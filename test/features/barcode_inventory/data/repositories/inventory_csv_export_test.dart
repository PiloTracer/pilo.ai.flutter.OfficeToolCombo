import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/csv_import_summary.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/inventory_search_matcher.dart';

bool _nativeZxingAvailable() {
  if (!Platform.isLinux) {
    return true;
  }
  try {
    DynamicLibrary.open('libflutter_zxing.so');
    return true;
  } on Object {
    return false;
  }
}

final _skipWithoutNativeLib = Platform.isLinux && !_nativeZxingAvailable()
    ? 'Run `flutter build linux` first (needs libflutter_zxing.so)'
    : false;

void main() {
  late AppDatabase database;
  late InventoryRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.inMemory();
    repository = InventoryRepositoryImpl(database: database);
    tempDir = await Directory.systemTemp.createTemp('inventory_export_');
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  String tempPath(String name) =>
      '${tempDir.path}${Platform.pathSeparator}$name';

  Future<List<InventoryItem>> loadItems() async {
    final result = await repository.loadItems();
    return (result as Success<List<InventoryItem>>).data;
  }

  group('exportInventoryCsv', () {
    test('writes header and one row per item to the chosen path', () async {
      await repository.createItem(
        barcode: 'E-1',
        name: 'Export widget',
        description: 'Plain',
        startingQuantity: 4,
      );
      await repository.createItem(
        barcode: 'E-2',
        name: 'Gadget, with comma',
        startingQuantity: 2,
      );

      final path = tempPath('chosen.csv');
      final result = await repository.exportInventoryCsv(outputPath: path);

      expect(result, isA<Success<String?>>());
      expect((result as Success<String?>).data, path);

      final lines = await File(path).readAsLines();
      expect(
        lines.first,
        'barcode,name,description,sku,quantity_on_hand,updated_at',
      );
      expect(lines, hasLength(3));
      expect(lines[1], startsWith('E-1,Export widget,Plain,E-1,4,'));
      // Commas in values are quoted so the CSV stays parseable.
      expect(lines[2], startsWith('E-2,"Gadget, with comma",,E-2,2,'));
    });

    test('appends .csv when the chosen path lacks the extension', () async {
      await repository.createItem(
        barcode: 'E-3',
        name: 'Extensionless',
        startingQuantity: 1,
      );

      final result = await repository.exportInventoryCsv(
        outputPath: tempPath('no_extension'),
      );

      expect(result, isA<Success<String?>>());
      final written = (result as Success<String?>).data;
      expect(written, endsWith('.csv'));
      expect(File(written!).existsSync(), isTrue);
    });

    test(
      'fails with the exportEmpty code when there is nothing to export',
      () async {
        final result = await repository.exportInventoryCsv(
          outputPath: tempPath('empty.csv'),
        );

        expect(result, isA<Err<String?>>());
        expect(
          (result as Err<String?>).failure.message,
          InventoryFailureCodes.exportEmpty,
        );
        expect(File(tempPath('empty.csv')).existsSync(), isFalse);
      },
    );

    test('round-trip import(export) preserves all items', () async {
      await repository.createItem(
        barcode: 'RT-1',
        name: 'Round trip "quoted"',
        description: 'Notes, with comma',
        startingQuantity: 6,
      );
      await repository.createItem(
        barcode: 'RT-2',
        name: 'Second',
        startingQuantity: 0,
      );

      final exportPath = tempPath('round_trip.csv');
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

      final items =
          ((await freshRepo.loadItems()) as Success<List<InventoryItem>>).data;
      expect(items, hasLength(2));
      final quoted = items.firstWhere((item) => item.barcode == 'RT-1');
      expect(quoted.name, 'Round trip "quoted"');
      expect(quoted.description, 'Notes, with comma');
      expect(quoted.quantityOnHand, 6);
      expect(
        items.firstWhere((item) => item.barcode == 'RT-2').quantityOnHand,
        0,
      );
    });
  });

  group('decodeBarcodesFromImagePath', () {
    test('returns failure for a non-image file', () async {
      final file = File(tempPath('not_an_image.csv'));
      await file.writeAsString('barcode,name,quantity_on_hand\nX-1,Nope,3\n');

      final result = await repository.decodeBarcodesFromImagePath(file.path);

      expect(result, isA<Err<List<String>>>());
    }, skip: _skipWithoutNativeLib);

    test('returns failure for a missing file', () async {
      final result = await repository.decodeBarcodesFromImagePath(
        tempPath('does_not_exist.png'),
      );

      expect(result, isA<Err<List<String>>>());
    });
  });

  group('decodeBarcodeImagePaths', () {
    test('empty path list decodes to an empty outcome', () async {
      final result = await repository.decodeBarcodeImagePaths(const []);

      expect(result, isA<Success<MultiImageDecodeOutcome>>());
      final outcome = (result as Success<MultiImageDecodeOutcome>).data;
      expect(outcome.decodedBarcodes, isEmpty);
      expect(outcome.failedFileNames, isEmpty);
    });

    test('undecodable files land in failedFileNames', () async {
      final file = File(tempPath('broken.png'));
      await file.writeAsBytes(List.filled(64, 7));

      final result = await repository.decodeBarcodeImagePaths([file.path]);

      expect(result, isA<Success<MultiImageDecodeOutcome>>());
      final outcome = (result as Success<MultiImageDecodeOutcome>).data;
      expect(outcome.decodedBarcodes, isEmpty);
      expect(outcome.failedFileNames, ['broken.png']);
    }, skip: _skipWithoutNativeLib);
  });

  group('search delegation', () {
    test('empty query returns all loaded items; query filters', () async {
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
      final items = await loadItems();

      expect(
        InventorySearchMatcher.filterAndRank(items, ''),
        hasLength(items.length),
      );
      expect(
        InventorySearchMatcher.filterAndRank(items, '   '),
        hasLength(items.length),
      );

      final matches = InventorySearchMatcher.filterAndRank(items, 'bolt');
      expect(matches, hasLength(1));
      expect(matches.single.barcode, 'bolt-1');
    });
  });
}
