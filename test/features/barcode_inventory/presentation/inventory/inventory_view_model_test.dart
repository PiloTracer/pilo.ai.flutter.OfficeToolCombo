import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_providers.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase.inMemory();
    container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          InventoryRepositoryImpl(database: database),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
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
}
