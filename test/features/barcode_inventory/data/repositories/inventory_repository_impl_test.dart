import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';

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
      InventoryFailureCodes.insufficientStock,
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
      InventoryFailureCodes.duplicateBarcode,
    );
  });

  group('validation and edge paths', () {
    test('processScan rejects an empty barcode by code', () async {
      final result = await repository.processScan(
        barcode: '   ',
        mode: ScanMode.receive,
      );

      expect(result, isA<Err<InventoryItem>>());
      expect(
        (result as Err<InventoryItem>).failure.message,
        InventoryFailureCodes.validationBarcode,
      );
    });

    test(
      'processScan count without a quantity on an unknown barcode fails by code',
      () async {
        final result = await repository.processScan(
          barcode: 'GHOST-1',
          mode: ScanMode.count,
        );

        expect(result, isA<Err<InventoryItem>>());
        expect(
          (result as Err<InventoryItem>).failure.message,
          InventoryFailureCodes.validationUnknownItem,
        );
      },
    );

    test('processScan count with a quantity creates the item', () async {
      final result = await repository.processScan(
        barcode: 'COUNT-1',
        mode: ScanMode.count,
        countQuantity: 8,
      );

      expect(result, isA<Success<InventoryItem>>());
      expect((result as Success<InventoryItem>).data.quantityOnHand, 8);
    });

    test(
      'createItem validates barcode, name, description and quantity',
      () async {
        final emptyBarcode = await repository.createItem(
          barcode: '  ',
          name: 'Widget',
          startingQuantity: 1,
        );
        expect(
          (emptyBarcode as Err<InventoryItem>).failure.message,
          InventoryFailureCodes.validationBarcode,
        );

        final emptyName = await repository.createItem(
          barcode: 'V-1',
          name: '  ',
          startingQuantity: 1,
        );
        expect(
          (emptyName as Err<InventoryItem>).failure.message,
          InventoryFailureCodes.validationName,
        );

        final longDescription = await repository.createItem(
          barcode: 'V-2',
          name: 'Widget',
          description: 'x' * 501,
          startingQuantity: 1,
        );
        expect(
          (longDescription as Err<InventoryItem>).failure.message,
          InventoryFailureCodes.validationDescription,
        );

        final badQuantity = await repository.createItem(
          barcode: 'V-3',
          name: 'Widget',
          startingQuantity: 1000000,
        );
        expect(
          (badQuantity as Err<InventoryItem>).failure.message,
          InventoryFailureCodes.validationQuantity,
        );
      },
    );

    test('updateItem rejects invalid input by code', () async {
      final emptyName = await repository.updateItem(
        id: 'whatever',
        name: ' ',
        quantityOnHand: 1,
      );
      expect(
        (emptyName as Err<InventoryItem>).failure.message,
        InventoryFailureCodes.validationName,
      );

      final badQuantity = await repository.updateItem(
        id: 'whatever',
        name: 'Widget',
        quantityOnHand: -1,
      );
      expect(
        (badQuantity as Err<InventoryItem>).failure.message,
        InventoryFailureCodes.validationQuantity,
      );
    });

    test('updateItem fails for a missing item by code', () async {
      final result = await repository.updateItem(
        id: 'missing',
        name: 'Widget',
        quantityOnHand: 1,
      );

      expect(result, isA<Err<InventoryItem>>());
      expect(
        (result as Err<InventoryItem>).failure.message,
        InventoryFailureCodes.save,
      );
    });

    test('updateItem persists edits', () async {
      final created =
          (await repository.createItem(
                    barcode: 'U-1',
                    name: 'Original',
                    startingQuantity: 2,
                  )
                  as Success<InventoryItem>)
              .data;

      final updated = await repository.updateItem(
        id: created.id,
        name: 'Renamed',
        description: 'Shelf B2',
        quantityOnHand: 9,
      );

      expect(updated, isA<Success<InventoryItem>>());
      final item = (updated as Success<InventoryItem>).data;
      expect(item.name, 'Renamed');
      expect(item.description, 'Shelf B2');
      expect(item.quantityOnHand, 9);
      expect(item.barcode, 'U-1');
    });

    test('deleteItem removes the item', () async {
      final created =
          (await repository.createItem(
                    barcode: 'DEL-1',
                    name: 'Doomed',
                    startingQuantity: 1,
                  )
                  as Success<InventoryItem>)
              .data;

      final result = await repository.deleteItem(created.id);

      expect(result, isA<Success<void>>());
      final items =
          (await repository.loadItems()) as Success<List<InventoryItem>>;
      expect(items.data, isEmpty);
    });
  });
}
