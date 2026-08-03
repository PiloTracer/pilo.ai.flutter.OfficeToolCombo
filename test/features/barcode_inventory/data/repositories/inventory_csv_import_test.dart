import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/csv_import_summary.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';

void main() {
  late AppDatabase database;
  late InventoryRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.inMemory();
    repository = InventoryRepositoryImpl(database: database);
    tempDir = await Directory.systemTemp.createTemp('inventory_csv_');
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeCsv(String name, String content) {
    return File('${tempDir.path}${Platform.pathSeparator}$name')
        .writeAsString(content);
  }

  Future<List<InventoryItem>> loadItems() async {
    final result = await repository.loadItems();
    return (result as Success<List<InventoryItem>>).data;
  }

  test('export then import round-trips all items', () async {
    await repository.createItem(
      barcode: 'R-1',
      name: 'Round trip widget',
      description: 'Comma, "quoted" notes',
      startingQuantity: 4,
    );
    await repository.createItem(
      barcode: 'R-2',
      name: 'Second item',
      startingQuantity: 9,
    );

    final exportPath = '${tempDir.path}${Platform.pathSeparator}export.csv';
    final exportResult = await repository.exportInventoryCsv(
      outputPath: exportPath,
    );
    expect(exportResult, isA<Success<String?>>());

    // Import into a fresh database so only round-tripped rows can appear.
    final freshDb = AppDatabase.inMemory();
    addTearDown(freshDb.close);
    final freshRepo = InventoryRepositoryImpl(database: freshDb);
    final importResult = await freshRepo.importInventoryCsv(exportPath);

    expect(importResult, isA<Success<CsvImportSummary>>());
    final summary = (importResult as Success<CsvImportSummary>).data;
    expect(summary.importedCount, 2);
    expect(summary.skippedCount, 0);
    expect(summary.duplicateCount, 0);

    final freshItems =
        ((await freshRepo.loadItems()) as Success<List<InventoryItem>>).data;
    expect(freshItems, hasLength(2));
    final widget = freshItems.firstWhere((item) => item.barcode == 'R-1');
    expect(widget.name, 'Round trip widget');
    expect(widget.description, 'Comma, "quoted" notes');
    expect(widget.quantityOnHand, 4);
  });

  test('BOM-prefixed CSV imports successfully', () async {
    final file = await writeCsv(
      'bom.csv',
      '\uFEFFbarcode,name,description,sku,quantity_on_hand,updated_at\n'
      'BOM-1,Excel item,,BOM-1,3,\n',
    );

    final result = await repository.importInventoryCsv(file.path);

    expect(result, isA<Success<CsvImportSummary>>());
    expect((result as Success<CsvImportSummary>).data.importedCount, 1);
    final items = await loadItems();
    expect(items.single.barcode, 'BOM-1');
    expect(items.single.quantityOnHand, 3);
  });

  test('CRLF and lone-CR line endings parse', () async {
    final crlf = await writeCsv(
      'crlf.csv',
      'barcode,name,quantity_on_hand\r\nCR-1,Windows item,2\r\n',
    );
    final crlfResult = await repository.importInventoryCsv(crlf.path);
    expect(crlfResult, isA<Success<CsvImportSummary>>());
    expect((crlfResult as Success<CsvImportSummary>).data.importedCount, 1);

    final cr = await writeCsv(
      'cr.csv',
      'barcode,name,quantity_on_hand\rCR-2,Legacy mac item,6\r',
    );
    final crResult = await repository.importInventoryCsv(cr.path);
    expect(crResult, isA<Success<CsvImportSummary>>());
    expect((crResult as Success<CsvImportSummary>).data.importedCount, 1);
    expect((await loadItems()).single.quantityOnHand, 6);
  });

  test('rows with invalid quantities are skipped and counted', () async {
    final file = await writeCsv(
      'invalid_qty.csv',
      'barcode,name,quantity_on_hand\n'
      'OK-1,Good,5\n'
      'BAD-1,Not a number,abc\n'
      'BAD-2,Empty,\n'
      'BAD-3,Negative,-2\n'
      'BAD-4,Too big,1000000\n'
      'OK-2,Also good,0\n',
    );

    final result = await repository.importInventoryCsv(file.path);

    expect(result, isA<Success<CsvImportSummary>>());
    final summary = (result as Success<CsvImportSummary>).data;
    expect(summary.importedCount, 2);
    expect(summary.skippedCount, 4);
    expect(summary.duplicateCount, 0);

    final items = await loadItems();
    expect(items.map((item) => item.barcode), unorderedEquals(['OK-1', 'OK-2']));
    // Zero is a legitimate quantity and must be kept, not treated as invalid.
    expect(items.firstWhere((item) => item.barcode == 'OK-2').quantityOnHand, 0);
  });

  test('duplicate barcodes: last row wins and duplicates are counted', () async {
    final file = await writeCsv(
      'dupes.csv',
      'barcode,name,quantity_on_hand\n'
      'DUP-1,First version,1\n'
      'KEEP-1,Other item,2\n'
      'DUP-1,Last version,9\n',
    );

    final result = await repository.importInventoryCsv(file.path);

    expect(result, isA<Success<CsvImportSummary>>());
    final summary = (result as Success<CsvImportSummary>).data;
    expect(summary.importedCount, 2);
    expect(summary.duplicateCount, 1);
    expect(summary.skippedCount, 0);

    final items = await loadItems();
    expect(items, hasLength(2));
    final dup = items.firstWhere((item) => item.barcode == 'DUP-1');
    expect(dup.name, 'Last version');
    expect(dup.quantityOnHand, 9);
  });

  test('import replaces all existing items (replaceAllItems)', () async {
    await repository.createItem(
      barcode: 'OLD-1',
      name: 'Pre-existing',
      startingQuantity: 12,
    );

    final file = await writeCsv(
      'replace.csv',
      'barcode,name,quantity_on_hand\nNEW-1,Replacement,3\n',
    );
    final result = await repository.importInventoryCsv(file.path);
    expect(result, isA<Success<CsvImportSummary>>());

    final items = await loadItems();
    expect(items, hasLength(1));
    expect(items.single.barcode, 'NEW-1');
  });

  test('CSV with only invalid rows fails with importNoValidRows code', () async {
    final file = await writeCsv(
      'all_bad.csv',
      'barcode,name,quantity_on_hand\nBAD-1,Nope,xyz\n',
    );

    final result = await repository.importInventoryCsv(file.path);

    expect(result, isA<Err<CsvImportSummary>>());
    expect(
      (result as Err<CsvImportSummary>).failure.message,
      InventoryFailureCodes.importNoValidRows,
    );
  });

  test('empty CSV fails with importEmpty code', () async {
    final file = await writeCsv('empty.csv', '');

    final result = await repository.importInventoryCsv(file.path);

    expect(result, isA<Err<CsvImportSummary>>());
    expect(
      (result as Err<CsvImportSummary>).failure.message,
      InventoryFailureCodes.importEmpty,
    );
  });
}
