import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';

void main() {
  late AppDatabase database;
  late InventoryRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = InventoryRepositoryImpl(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('createItem persists and loadItems returns it', () async {
    final createResult = await repository.createItem(
      barcode: '1234567890',
      name: 'Test widget',
      startingQuantity: 3,
    );

    expect(createResult, isA<Success<InventoryItem>>());
    final created = (createResult as Success<InventoryItem>).data;
    expect(created.barcode, '1234567890');
    expect(created.quantityOnHand, 3);

    final loadResult = await repository.loadItems();
    expect(loadResult, isA<Success<List<InventoryItem>>>());
    final items = (loadResult as Success<List<InventoryItem>>).data;
    expect(items, hasLength(1));
    expect(items.first.name, 'Test widget');
  });

  test('processScan increments known item quantity', () async {
    await repository.createItem(
      barcode: 'ABC-001',
      name: 'Bolt pack',
      startingQuantity: 5,
    );

    final scanResult = await repository.processScan(
      barcode: 'ABC-001',
      mode: ScanMode.receive,
    );

    expect(scanResult, isA<Success<InventoryItem>>());
    expect((scanResult as Success<InventoryItem>).data.quantityOnHand, 6);
  });

  test('processScan ship fails when stock insufficient', () async {
    await repository.createItem(
      barcode: 'ABC-002',
      name: 'Single item',
      startingQuantity: 0,
    );

    final scanResult = await repository.processScan(
      barcode: 'ABC-002',
      mode: ScanMode.ship,
    );

    expect(scanResult, isA<Err<InventoryItem>>());
    expect(
      (scanResult as Err<InventoryItem>).failure.message,
      'Not enough stock to ship this quantity',
    );
  });

  test('loadItems returns multiple created items', () async {
    await repository.createItem(
      barcode: 'bolt-1',
      name: 'Hex bolt',
      startingQuantity: 2,
    );
    await repository.createItem(
      barcode: 'nut-1',
      name: 'Hex nut',
      startingQuantity: 4,
    );

    final loadResult = await repository.loadItems();
    final items = (loadResult as Success<List<InventoryItem>>).data;
    expect(items, hasLength(2));
  });

  test('duplicate barcode blocked on create', () async {
    await repository.createItem(
      barcode: 'DUP-1',
      name: 'First',
      startingQuantity: 1,
    );

    final second = await repository.createItem(
      barcode: 'DUP-1',
      name: 'Second',
      startingQuantity: 1,
    );

    expect(second, isA<Err<InventoryItem>>());
    expect(
      (second as Err<InventoryItem>).failure.message,
      'An item with this barcode already exists',
    );
  });
}
