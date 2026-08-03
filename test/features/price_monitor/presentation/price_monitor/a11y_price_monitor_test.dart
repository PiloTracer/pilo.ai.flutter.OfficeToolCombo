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
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_providers.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class FakeConnectivityService implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
}

class FakePriceFetchService implements PriceFetchService {
  @override
  Future<PriceFetchOutcome> fetch(PriceWatch watch) async =>
      PriceFetchSuccess(Decimal.parse('11'));
}

class FakeOsNotificationService implements OsNotificationService {
  @override
  Future<OsNotifyOutcome> showNotification({
    required String title,
    required String body,
  }) async => OsNotifyOutcome.failed;
}

void main() {
  late InMemoryPriceMonitorStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = InMemoryPriceMonitorStore();
  });

  /// Pumps the view with in-memory fakes. The returned container must be
  /// disposed at the end of the test body — teardown disposal runs after
  /// flutter_test's pending-timer check, too late for the coordinator's
  /// periodic timers.
  Future<ProviderContainer> pumpView(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        priceMonitorStoreProvider.overrideWithValue(store),
        priceMonitorRepositoryProvider.overrideWithValue(
          PriceMonitorRepositoryImpl(store: store),
        ),
        priceFetchServiceProvider.overrideWithValue(FakePriceFetchService()),
        connectivityServiceProvider.overrideWithValue(
          FakeConnectivityService(),
        ),
        osNotificationServiceProvider.overrideWithValue(
          FakeOsNotificationService(),
        ),
      ],
    );

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: UncontrolledProviderScope(
          container: container,
          child: buildL10nTestApp(
            theme: AppTheme.dark(),
            home: const PriceMonitorView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('price monitor and watch editor render at 200% text scale', (
    tester,
  ) async {
    final container = await pumpView(tester, textScale: 2);

    await tester.tap(find.widgetWithText(FilledButton, 'Add watch'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Label'), 'Coffee');
    await tester.enterText(
      find.widgetWithText(TextField, 'URL'),
      'https://example.com/coffee',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Threshold'), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Coffee'), findsOneWidget);
    container.dispose();
  });

  testWidgets('watch enable toggle announces the watch label', (tester) async {
    final container = await pumpView(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add watch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Label'), 'Coffee');
    await tester.enterText(
      find.widgetWithText(TextField, 'URL'),
      'https://example.com/coffee',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Threshold'), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Enable watch Coffee',
      ),
      findsOneWidget,
    );
    container.dispose();
  });
}
