import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/shared_preferences_price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

PriceWatch _watch(String id, {bool enabled = true}) {
  return PriceWatch(
    id: id,
    label: 'Watch $id',
    url: 'https://example.com/p/$id?ref=abc',
    threshold: Decimal.parse('19.99'),
    direction: PriceWatchDirection.below,
    enabled: enabled,
  );
}

PriceSample _sample(
  String watchId,
  String? price, {
  PriceSampleStatus? status,
}) {
  return PriceSample(
    watchId: watchId,
    price: price == null ? null : Decimal.parse(price),
    fetchedAt: DateTime.utc(2026, 8, 2, 12),
    status:
        status ??
        (price == null ? PriceSampleStatus.failed : PriceSampleStatus.success),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesPriceMonitorStore', () {
    test('watches round-trip through a fresh store instance', () async {
      final first = SharedPreferencesPriceMonitorStore();
      await first.writeWatches([_watch('a'), _watch('b', enabled: false)]);

      final second = SharedPreferencesPriceMonitorStore();
      final restored = await second.readWatches();
      expect(restored, hasLength(2));
      expect(restored.first.id, 'a');
      expect(restored.first.threshold, Decimal.parse('19.99'));
      expect(restored.first.direction, PriceWatchDirection.below);
      expect(restored.last.enabled, isFalse);
      // Full URL with query is persisted for polling; logging never sees it.
      expect(restored.first.url, 'https://example.com/p/a?ref=abc');
    });

    test('latest samples round-trip including failed samples', () async {
      final first = SharedPreferencesPriceMonitorStore();
      await first.writeLatestSample(_sample('a', '12.50'));
      await first.writeLatestSample(_sample('b', null));

      final second = SharedPreferencesPriceMonitorStore();
      final restored = await second.readLatestSamples();
      expect(restored['a']!.price, Decimal.parse('12.50'));
      expect(restored['a']!.status, PriceSampleStatus.success);
      expect(restored['b']!.price, isNull);
      expect(restored['b']!.status, PriceSampleStatus.failed);
      expect(restored['a']!.fetchedAt, DateTime.utc(2026, 8, 2, 12));
    });

    test('last successful sample write/read/clear', () async {
      final store = SharedPreferencesPriceMonitorStore();
      expect(await store.readLastSuccessfulSample('a'), isNull);

      await store.writeLastSuccessfulSample(_sample('a', '9.99'));
      final fresh = SharedPreferencesPriceMonitorStore();
      expect(
        (await fresh.readLastSuccessfulSample('a'))!.price,
        Decimal.parse('9.99'),
      );

      await fresh.clearLastSuccessfulSample('a');
      expect(
        await SharedPreferencesPriceMonitorStore().readLastSuccessfulSample(
          'a',
        ),
        isNull,
      );
    });

    test('removeSamples clears latest and last-successful records', () async {
      final store = SharedPreferencesPriceMonitorStore();
      await store.writeLatestSample(_sample('a', '1'));
      await store.writeLastSuccessfulSample(_sample('a', '1'));

      await store.removeSamples('a');

      expect(await store.readLatestSamples(), isEmpty);
      expect(await store.readLastSuccessfulSample('a'), isNull);
    });

    test('poll minutes default to 10 and persist (R6)', () async {
      final store = SharedPreferencesPriceMonitorStore();
      expect(
        await store.readPollMinutes(),
        PriceMonitorRepository.defaultPollMinutes,
      );

      await store.writePollMinutes(5);
      expect(await SharedPreferencesPriceMonitorStore().readPollMinutes(), 5);
    });

    test('empty store reads as empty, not corrupt', () async {
      final store = SharedPreferencesPriceMonitorStore();
      expect(await store.readWatches(), isEmpty);
      expect(await store.readLatestSamples(), isEmpty);
    });
  });

  group('InMemoryPriceMonitorStore', () {
    test('mirrors the same contract for tests', () async {
      final store = InMemoryPriceMonitorStore();
      await store.writeWatches([_watch('a')]);
      await store.writeLatestSample(_sample('a', '3'));
      await store.writeLastSuccessfulSample(_sample('a', '3'));

      expect((await store.readWatches()).single.id, 'a');
      expect((await store.readLatestSamples())['a']!.price, Decimal.parse('3'));
      expect(
        (await store.readLastSuccessfulSample('a'))!.price,
        Decimal.parse('3'),
      );

      await store.removeSamples('a');
      expect(await store.readLatestSamples(), isEmpty);
      expect(await store.readLastSuccessfulSample('a'), isNull);
    });
  });
}
