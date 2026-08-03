import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/price_monitor/data/repositories/price_monitor_repository_impl.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/os_notification_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/price_fetch_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_providers.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_ui_state.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_view_model.dart';

class FakePriceFetchService implements PriceFetchService {
  final List<String> fetchedUrls = [];
  Decimal price = Decimal.parse('11');
  var fail = false;

  @override
  Future<PriceFetchOutcome> fetch(PriceWatch watch) async {
    fetchedUrls.add(watch.url);
    if (fail) {
      return const PriceFetchFailed(
        code: PriceMonitorFailureCodes.fetch,
        message: 'boom',
      );
    }
    return PriceFetchSuccess(price);
  }
}

class FakeConnectivityService implements ConnectivityService {
  var online = true;

  @override
  Future<bool> isOnline() async => online;
}

class FakeOsNotificationService implements OsNotificationService {
  var outcome = OsNotifyOutcome.failed;
  final List<({String title, String body})> shown = [];

  @override
  Future<OsNotifyOutcome> showNotification({
    required String title,
    required String body,
  }) async {
    shown.add((title: title, body: body));
    return outcome;
  }
}

class ThrowingStore extends InMemoryPriceMonitorStore {
  @override
  Future<List<PriceWatch>> readWatches() {
    throw StateError('store corrupted');
  }
}

PriceWatch _watch({String id = 'w1', bool enabled = true}) {
  return PriceWatch(
    id: id,
    label: 'Coffee',
    url: 'https://example.com/coffee',
    threshold: Decimal.parse('10'),
    direction: PriceWatchDirection.above,
    enabled: enabled,
  );
}

void main() {
  late InMemoryPriceMonitorStore store;
  late FakePriceFetchService fetch;
  late FakeConnectivityService connectivity;
  late FakeOsNotificationService osNotify;
  late ProviderContainer container;

  PriceMonitorViewModel viewModel() =>
      container.read(priceMonitorViewModelProvider.notifier);

  PriceMonitorUiState uiState() =>
      container.read(priceMonitorViewModelProvider);

  void configureAlerts() {
    viewModel().configureAlertPresentation(
      titleBuilder: (alert) => 'Price alert: ${alert.watch.label}',
      bodyBuilder: (alert) =>
          'Price is ${alert.price} (threshold ${alert.watch.threshold})',
    );
  }

  void pumpContainer({InMemoryPriceMonitorStore? customStore}) {
    store = customStore ?? InMemoryPriceMonitorStore();
    container = ProviderContainer(
      overrides: [
        priceMonitorStoreProvider.overrideWithValue(store),
        priceMonitorRepositoryProvider.overrideWithValue(
          PriceMonitorRepositoryImpl(store: store),
        ),
        priceFetchServiceProvider.overrideWithValue(fetch),
        connectivityServiceProvider.overrideWithValue(connectivity),
        osNotificationServiceProvider.overrideWithValue(osNotify),
      ],
    );
    addTearDown(container.dispose);
  }

  setUp(() {
    fetch = FakePriceFetchService();
    connectivity = FakeConnectivityService();
    osNotify = FakeOsNotificationService();
  });

  test('A5+A7: cross attempts OS notification; failure falls back to a '
      'dismissible banner with the same title/body', () async {
    pumpContainer();
    final watch = _watch();
    await store.writeWatches([watch]);
    await store.writeLastSuccessfulSample(
      PriceSample(
        watchId: watch.id,
        price: Decimal.parse('9'),
        fetchedAt: DateTime.utc(2026),
        status: PriceSampleStatus.success,
      ),
    );

    // Keep the auto-poll at load on the safe side of the threshold.
    fetch.price = Decimal.parse('9');
    await viewModel().loadInitialState();
    configureAlerts();
    fetch.price = Decimal.parse('11');

    await viewModel().retryNow(watch);

    // Notification attempted with the SPEC §4.3 content.
    expect(osNotify.shown, hasLength(1));
    expect(osNotify.shown.single.title, 'Price alert: Coffee');
    expect(osNotify.shown.single.body, 'Price is 11 (threshold 10)');

    // OS failed -> in-app banner fallback (R10), dismissible.
    final banner = uiState().banner;
    expect(banner, isNotNull);
    expect(banner!.title, osNotify.shown.single.title);
    expect(banner.body, osNotify.shown.single.body);

    viewModel().dismissBanner();
    expect(uiState().banner, isNull);
  });

  test('delivered OS notification shows no banner', () async {
    pumpContainer();
    final watch = _watch();
    await store.writeWatches([watch]);
    await store.writeLastSuccessfulSample(
      PriceSample(
        watchId: watch.id,
        price: Decimal.parse('9'),
        fetchedAt: DateTime.utc(2026),
        status: PriceSampleStatus.success,
      ),
    );
    osNotify.outcome = OsNotifyOutcome.delivered;

    // Keep the auto-poll at load on the safe side of the threshold.
    fetch.price = Decimal.parse('9');
    await viewModel().loadInitialState();
    configureAlerts();
    fetch.price = Decimal.parse('11');
    await viewModel().retryNow(watch);

    expect(osNotify.shown, hasLength(1));
    expect(uiState().banner, isNull);
  });

  test(
    'A9: successful fetch stores a Decimal price with fetch timestamp',
    () async {
      pumpContainer();
      final watch = _watch();
      await store.writeWatches([watch]);

      await viewModel().loadInitialState();
      fetch.price = Decimal.parse('12.30');
      final before = DateTime.now().toUtc();
      await viewModel().retryNow(watch);

      final sample = uiState().samples[watch.id];
      expect(sample, isNotNull);
      expect(sample!.price, Decimal.parse('12.30'));
      expect(sample.status, PriceSampleStatus.success);
      expect(
        sample.fetchedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    },
  );

  test(
    'offline at load: badge state on, polls skipped, retry is a no-op',
    () async {
      connectivity.online = false;
      pumpContainer();
      final watch = _watch();
      await store.writeWatches([watch]);

      await viewModel().loadInitialState();

      expect(uiState().isOffline, isTrue);
      expect(fetch.fetchedUrls, isEmpty);

      await viewModel().retryNow(watch);
      expect(fetch.fetchedUrls, isEmpty);
    },
  );

  test(
    'store load failure surfaces the error state with the load code',
    () async {
      pumpContainer(customStore: ThrowingStore());

      await viewModel().loadInitialState();

      expect(uiState().status, PriceMonitorStatus.error);
      expect(uiState().errorCode, PriceMonitorFailureCodes.load);
    },
  );

  test('saveWatch and deleteWatch keep the list state in sync', () async {
    pumpContainer();
    await viewModel().loadInitialState();

    await viewModel().saveWatch(_watch());
    await viewModel().saveWatch(_watch(id: 'w2'));
    expect(uiState().watches.map((w) => w.id), ['w1', 'w2']);

    await viewModel().deleteWatch('w1');
    expect(uiState().watches.map((w) => w.id), ['w2']);
  });

  test('R5: re-enabling a watch resets its cross baseline', () async {
    pumpContainer();
    final watch = _watch();
    await store.writeWatches([watch.copyWith(enabled: false)]);
    await store.writeLastSuccessfulSample(
      PriceSample(
        watchId: watch.id,
        price: Decimal.parse('9'),
        fetchedAt: DateTime.utc(2026),
        status: PriceSampleStatus.success,
      ),
    );

    await viewModel().loadInitialState();
    await viewModel().setEnabled(watch.copyWith(enabled: false), true);

    expect(uiState().watches.single.enabled, isTrue);
    expect(await store.readLastSuccessfulSample(watch.id), isNull);
  });
}
