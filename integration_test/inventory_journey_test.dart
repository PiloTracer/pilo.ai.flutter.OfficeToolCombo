// F2-T5 — offline barcode-inventory journey: create an item, adjust its
// quantity, and keep both across app restarts.
//
// Written with the plain widgets binding so it runs under
// `flutter test integration_test/` (same pattern as locale_persist_test.dart).
// The scanner field is a keyboard wedge, so item creation and the quantity
// adjustment go through the ViewModel seam — but persistence is real: the
// drift database is a file on disk in a temp dir, and the simulated restart
// reopens that exact file with a brand-new ProviderScope.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/storage/app_database.dart';
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('created item and adjusted quantity survive a full restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final tempDir = await Directory.systemTemp.createTemp('inventory_journey_');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    final dbFile = File(
      '${tempDir.path}${Platform.pathSeparator}inventory.sqlite',
    );

    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppDatabase openDatabase() {
      // Real drift database backed by the temp file — not in-memory — so
      // the restart below exercises genuine persistence.
      return AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));
    }

    Future<void> bootFreshApp(AppDatabase database) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: OfficeToolComboApp(logger: AppLogger()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<ProviderContainer> navigateToInventory() async {
      await tester.tap(find.text('Barcode inventory'));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(InventoryView)),
      );
    }

    // First boot: home → barcode inventory → create + adjust via the
    // ViewModel seam (the scanner field is a keyboard wedge).
    final firstDatabase = openDatabase();
    await bootFreshApp(firstDatabase);
    expect(find.text('Choose a tool'), findsOneWidget);
    final container = await navigateToInventory();
    expect(find.text('No items yet'), findsWidgets);

    final viewModel = container.read(inventoryViewModelProvider.notifier);
    final createResult = await viewModel.confirmCreateItem(
      barcode: 'JRN-0001',
      name: 'Journey widget',
      startingQuantity: 2,
    );
    createResult.when(
      cleared: () => fail('scan submission was cleared'),
      handled: () {},
      needsCreate: () => fail('unexpected needsCreate'),
      needsCount: (_) => fail('unexpected needsCount'),
      failed: (message) => fail('createItem failed: $message'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Journey widget'), findsOneWidget);
    expect(find.text('Qty: 2'), findsOneWidget);

    await viewModel.updateItem(
      id: 'JRN-0001',
      name: 'Journey widget',
      quantityOnHand: 7,
    );
    await tester.pumpAndSettle();
    expect(find.text('Qty: 7'), findsOneWidget);
    expect(dbFile.existsSync(), isTrue);

    // Full restart: tear the tree down (disposing the ProviderScope), close
    // the database handle — simulating process shutdown — and boot a
    // brand-new app instance that reopens the same file with a fresh
    // ProviderScope.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await firstDatabase.close();
    await bootFreshApp(openDatabase());

    await navigateToInventory();

    expect(find.text('Journey widget'), findsOneWidget);
    expect(find.text('Qty: 7'), findsOneWidget);
  });
}
