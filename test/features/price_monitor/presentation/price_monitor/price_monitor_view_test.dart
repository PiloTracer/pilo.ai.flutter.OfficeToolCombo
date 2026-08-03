import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/price_monitor/data/repositories/price_monitor_repository_impl.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/os_notification_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/price_fetch_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_providers.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class FakePriceFetchService implements PriceFetchService {
  Decimal price = Decimal.parse('11');
  var fail = false;

  @override
  Future<PriceFetchOutcome> fetch(PriceWatch watch) async {
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

  @override
  Future<OsNotifyOutcome> showNotification({
    required String title,
    required String body,
  }) async {
    return outcome;
  }
}

PriceWatch _watch({
  String id = 'w1',
  String label = 'Coffee',
  String threshold = '10',
  bool enabled = true,
}) {
  return PriceWatch(
    id: id,
    label: label,
    url: 'https://example.com/$id',
    threshold: Decimal.parse(threshold),
    direction: PriceWatchDirection.above,
    enabled: enabled,
  );
}

void main() {
  late InMemoryPriceMonitorStore store;
  late FakePriceFetchService fetch;
  late FakeConnectivityService connectivity;
  late FakeOsNotificationService osNotify;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = InMemoryPriceMonitorStore();
    fetch = FakePriceFetchService();
    connectivity = FakeConnectivityService();
    osNotify = FakeOsNotificationService();
  });

  /// Pumps the view with in-memory fakes. The returned container must be
  /// disposed at the end of the test body — `addTearDown` runs after
  /// flutter_test's pending-timer check, so teardown disposal is too late
  /// for the coordinator's periodic timers.
  Future<ProviderContainer> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildL10nTestApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const PriceMonitorView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> createWatch(
    WidgetTester tester, {
    required String label,
    required String url,
    required String threshold,
  }) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Add watch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Label'), label);
    await tester.enterText(find.widgetWithText(TextField, 'URL'), url);
    await tester.enterText(
      find.widgetWithText(TextField, 'Threshold'),
      threshold,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('A1: creating two watches lists both with their labels', (
    tester,
  ) async {
    final container = await pumpView(tester);

    await createWatch(
      tester,
      label: 'Coffee beans',
      url: 'https://example.com/coffee',
      threshold: '10',
    );
    await createWatch(
      tester,
      label: 'Green tea',
      url: 'https://example.com/tea',
      threshold: '5.50',
    );

    expect(find.text('Coffee beans'), findsOneWidget);
    expect(find.text('Green tea'), findsOneWidget);
    // Never fetched — the not-fetched copy shows per row (SPEC §4.1).
    expect(find.text('Not fetched yet'), findsNWidgets(4));
    container.dispose();
  });

  testWidgets('empty state shows title, message and Add watch', (tester) async {
    final container = await pumpView(tester);

    expect(find.text('No price watches yet'), findsOneWidget);
    expect(
      find.text(
        'Add a watch to get notified when a price crosses your threshold.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Add watch'), findsOneWidget);
    container.dispose();
  });

  testWidgets('A3: delete asks for confirmation, then removes the watch', (
    tester,
  ) async {
    store.watches.add(_watch());
    final container = await pumpView(tester);
    expect(find.text('Coffee'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // Confirmation gate (SPEC §4.2) — watch still listed until confirmed.
    expect(find.text('Delete this watch?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsNothing);
    expect(find.text('No price watches yet'), findsOneWidget);
    expect(store.watches, isEmpty);
    container.dispose();
  });

  testWidgets('A4: threshold 0 or negative blocks save with the R2 message', (
    tester,
  ) async {
    final container = await pumpView(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add watch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Label'), 'Coffee');
    await tester.enterText(
      find.widgetWithText(TextField, 'URL'),
      'https://example.com/coffee',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Threshold'), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a threshold greater than zero'), findsOneWidget);
    // Dialog stays open; watch was not created.
    expect(find.text('Add watch'), findsWidgets);
    expect(store.watches, isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Threshold'), '-3');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a threshold greater than zero'), findsOneWidget);
    container.dispose();
  });

  testWidgets('A4 (es): threshold validation message is localized', (
    tester,
  ) async {
    final container = await pumpView(tester, locale: const Locale('es'));

    await tester.tap(find.widgetWithText(FilledButton, 'Agregar seguimiento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Etiqueta'), 'Café');
    await tester.enterText(
      find.widgetWithText(TextField, 'URL'),
      'https://example.com/cafe',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Umbral'), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese un umbral mayor que cero'), findsOneWidget);
    container.dispose();
  });

  testWidgets('invalid URL blocks save with the R8 message', (tester) async {
    final container = await pumpView(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add watch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Label'), 'Coffee');
    await tester.enterText(
      find.widgetWithText(TextField, 'URL'),
      'example.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Threshold'), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid web address starting with http:// or https://'),
      findsOneWidget,
    );
    expect(store.watches, isEmpty);
    container.dispose();
  });

  testWidgets('dirty cancel asks before discarding (§4.6)', (tester) async {
    final container = await pumpView(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add watch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Label'), 'Coffee');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(store.watches, isEmpty);
    container.dispose();
  });

  testWidgets('offline shows the global badge and per-row chip', (
    tester,
  ) async {
    connectivity.online = false;
    store.watches.add(_watch());
    final container = await pumpView(tester);

    expect(find.text('Offline — price checks paused'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget); // per-row chip
    container.dispose();
  });

  testWidgets('A8 (es): offline badge is localized', (tester) async {
    connectivity.online = false;
    store.watches.add(_watch());
    final container = await pumpView(tester, locale: const Locale('es'));

    expect(
      find.text('Sin conexión — consultas de precio en pausa'),
      findsOneWidget,
    );
    container.dispose();
  });

  testWidgets('A9: successful poll shows Decimal price and Updated time', (
    tester,
  ) async {
    fetch.price = Decimal.parse('12.30');
    store.watches.add(_watch());
    final container = await pumpView(tester);

    // Decimal normalizes trailing zeros — 12.30 renders as 12.3.
    expect(find.text('12.3'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    expect(find.text('Alert Above 10'), findsOneWidget);
    container.dispose();
  });

  testWidgets('failed fetch shows the row failure and Retry now', (
    tester,
  ) async {
    fetch.fail = true;
    store.watches.add(_watch());
    final container = await pumpView(tester);

    expect(
      find.text('Fetch failed — Could not read price from page'),
      findsOneWidget,
    );
    expect(find.text('Retry now'), findsOneWidget);
    container.dispose();
  });

  testWidgets('A7: OS failure shows banner, Dismiss clears it', (tester) async {
    // Baseline below threshold; next poll crosses upward.
    store.watches.add(_watch());
    store.lastSuccessfulSamples['w1'] = PriceSample(
      watchId: 'w1',
      price: Decimal.parse('9'),
      fetchedAt: DateTime.utc(2026),
      status: PriceSampleStatus.success,
    );
    fetch.price = Decimal.parse('11');
    osNotify.outcome = OsNotifyOutcome.failed;

    final container = await pumpView(tester);

    expect(find.text('Price alert: Coffee'), findsOneWidget);
    expect(find.text('Price is 11 (threshold 10)'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Price alert: Coffee'), findsNothing);
    container.dispose();
  });
}
