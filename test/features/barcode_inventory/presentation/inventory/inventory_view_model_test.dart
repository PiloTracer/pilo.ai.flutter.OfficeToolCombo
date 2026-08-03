import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_providers.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.inMemory();
    container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          InventoryRepositoryImpl(database: database),
        ),
      ],
    );
    tempDir = await Directory.systemTemp.createTemp('inventory_vm_');
  });

  tearDown(() async {
    container.dispose();
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadInventory moves to success with empty list', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();

    final state = container.read(inventoryViewModelProvider);
    expect(state.phase, InventoryPhase.empty);
    expect(state.items, isEmpty);
  });

  test('submitScan for unknown barcode sets pending create', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();

    final result = await viewModel.submitScan('UNKNOWN-999');
    expect(result, isA<ScanSubmissionResult>());

    final state = container.read(inventoryViewModelProvider);
    expect(state.pendingUnknownBarcode, 'UNKNOWN-999');
  });

  test('confirmCreateItem adds item to state', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();

    await viewModel.confirmCreateItem(
      barcode: 'NEW-1',
      name: 'Manual item',
      startingQuantity: 2,
    );

    final state = container.read(inventoryViewModelProvider);
    expect(state.items, hasLength(1));
    expect(state.items.first.name, 'Manual item');
    expect(state.toastMessage, 'Added Manual item');
  });

  test('setSearchQuery filters items in derived list', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();
    await viewModel.confirmCreateItem(
      barcode: 'bolt-99',
      name: 'Big bolt',
      startingQuantity: 1,
    );
    await viewModel.confirmCreateItem(
      barcode: 'nut-99',
      name: 'Small nut',
      startingQuantity: 1,
    );

    viewModel.setSearchQuery('bolt');
    expect(viewModel.filteredItems, hasLength(1));
    expect(viewModel.filteredItems.first.barcode, 'bolt-99');
  });

  test('setScanMode updates mode', () {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    viewModel.setScanMode(ScanMode.ship);
    expect(container.read(inventoryViewModelProvider).scanMode, ScanMode.ship);
  });

  test(
    'importCsvFile wires skipped/duplicate counts into state; dismiss clears',
    () async {
      final csvFile = File('${tempDir.path}/import.csv');
      await csvFile.writeAsString(
        'barcode,name,description,sku,quantity_on_hand,updated_at\n'
        'A-1,Widget,,A-1,5,\n'
        'A-1,Widget v2,,A-1,7,\n'
        'B-2,Gadget,,B-2,not-a-number,\n'
        'C-3,,,C-3,2,\n',
      );

      final viewModel = container.read(inventoryViewModelProvider.notifier);
      await viewModel.loadInventory();
      await viewModel.importCsvFile(csvFile.path);

      var state = container.read(inventoryViewModelProvider);
      expect(state.items, hasLength(1));
      expect(state.items.first.name, 'Widget v2');
      expect(state.items.first.quantityOnHand, 7);
      // 2 invalid rows skipped + 1 duplicate merged.
      expect(state.skippedRowCount, 3);
      expect(state.phase, InventoryPhase.partial);
      expect(state.toastMessage, contains('Imported 1 item'));
      expect(state.toastMessage, contains('2 rows skipped'));
      expect(state.toastMessage, contains('1 duplicate merged'));

      viewModel.dismissSkippedRows();
      state = container.read(inventoryViewModelProvider);
      expect(state.skippedRowCount, 0);
      expect(state.phase, InventoryPhase.success);
    },
  );

  test('importCsvFile surfaces a localized error for a bad CSV', () async {
    final csvFile = File('${tempDir.path}/bad.csv');
    await csvFile.writeAsString('foo,bar\n1,2\n');

    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();
    await viewModel.importCsvFile(csvFile.path);

    final state = container.read(inventoryViewModelProvider);
    expect(
      state.errorMessage,
      'CSV must include barcode, name, and quantity_on_hand columns',
    );
  });
}
