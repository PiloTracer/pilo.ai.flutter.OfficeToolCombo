import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/csv_import_summary.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_providers.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class _MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void useWideSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Pumps [InventoryView] against [db] and waits for the initial load.
  /// Pass [repository] to override the default repository (e.g. a mock).
  /// Returns the provider container for driving/reading the view model.
  Future<ProviderContainer> pumpInventoryView(
    WidgetTester tester,
    AppDatabase db, {
    Locale locale = const Locale('en'),
    InventoryRepository? repository,
  }) async {
    useWideSurface(tester);
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          if (repository != null)
            inventoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: buildL10nTestApp(
          theme: AppTheme.dark(),
          locale: locale,
          home: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const InventoryView();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));
    return container;
  }

  InventoryViewModel viewModel(ProviderContainer container) {
    return container.read(inventoryViewModelProvider.notifier);
  }

  InventoryUiState uiState(ProviderContainer container) {
    return container.read(inventoryViewModelProvider);
  }

  Finder scanField() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Scan barcode',
    );
  }

  Finder searchField() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Search stock',
    );
  }

  Finder textFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
  }

  /// Types [barcode] into the wedge scan field and submits it (Enter).
  ///
  /// Pumps in bounded 50ms steps instead of `pumpAndSettle` so the fake clock
  /// stays under the 2s toast-clear timer and the 4s SnackBar duration —
  /// keeping both observable for assertions right after the scan.
  Future<void> submitScan(WidgetTester tester, String barcode) async {
    await tester.enterText(scanField(), barcode);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Expires the 2s toast-clear timer and the SnackBar durations so no timers
  /// are left pending at the end of a test. A scan after a create queues a
  /// second SnackBar behind the first, so this must outlast two chained 4s
  /// durations. Uses bounded pumps rather than `pumpAndSettle` — a queued
  /// SnackBar can keep scheduling transitions long enough to time
  /// `pumpAndSettle` out.
  Future<void> flushToasts(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('scan mode chips switch the view model scan mode', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);

    expect(uiState(container).scanMode, ScanMode.receive);

    await tester.tap(find.text('Ship'));
    await tester.pumpAndSettle();
    expect(uiState(container).scanMode, ScanMode.ship);

    await tester.tap(find.text('Count'));
    await tester.pumpAndSettle();
    expect(uiState(container).scanMode, ScanMode.count);

    await tester.tap(find.text('Receive'));
    await tester.pumpAndSettle();
    expect(uiState(container).scanMode, ScanMode.receive);
  });

  testWidgets('receive scan increments quantity and updates summary chips', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await viewModel(
      container,
    ).confirmCreateItem(barcode: 'R-1', name: 'Hex bolt', startingQuantity: 3);
    await tester.pumpAndSettle();

    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('3 units on hand'), findsOneWidget);

    await submitScan(tester, 'R-1');

    expect(find.text('4 units on hand'), findsOneWidget);
    // The SnackBar queues behind the create toast, so assert via state.
    expect(uiState(container).toastMessage, 'Received Hex bolt: 4');
    await flushToasts(tester);
  });

  testWidgets('ship scan with insufficient stock surfaces a toast', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await viewModel(
      container,
    ).confirmCreateItem(barcode: 'S-1', name: 'Empty box', startingQuantity: 0);
    viewModel(container).setScanMode(ScanMode.ship);
    await tester.pumpAndSettle();

    await submitScan(tester, 'S-1');

    // The SnackBar queues behind the create toast, so assert via state.
    expect(
      uiState(container).toastMessage,
      'Not enough stock to ship this quantity',
    );
    expect(uiState(container).errorMessage, isNull);
    // Still zero — the failed ship did not mutate stock.
    expect(find.text('0 units on hand'), findsOneWidget);
    await flushToasts(tester);
  });

  testWidgets('count mode scan opens the count dialog and sets quantity', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await viewModel(
      container,
    ).confirmCreateItem(barcode: 'C-1', name: 'Washers', startingQuantity: 3);
    viewModel(container).setScanMode(ScanMode.count);
    await tester.pumpAndSettle();

    await submitScan(tester, 'C-1');

    expect(find.text('Set counted quantity'), findsOneWidget);
    expect(find.text('Identifier: C-1'), findsOneWidget);

    await tester.enterText(textFieldByLabel('Quantity on hand'), '9');
    await tester.tap(find.text('Set quantity'));
    await tester.pumpAndSettle();

    expect(uiState(container).items.single.quantityOnHand, 9);
    expect(find.text('9 units on hand'), findsOneWidget);
    await flushToasts(tester);
  });

  testWidgets('unknown identifier prompts to create; cancel keeps list empty', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);

    await submitScan(tester, 'UNKNOWN-7');

    expect(find.text('New item'), findsOneWidget);
    // The barcode shows in the read-only field and its helper text.
    expect(find.text('UNKNOWN-7'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New item'), findsNothing);
    expect(uiState(container).items, isEmpty);
    expect(uiState(container).pendingUnknownBarcode, isNull);
  });

  testWidgets('unknown identifier create flow adds the item from the dialog', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);

    await submitScan(tester, 'NEW-9');

    await tester.enterText(textFieldByLabel('Item name'), 'Anchor bolt');
    await tester.enterText(textFieldByLabel('Starting quantity'), '6');
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(uiState(container).items.single.name, 'Anchor bolt');
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('6 units on hand'), findsOneWidget);
    await flushToasts(tester);
  });

  testWidgets('manual entry opens the dialog and submits the identifier', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    await pumpInventoryView(tester, db);

    await tester.tap(find.text('Manual entry'));
    await tester.pumpAndSettle();
    expect(find.text('Enter identifier manually'), findsOneWidget);

    await tester.enterText(
      textFieldByLabel('Barcode / SKU / alphanumeric ID'),
      'MAN-1',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Unknown identifier routes into the create flow.
    expect(find.text('New item'), findsOneWidget);
    expect(find.text('MAN-1'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('search field filters the stock list and shows match count', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    final vm = viewModel(container);
    await vm.confirmCreateItem(
      barcode: 'bolt-1',
      name: 'Hex bolt',
      startingQuantity: 2,
    );
    await vm.confirmCreateItem(
      barcode: 'nut-1',
      name: 'Hex nut',
      startingQuantity: 4,
    );
    await tester.pumpAndSettle();

    await tester.enterText(searchField(), 'bolt');
    await tester.pumpAndSettle();

    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('Hex bolt'), findsOneWidget);
    expect(find.text('Hex nut'), findsNothing);

    // Clear via the suffix icon.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Hex bolt'), findsOneWidget);
    expect(find.text('Hex nut'), findsOneWidget);
    expect(find.text('1 match'), findsNothing);
    await flushToasts(tester);
  });

  testWidgets('recent scans panel renders scan events', (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await viewModel(container).confirmCreateItem(
      barcode: 'R-2',
      name: 'Wood screw',
      startingQuantity: 1,
    );
    await tester.pumpAndSettle();

    await submitScan(tester, 'R-2');

    expect(find.text('Recent scans'), findsOneWidget);
    // Item name shows in both the stock list and the recent scans panel.
    expect(find.text('Wood screw'), findsWidgets);
    expect(find.text('+1'), findsWidgets);
    await flushToasts(tester);
  });

  testWidgets('partial import shows the skipped-rows banner; dismiss clears', (
    tester,
  ) async {
    // A mocked import keeps real file IO out of the widget test.
    final item = InventoryItem(
      id: 'A-1',
      sku: 'A-1',
      barcode: 'A-1',
      name: 'Widget',
      quantityOnHand: 5,
      updatedAt: DateTime(2024),
    );
    final repository = _MockInventoryRepository();
    when(
      () => repository.loadItems(),
    ).thenAnswer((_) async => Success<List<InventoryItem>>([item]));
    when(
      () => repository.loadRecentScans(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Success<List<ScanEvent>>([]));
    when(() => repository.importInventoryCsv(any())).thenAnswer(
      (_) async => const Success(
        CsvImportSummary(importedCount: 1, skippedCount: 1, duplicateCount: 0),
      ),
    );

    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(
      tester,
      db,
      repository: repository,
    );
    await viewModel(container).importCsvFile('ignored.csv');
    await tester.pumpAndSettle();

    expect(
      find.text('1 row from the last import was skipped or merged'),
      findsOneWidget,
    );
    expect(uiState(container).phase, InventoryPhase.partial);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(
      find.text('1 row from the last import was skipped or merged'),
      findsNothing,
    );
    expect(uiState(container).skippedRowCount, 0);
    await flushToasts(tester);
  });

  testWidgets('load failure surfaces the error state and retry', (
    tester,
  ) async {
    final repository = _MockInventoryRepository();
    when(() => repository.loadItems()).thenAnswer(
      (_) async => const Err<List<InventoryItem>>(IoFailure('boom')),
    );
    when(
      () => repository.loadRecentScans(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Err<List<ScanEvent>>(IoFailure('boom')));

    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(
      tester,
      db,
      repository: repository,
    );

    expect(find.text('Could not load inventory'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(uiState(container).phase, InventoryPhase.error);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // The repository still fails, so the error state persists.
    expect(uiState(container).phase, InventoryPhase.error);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('edit flow updates the item through the popup menu', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await viewModel(
      container,
    ).confirmCreateItem(barcode: 'E-1', name: 'Old name', startingQuantity: 2);
    await tester.pumpAndSettle();

    final itemMenu = find.descendant(
      of: find.byType(Card),
      matching: find.byType(PopupMenuButton<String>),
    );
    await tester.tap(itemMenu.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit item'));
    await tester.pumpAndSettle();

    expect(find.text('Old name'), findsWidgets);

    await tester.enterText(textFieldByLabel('Item name'), 'New name');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(uiState(container).items.single.name, 'New name');
    await flushToasts(tester);
  });

  testWidgets('delete flow removes the item after confirmation', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final container = await pumpInventoryView(tester, db);
    await viewModel(container).confirmCreateItem(
      barcode: 'D-1',
      name: 'Doomed item',
      startingQuantity: 1,
    );
    await tester.pumpAndSettle();

    final itemMenu = find.descendant(
      of: find.byType(Card),
      matching: find.byType(PopupMenuButton<String>),
    );
    await tester.tap(itemMenu.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();

    expect(find.text('Delete item?'), findsOneWidget);
    expect(find.text('Remove "Doomed item" from inventory?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(uiState(container).items, isEmpty);
    expect(find.text('No items yet'), findsWidgets);
    await flushToasts(tester);
  });

  testWidgets('renders the screen title in Spanish', (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    await pumpInventoryView(tester, db, locale: const Locale('es'));

    // AppBar title and the body headline.
    expect(find.text('Inventario con códigos de barras'), findsNWidgets(2));
    expect(find.text('Aún no hay artículos'), findsWidgets);
  });
}
