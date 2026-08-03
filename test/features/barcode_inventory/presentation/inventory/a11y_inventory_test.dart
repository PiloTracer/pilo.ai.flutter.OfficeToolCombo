import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpInventoryView(
    WidgetTester tester,
    AppDatabase db, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late ProviderContainer container;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: buildL10nTestApp(
            theme: AppTheme.dark(),
            home: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return const InventoryView();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));
    return container;
  }

  /// Expires the 2s toast-clear timer and the 4s SnackBar duration so no
  /// timers are left pending at the end of a test.
  Future<void> flushToasts(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('inventory renders without overflow at 200% text scale', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db, textScale: 2);
    await container
        .read(inventoryViewModelProvider.notifier)
        .confirmCreateItem(
          barcode: 'A-1',
          name: 'Hex bolt',
          startingQuantity: 3,
        );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hex bolt'), findsOneWidget);
    await flushToasts(tester);
  });

  testWidgets('app-bar overflow menu has a localized tooltip', (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    await pumpInventoryView(tester, db);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuButton<String> &&
            widget.tooltip == 'More actions',
      ),
      findsOneWidget,
    );
  });

  testWidgets('stock row action menu has a per-item localized tooltip', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await container
        .read(inventoryViewModelProvider.notifier)
        .confirmCreateItem(
          barcode: 'A-1',
          name: 'Hex bolt',
          startingQuantity: 3,
        );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuButton<String> &&
            widget.tooltip == 'Actions for Hex bolt',
      ),
      findsOneWidget,
    );
    await flushToasts(tester);
  });
}
