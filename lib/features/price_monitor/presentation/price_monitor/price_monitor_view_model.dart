import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/price_monitor/domain/alerting/os_notifications.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/polling/price_poll_coordinator.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_providers.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_ui_state.dart';

class PriceMonitorViewModel extends Notifier<PriceMonitorUiState> {
  PriceMonitorRepository get _repository =>
      ref.read(priceMonitorRepositoryProvider);

  late final PricePollCoordinator _coordinator;
  final AppLogger _logger = AppLogger();

  /// Localized alert formatting, provided by the view (which owns l10n).
  String Function(PriceCrossAlert alert)? _alertTitleBuilder;
  String Function(PriceCrossAlert alert)? _alertBodyBuilder;
  var _includeSystemSettingsHint = false;

  @override
  PriceMonitorUiState build() {
    _coordinator = PricePollCoordinator(
      repository: _repository,
      fetchService: ref.read(priceFetchServiceProvider),
      connectivityService: ref.read(connectivityServiceProvider),
    );
    _coordinator.onCycle = _handleCycle;
    _coordinator.onConnectivityChanged = _handleConnectivity;
    ref.onDispose(_coordinator.stop);
    return const PriceMonitorUiState();
  }

  /// The view calls this once per dependency change so notifications and
  /// banner fallbacks are formatted in the active locale (SPEC §4.3).
  void configureAlertPresentation({
    required String Function(PriceCrossAlert alert) titleBuilder,
    required String Function(PriceCrossAlert alert) bodyBuilder,
    bool includeSystemSettingsHint = false,
  }) {
    _alertTitleBuilder = titleBuilder;
    _alertBodyBuilder = bodyBuilder;
    _includeSystemSettingsHint = includeSystemSettingsHint;
  }

  Future<void> loadInitialState() async {
    final loaded = await _repository.loadWatches();
    if (!ref.mounted) return;
    await loaded.when(
      success: (watches) async {
        final samples = await _repository.readLatestSamples();
        if (!ref.mounted) return;
        final online = await _coordinator.probeConnectivity();
        if (!ref.mounted) return;
        state = state.copyWith(
          status: PriceMonitorStatus.ready,
          watches: watches,
          samples: samples,
          isOffline: !online,
          clearError: true,
        );
        unawaited(_coordinator.start());
      },
      failure: (failure) async {
        state = state.copyWith(
          status: PriceMonitorStatus.error,
          errorCode: failure.message,
        );
      },
    );
  }

  /// SPEC §6 — "Try again" reloads from the local store.
  Future<void> tryAgain() async {
    state = state.copyWith(
      status: PriceMonitorStatus.loading,
      clearError: true,
    );
    await loadInitialState();
  }

  /// Persists a new or edited watch; the caller (editor) shows the
  /// validation or save error when this returns an [Err].
  Future<Result<PriceWatch>> saveWatch(PriceWatch watch) async {
    final result = await _repository.saveWatch(watch);
    if (!ref.mounted) return result;
    result.when(
      success: (saved) {
        final watches = List<PriceWatch>.from(state.watches);
        final index = watches.indexWhere((item) => item.id == saved.id);
        if (index >= 0) {
          watches[index] = saved;
        } else {
          watches.add(saved);
        }
        state = state.copyWith(watches: watches);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteWatch(String watchId) async {
    final result = await _repository.deleteWatch(watchId);
    if (!ref.mounted) return result;
    result.when(
      success: (_) {
        final samples = Map<String, PriceSample>.from(state.samples)
          ..remove(watchId);
        state = state.copyWith(
          watches: state.watches.where((watch) => watch.id != watchId).toList(),
          samples: samples,
        );
      },
      failure: (_) {},
    );
    return result;
  }

  Future<void> setEnabled(PriceWatch watch, bool enabled) async {
    final result = await _repository.setWatchEnabled(watch.id, enabled);
    if (!ref.mounted) return;
    if (result is Err<void>) {
      return;
    }
    if (enabled) {
      // R5 — re-enabling establishes a fresh baseline on the next
      // successful fetch instead of alerting from a stale sample.
      await _repository.resetCrossBaseline(watch.id);
      if (!ref.mounted) return;
    }
    final watches = state.watches
        .map(
          (item) =>
              item.id == watch.id ? item.copyWith(enabled: enabled) : item,
        )
        .toList();
    state = state.copyWith(watches: watches);
  }

  /// SPEC §6 — "Retry now" polls one watch immediately (skipped offline).
  Future<void> retryNow(PriceWatch watch) async {
    if (state.isOffline) {
      return;
    }
    final outcome = await _coordinator.pollWatch(watch);
    if (!ref.mounted) return;
    _recordSample(outcome.sample);
    final alert = outcome.alert;
    if (alert != null) {
      await _deliverAlert(alert);
    }
  }

  void dismissBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void _handleConnectivity(bool online) {
    if (!ref.mounted) return;
    state = state.copyWith(isOffline: !online);
  }

  void _handleCycle(PricePollCycleResult result) {
    if (!ref.mounted) return;
    if (result.offline) {
      state = state.copyWith(isOffline: true);
      return;
    }
    state = state.copyWith(isOffline: false);
    for (final sample in result.samples) {
      _recordSample(sample);
    }
    for (final alert in result.alerts) {
      unawaited(_deliverAlert(alert));
    }
  }

  void _recordSample(PriceSample sample) {
    final samples = Map<String, PriceSample>.from(state.samples);
    samples[sample.watchId] = sample;
    state = state.copyWith(samples: samples);
  }

  /// SPEC §4.3 / R10 — OS notification first; any failure falls back to the
  /// in-app banner with the same title/body, immediately (≤ 2 s).
  Future<void> _deliverAlert(PriceCrossAlert alert) async {
    final titleBuilder = _alertTitleBuilder;
    final bodyBuilder = _alertBodyBuilder;
    if (titleBuilder == null || bodyBuilder == null) {
      _logger.info(
        'price_monitor.notify_failed watchId=${alert.watch.id} '
        'reason=no_presentation',
      );
      return;
    }
    final title = titleBuilder(alert);
    final body = bodyBuilder(alert);
    final outcome = await ref
        .read(osNotificationServiceProvider)
        .showNotification(title: title, body: body);
    if (!ref.mounted) return;
    if (outcome == OsNotifyOutcome.delivered) {
      _logger.info(
        'price_monitor.notify_delivered watchId=${alert.watch.id} channel=os',
      );
      return;
    }
    _logger.info(
      'price_monitor.notify_delivered watchId=${alert.watch.id} '
      'channel=banner',
    );
    state = state.copyWith(
      banner: PriceBannerAlert(
        title: title,
        body: body,
        showSystemSettingsHint: _includeSystemSettingsHint,
      ),
    );
  }
}

final priceMonitorViewModelProvider =
    NotifierProvider<PriceMonitorViewModel, PriceMonitorUiState>(
      PriceMonitorViewModel.new,
    );
