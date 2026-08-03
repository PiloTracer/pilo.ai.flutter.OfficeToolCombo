import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/price_monitor/data/repositories/price_monitor_repository_impl.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';

PriceWatch _watch({
  String id = 'w1',
  String label = 'Coffee',
  String url = 'https://example.com/coffee',
  String threshold = '10',
  bool enabled = true,
}) {
  return PriceWatch(
    id: id,
    label: label,
    url: url,
    threshold: Decimal.parse(threshold),
    direction: PriceWatchDirection.above,
    enabled: enabled,
  );
}

void main() {
  late InMemoryPriceMonitorStore store;
  late PriceMonitorRepositoryImpl repository;

  setUp(() {
    store = InMemoryPriceMonitorStore();
    repository = PriceMonitorRepositoryImpl(store: store);
  });

  test(
    'saveWatch validates and returns stable field codes (R2/R8/R9)',
    () async {
      final badLabel = await repository.saveWatch(_watch(label: '  '));
      expect(badLabel, isA<Err<PriceWatch>>());
      expect(
        (badLabel as Err<PriceWatch>).failure.message,
        PriceMonitorFailureCodes.validationLabel,
      );

      final badUrl = await repository.saveWatch(_watch(url: 'ftp://x'));
      expect(
        (badUrl as Err<PriceWatch>).failure.message,
        PriceMonitorFailureCodes.validationUrl,
      );

      // Threshold is stored as Decimal; zero threshold is rejected (R2).
      final zero = _watch(threshold: '0');
      final badThreshold = await repository.saveWatch(zero);
      expect(
        (badThreshold as Err<PriceWatch>).failure.message,
        PriceMonitorFailureCodes.validationThreshold,
      );
    },
  );

  test('saveWatch trims and updates existing watches in place', () async {
    await repository.saveWatch(_watch(label: '  Coffee  '));
    await repository.saveWatch(_watch(id: 'w2', label: 'Tea'));
    await repository.saveWatch(_watch(label: 'Coffee v2'));

    final loaded = await repository.loadWatches();
    final watches = (loaded as Success<List<PriceWatch>>).data;
    expect(watches, hasLength(2));
    expect(watches.first.label, 'Coffee v2');
    expect(watches.last.label, 'Tea');
  });

  test('deleteWatch removes the watch and its samples', () async {
    await repository.saveWatch(_watch());
    await repository.writeSample(
      PriceSample(
        watchId: 'w1',
        price: Decimal.parse('9'),
        fetchedAt: DateTime.utc(2026),
        status: PriceSampleStatus.success,
      ),
    );

    final result = await repository.deleteWatch('w1');
    expect(result, isA<Success<void>>());
    expect(store.watches, isEmpty);
    expect(store.latestSamples, isEmpty);
    expect(store.lastSuccessfulSamples, isEmpty);
  });

  test('setWatchEnabled flips only the enabled flag', () async {
    await repository.saveWatch(_watch());
    await repository.setWatchEnabled('w1', false);
    expect(store.watches.single.enabled, isFalse);
    expect(store.watches.single.label, 'Coffee');
  });

  test('writeSample promotes successes to the cross baseline', () async {
    final failed = PriceSample(
      watchId: 'w1',
      price: null,
      fetchedAt: DateTime.utc(2026),
      status: PriceSampleStatus.failed,
    );
    await repository.writeSample(failed);
    expect(await repository.readLastSuccessfulSample('w1'), isNull);
    expect((await repository.readLatestSamples())['w1'], failed);

    final ok = PriceSample(
      watchId: 'w1',
      price: Decimal.parse('7'),
      fetchedAt: DateTime.utc(2026, 1, 2),
      status: PriceSampleStatus.success,
    );
    await repository.writeSample(ok);
    expect(
      (await repository.readLastSuccessfulSample('w1'))!.price,
      Decimal.parse('7'),
    );
  });
}
