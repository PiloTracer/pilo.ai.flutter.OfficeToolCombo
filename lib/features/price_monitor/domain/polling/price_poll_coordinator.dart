import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/features/price_monitor/domain/connectivity/connectivity.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/fetch/price_fetcher.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';
import 'package:office_tool_combo/features/price_monitor/domain/services/threshold_cross_detector.dart';

/// A threshold cross detected during a poll (R3/R4). The presentation
/// layer formats the localized title/body and picks the delivery channel.
class PriceCrossAlert {
  const PriceCrossAlert({required this.watch, required this.price});

  final PriceWatch watch;
  final Decimal price;
}

/// What changed during one poll cycle.
class PricePollCycleResult {
  const PricePollCycleResult({
    required this.offline,
    this.samples = const [],
    this.alerts = const [],
  });

  /// R7 — polls are skipped while offline; samples stay untouched.
  final bool offline;
  final List<PriceSample> samples;
  final List<PriceCrossAlert> alerts;
}

/// Outcome of polling a single watch.
class PriceWatchPollOutcome {
  const PriceWatchPollOutcome({required this.sample, this.alert});

  final PriceSample sample;
  final PriceCrossAlert? alert;
}

/// Timer-based background poll scheduler (NFR9 — default 10 minutes).
///
/// Polls only enabled watches (R1), sequentially, skipping whole cycles
/// while offline (R7). The clock and timer behaviour follow Dart's `Timer`,
/// so tests drive it with `package:fake_async`; the first poll runs
/// immediately on [start], later polls every `pricePollMinutes` (R6).
class PricePollCoordinator {
  PricePollCoordinator({
    required this.repository,
    required this.fetchService,
    required this.connectivityService,
    DateTime Function()? clock,
    this.connectivityProbeInterval = const Duration(seconds: 30),
    AppLogger? logger,
  }) : _clock = clock ?? DateTime.now,
       _logger = logger ?? AppLogger();

  final PriceMonitorRepository repository;
  final PriceFetchService fetchService;
  final ConnectivityService connectivityService;
  final DateTime Function() _clock;
  final Duration connectivityProbeInterval;
  final AppLogger _logger;

  /// Called after every poll cycle (including skipped offline cycles).
  void Function(PricePollCycleResult result)? onCycle;

  /// Called when the probed connectivity state flips.
  void Function(bool online)? onConnectivityChanged;

  Timer? _pollTimer;
  Timer? _connectivityTimer;
  bool _running = false;
  bool _isPolling = false;
  bool? lastKnownOnline;

  /// Starts the scheduler: an immediate first poll, then one poll per
  /// configured interval. A separate, lighter probe keeps the offline
  /// badge fresh within one connectivity check cycle (SPEC §6).
  Future<void> start() async {
    if (_running) {
      return;
    }
    _running = true;
    final minutes = await repository.readPollIntervalMinutes();
    if (!_running) {
      return;
    }
    _pollTimer = Timer.periodic(Duration(minutes: minutes), (_) {
      unawaited(pollCycle());
    });
    _connectivityTimer = Timer.periodic(connectivityProbeInterval, (_) {
      unawaited(probeConnectivity());
    });
    unawaited(pollCycle());
  }

  void stop() {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  Future<bool> probeConnectivity() async {
    final online = await connectivityService.isOnline();
    if (online != lastKnownOnline) {
      lastKnownOnline = online;
      onConnectivityChanged?.call(online);
    }
    return online;
  }

  /// Runs one full cycle over all enabled watches. Safe against
  /// re-entrancy: a cycle already in flight makes the call a no-op.
  Future<PricePollCycleResult> pollCycle() async {
    if (_isPolling) {
      return PricePollCycleResult(offline: !(lastKnownOnline ?? true));
    }
    _isPolling = true;
    try {
      final online = await probeConnectivity();
      if (!online) {
        const result = PricePollCycleResult(offline: true);
        onCycle?.call(result);
        return result;
      }

      final loaded = await repository.loadWatches();
      final watches = loaded.when(
        success: (watches) => watches,
        failure: (failure) {
          _logger.info('price_monitor.load_failed code=${failure.message}');
          return const <PriceWatch>[];
        },
      );

      final samples = <PriceSample>[];
      final alerts = <PriceCrossAlert>[];
      // Sequential on purpose: bounded, predictable network use (SPEC §13).
      for (final watch in watches) {
        if (!watch.enabled) {
          continue; // R1 — disabled watches are never polled.
        }
        final outcome = await pollWatch(watch);
        samples.add(outcome.sample);
        final alert = outcome.alert;
        if (alert != null) {
          alerts.add(alert);
        }
      }

      final result = PricePollCycleResult(
        offline: false,
        samples: samples,
        alerts: alerts,
      );
      onCycle?.call(result);
      return result;
    } finally {
      _isPolling = false;
    }
  }

  /// Fetches a single watch, records the sample, and runs cross detection
  /// against the previous successful sample (R3/R4/R5).
  Future<PriceWatchPollOutcome> pollWatch(PriceWatch watch) async {
    final previous = await repository.readLastSuccessfulSample(watch.id);
    final stopwatch = Stopwatch()..start();
    final outcome = await fetchService.fetch(watch);
    _logger.info(
      'price_monitor.fetch_completed watchId=${watch.id} '
      'latencyMs=${stopwatch.elapsedMilliseconds} '
      'success=${outcome is PriceFetchSuccess}',
    );

    final now = _clock().toUtc();
    switch (outcome) {
      case PriceFetchSuccess(price: final price):
        final sample = PriceSample(
          watchId: watch.id,
          price: price,
          fetchedAt: now,
          status: PriceSampleStatus.success,
        );
        await repository.writeSample(sample);
        final crossed = ThresholdCrossDetector.didCross(
          direction: watch.direction,
          threshold: watch.threshold,
          previous: previous?.price,
          current: price,
        );
        if (crossed) {
          _logger.info(
            'price_monitor.threshold_crossed watchId=${watch.id} '
            'direction=${watch.direction.name} price=$price '
            'threshold=${watch.threshold}',
          );
          return PriceWatchPollOutcome(
            sample: sample,
            alert: PriceCrossAlert(watch: watch, price: price),
          );
        }
        return PriceWatchPollOutcome(sample: sample);
      case PriceFetchFailed():
        final sample = PriceSample(
          watchId: watch.id,
          price: null,
          fetchedAt: now,
          status: PriceSampleStatus.failed,
        );
        await repository.writeSample(sample);
        return PriceWatchPollOutcome(sample: sample);
    }
  }
}
