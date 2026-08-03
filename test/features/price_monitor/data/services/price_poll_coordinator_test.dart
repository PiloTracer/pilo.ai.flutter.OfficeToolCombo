import 'dart:async';

import 'package:decimal/decimal.dart';
// fake_async ships with flutter_test; pubspec.yaml is a protected file, so
// the transitive import is acknowledged here instead of via pubspec.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/price_monitor/data/repositories/price_monitor_repository_impl.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/price_fetch_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/features/price_monitor/domain/polling/price_poll_coordinator.dart';

class FakePriceFetchService implements PriceFetchService {
  final List<String> fetchedUrls = [];
  final List<Decimal> priceQueue = [];
  var failNext = false;
  Decimal defaultPrice = Decimal.parse('5');

  @override
  Future<PriceFetchOutcome> fetch(PriceWatch watch) async {
    fetchedUrls.add(watch.url);
    if (failNext) {
      failNext = false;
      return const PriceFetchFailed(
        code: PriceMonitorFailureCodes.fetch,
        message: 'boom',
      );
    }
    final price = priceQueue.isEmpty ? defaultPrice : priceQueue.removeAt(0);
    return PriceFetchSuccess(price);
  }
}

class FakeConnectivityService implements ConnectivityService {
  var online = true;

  @override
  Future<bool> isOnline() async => online;
}

PriceWatch _watch({
  String id = 'w1',
  String url = 'https://example.com/a',
  String threshold = '10',
  PriceWatchDirection direction = PriceWatchDirection.above,
  bool enabled = true,
}) {
  return PriceWatch(
    id: id,
    label: 'Watch $id',
    url: url,
    threshold: Decimal.parse(threshold),
    direction: direction,
    enabled: enabled,
  );
}

void main() {
  late InMemoryPriceMonitorStore store;
  late PriceMonitorRepositoryImpl repository;
  late FakePriceFetchService fetch;
  late FakeConnectivityService connectivity;
  late PricePollCoordinator coordinator;

  setUp(() {
    store = InMemoryPriceMonitorStore();
    repository = PriceMonitorRepositoryImpl(store: store);
    fetch = FakePriceFetchService();
    connectivity = FakeConnectivityService();
    coordinator = PricePollCoordinator(
      repository: repository,
      fetchService: fetch,
      connectivityService: connectivity,
    );
  });

  tearDown(() {
    coordinator.stop();
  });

  test('A10: second poll fires no earlier than 10 minutes after the first', () {
    fakeAsync((async) {
      unawaited(store.writeWatches([_watch()]));
      final timed = PricePollCoordinator(
        repository: repository,
        fetchService: fetch,
        connectivityService: connectivity,
      );
      unawaited(timed.start());
      async.flushMicrotasks();
      // First poll runs immediately on start.
      expect(fetch.fetchedUrls, hasLength(1));

      async.elapse(const Duration(minutes: 9, seconds: 59));
      async.flushMicrotasks();
      expect(fetch.fetchedUrls, hasLength(1));

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(fetch.fetchedUrls, hasLength(2));

      timed.stop();
    });
  });

  test('A2: disabled watches are never fetched in a poll cycle (R1)', () async {
    await store.writeWatches([
      _watch(id: 'on', url: 'https://example.com/on'),
      _watch(id: 'off', url: 'https://example.com/off', enabled: false),
    ]);

    final result = await coordinator.pollCycle();

    expect(fetch.fetchedUrls, ['https://example.com/on']);
    expect(result.offline, isFalse);
    expect(result.samples, hasLength(1));
    expect(result.samples.single.watchId, 'on');
  });

  test(
    'R5: first successful fetch establishes baseline without alerting',
    () async {
      await store.writeWatches([_watch()]);
      fetch.defaultPrice = Decimal.parse('15'); // already above threshold

      final result = await coordinator.pollCycle();

      expect(result.alerts, isEmpty);
      expect(
        (await repository.readLastSuccessfulSample('w1'))!.price,
        Decimal.parse('15'),
      );
    },
  );

  test('A5/R3: cross alerts once, re-arms only after cross-back', () async {
    await store.writeWatches([_watch()]);
    fetch.priceQueue.addAll([
      Decimal.parse('9'), // baseline
      Decimal.parse('11'), // cross -> alert
      Decimal.parse('12'), // same side -> silent
      Decimal.parse('8'), // cross back -> silent, re-armed
      Decimal.parse('10'), // cross again (>=) -> alert
    ]);

    final alerts = <PriceCrossAlert>[];
    for (var i = 0; i < 5; i++) {
      final result = await coordinator.pollCycle();
      alerts.addAll(result.alerts);
    }

    expect(alerts, hasLength(2));
    expect(alerts.first.price, Decimal.parse('11'));
    expect(alerts.last.price, Decimal.parse('10'));
  });

  test('failed fetch does not move the cross baseline', () async {
    await store.writeWatches([_watch()]);
    await repository.writeSample(
      PriceSample(
        watchId: 'w1',
        price: Decimal.parse('9'),
        fetchedAt: DateTime.utc(2026),
        status: PriceSampleStatus.success,
      ),
    );

    fetch.failNext = true;
    final failed = await coordinator.pollCycle();
    expect(failed.samples.single.status, PriceSampleStatus.failed);
    expect(
      (await repository.readLastSuccessfulSample('w1'))!.price,
      Decimal.parse('9'),
    );

    // Next success still compares against the pre-failure baseline.
    fetch.defaultPrice = Decimal.parse('11');
    final recovered = await coordinator.pollCycle();
    expect(recovered.alerts, hasLength(1));
  });

  test(
    'R7: offline skips the whole cycle — no fetches, samples unchanged',
    () async {
      await store.writeWatches([_watch()]);
      connectivity.online = false;

      PricePollCycleResult? callbackResult;
      coordinator.onCycle = (result) => callbackResult = result;

      final result = await coordinator.pollCycle();

      expect(result.offline, isTrue);
      expect(callbackResult?.offline, isTrue);
      expect(fetch.fetchedUrls, isEmpty);
      expect(await repository.readLatestSamples(), isEmpty);
    },
  );

  test('connectivity flips are reported to listeners', () async {
    final flips = <bool>[];
    coordinator.onConnectivityChanged = flips.add;

    connectivity.online = false;
    await coordinator.probeConnectivity();
    await coordinator.probeConnectivity(); // no flip, no duplicate
    connectivity.online = true;
    await coordinator.probeConnectivity();

    expect(flips, [false, true]);
  });

  test('A11: edited URL is used on the next poll', () async {
    await store.writeWatches([_watch(url: 'https://example.com/old')]);
    await coordinator.pollCycle();

    await repository.saveWatch(_watch(url: 'https://example.com/new'));
    await coordinator.pollCycle();

    expect(fetch.fetchedUrls, [
      'https://example.com/old',
      'https://example.com/new',
    ]);
  });
}
