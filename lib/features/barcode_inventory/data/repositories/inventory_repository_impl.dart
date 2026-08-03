import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/mappers/inventory_failure_mapper.dart';
import 'package:office_tool_combo/features/barcode_inventory/data/sources/inventory_local_source.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/csv_import_summary.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/services/barcode_image_decoder.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({
    required AppDatabase database,
    InventoryLocalSource? localSource,
    BarcodeImageDecoder? imageDecoder,
  }) : _localSource = localSource ?? InventoryLocalSource(database),
       _imageDecoder = imageDecoder ?? BarcodeImageDecoder();

  final InventoryLocalSource _localSource;
  final BarcodeImageDecoder _imageDecoder;

  @override
  Future<Result<List<InventoryItem>>> loadItems() async {
    try {
      await _localSource.purgeExpiredScanEvents();
      final items = await _localSource.loadAllItems();
      return Success(items);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventoryLoadFailure('Could not load inventory: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<List<ScanEvent>>> loadRecentScans({int limit = 20}) async {
    try {
      final events = await _localSource.loadRecentScans(limit: limit);
      return Success(events);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventoryLoadFailure('Could not load scan history: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<InventoryItem>> processScan({
    required String barcode,
    required ScanMode mode,
    int? countQuantity,
  }) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationBarcode,
            message: 'Enter a barcode or identifier',
          ),
        ),
      );
    }

    try {
      if (mode == ScanMode.count && countQuantity == null) {
        final existing = await _localSource.findByBarcode(normalized);
        if (existing == null) {
          return Err(
            mapInventoryFailure(
              const InventoryValidationFailure(
                code: InventoryFailureCodes.validationUnknownItem,
                message: 'Unknown item — create it first or switch to Receive mode',
              ),
            ),
          );
        }
      }

      final item = await _localSource.applyScanTransaction(
        barcode: normalized,
        delta: mode == ScanMode.ship ? -1 : 1,
        mode: mode,
        countQuantity: countQuantity,
      );
      return Success(item);
    } on StateError catch (error) {
      if (error.message == 'insufficient') {
        return Err(
          mapInventoryFailure(const InventoryInsufficientStockFailure()),
        );
      }
      return Err(mapInventoryFailure(InventorySaveFailure(error.toString())));
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventorySaveFailure('Could not save scan: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<InventoryItem>> createItem({
    required String barcode,
    required String name,
    String description = '',
    required int startingQuantity,
  }) async {
    final normalizedBarcode = barcode.trim();
    final normalizedName = name.trim();
    final normalizedDescription = description.trim();

    if (normalizedBarcode.isEmpty) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationBarcode,
            message: 'Enter a barcode or identifier',
          ),
        ),
      );
    }
    if (normalizedName.isEmpty || normalizedName.length > 120) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationName,
            message: 'Enter an item name',
          ),
        ),
      );
    }
    if (normalizedDescription.length > 500) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationDescription,
            message: 'Description is too long',
          ),
        ),
      );
    }
    if (startingQuantity < 0 || startingQuantity > 999999) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationQuantity,
            message: 'Enter a valid quantity',
          ),
        ),
      );
    }

    try {
      final existing = await _localSource.findByBarcode(normalizedBarcode);
      if (existing != null) {
        return Err(
          mapInventoryFailure(const InventoryDuplicateBarcodeFailure()),
        );
      }
      final item = await _localSource.createItem(
        barcode: normalizedBarcode,
        name: normalizedName,
        description: normalizedDescription,
        startingQuantity: startingQuantity,
      );
      return Success(item);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventoryCreateFailure('Could not save item: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<InventoryItem>> updateItem({
    required String id,
    required String name,
    String description = '',
    required int quantityOnHand,
  }) async {
    final normalizedName = name.trim();
    final normalizedDescription = description.trim();
    if (normalizedName.isEmpty || normalizedName.length > 120) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationName,
            message: 'Enter an item name',
          ),
        ),
      );
    }
    if (normalizedDescription.length > 500) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationDescription,
            message: 'Description is too long',
          ),
        ),
      );
    }
    if (quantityOnHand < 0 || quantityOnHand > 999999) {
      return Err(
        mapInventoryFailure(
          const InventoryValidationFailure(
            code: InventoryFailureCodes.validationQuantity,
            message: 'Enter a valid quantity',
          ),
        ),
      );
    }

    try {
      final items = await _localSource.loadAllItems();
      final existing = items.where((item) => item.id == id).firstOrNull;
      if (existing == null) {
        return Err(
          mapInventoryFailure(
            const InventorySaveFailure('Item no longer exists'),
          ),
        );
      }
      final item = await _localSource.insertOrUpdateItem(
        id: existing.id,
        sku: existing.sku,
        barcode: existing.barcode,
        name: normalizedName,
        description: normalizedDescription,
        quantityOnHand: quantityOnHand,
      );
      return Success(item);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventorySaveFailure('Could not update item: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteItem(String id) async {
    try {
      await _localSource.deleteItem(id);
      return const Success(null);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventorySaveFailure('Could not delete item: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> decodeBarcodesFromImagePath(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      return _imageDecoder.decodeBytesAsync(bytes);
    } on Object catch (error) {
      return Err(IoFailure('Could not read image: $error'));
    }
  }

  @override
  Future<Result<List<String>>> pickBarcodeImagePaths({
    String? dialogTitle,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: dialogTitle ?? 'Select product label or barcode images',
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) {
        return const Success(<String>[]);
      }
      final paths = <String>[];
      for (final file in result.files) {
        final path = file.path;
        if (path != null && path.isNotEmpty) {
          paths.add(path);
        }
      }
      return Success(paths);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventoryDecodeFailure('Could not open image picker: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<MultiImageDecodeOutcome>> decodeBarcodeImagePaths(
    List<String> paths,
  ) async {
    if (paths.isEmpty) {
      return const Success(
        MultiImageDecodeOutcome(decodedBarcodes: [], failedFileNames: []),
      );
    }

    final decodedBarcodes = <String>[];
    final failedFileNames = <String>[];

    for (final path in paths) {
      final name = path.split(Platform.pathSeparator).last;
      final decoded = await decodeBarcodesFromImagePath(path);
      decoded.when(
        success: (barcodes) {
          final trimmed = barcodes
              .map((barcode) => barcode.trim())
              .where((barcode) => barcode.isNotEmpty)
              .toList(growable: false);
          if (trimmed.isEmpty) {
            failedFileNames.add(name);
          } else {
            decodedBarcodes.addAll(trimmed);
          }
        },
        failure: (_) => failedFileNames.add(name),
      );
    }

    return Success(
      MultiImageDecodeOutcome(
        decodedBarcodes: decodedBarcodes,
        failedFileNames: failedFileNames,
      ),
    );
  }

  @override
  Future<Result<MultiImageDecodeOutcome>> pickAndDecodeBarcodeImages() async {
    final pickResult = await pickBarcodeImagePaths();
    return pickResult.when(
      success: (paths) => decodeBarcodeImagePaths(paths),
      failure: (failure) => Err(failure),
    );
  }

  @override
  Future<Result<String?>> exportInventoryCsv({
    String? outputPath,
    String? dialogTitle,
  }) async {
    try {
      final items = await _localSource.loadAllItems();
      if (items.isEmpty) {
        return Err(
          mapInventoryFailure(
            const InventoryExportFailure(
              code: InventoryFailureCodes.exportEmpty,
              message: 'Nothing to export yet',
            ),
          ),
        );
      }

      var path = outputPath;
      if (path == null || path.isEmpty) {
        path = await FilePicker.saveFile(
          dialogTitle: dialogTitle ?? 'Export inventory CSV',
          fileName: 'inventory_export.csv',
          type: FileType.custom,
          allowedExtensions: const ['csv'],
        );
      }
      if (path == null || path.isEmpty) {
        return const Success(null);
      }
      if (!path.toLowerCase().endsWith('.csv')) {
        path = '$path.csv';
      }
      final written = await _localSource.writeCsvExport(items, path);
      return Success(written);
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventoryExportFailure(message: 'Could not export inventory: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<CsvImportSummary>> importInventoryCsv(String path) async {
    try {
      var content = await File(path).readAsString();
      // Excel-saved CSVs often start with a UTF-8 BOM; strip it or the header
      // becomes "﻿barcode" and column lookup fails.
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }
      // Normalize CRLF and lone-CR line endings so exports from any OS parse.
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) {
        return Err(
          mapInventoryFailure(
            const InventoryImportFailure(
              code: InventoryFailureCodes.importEmpty,
              message: 'That CSV file is empty',
            ),
          ),
        );
      }

      final header = rows.first
          .map((cell) => cell.toString().trim().toLowerCase())
          .toList();
      final barcodeIndex = header.indexOf('barcode');
      final nameIndex = header.indexOf('name');
      final descriptionIndex = header.indexOf('description');
      final skuIndex = header.indexOf('sku');
      final qtyIndex = header.indexOf('quantity_on_hand');

      if (barcodeIndex < 0 || nameIndex < 0 || qtyIndex < 0) {
        return Err(
          mapInventoryFailure(
            const InventoryImportFailure(
              code: InventoryFailureCodes.importMissingColumns,
              message:
                  'CSV must include barcode, name, and quantity_on_hand columns',
            ),
          ),
        );
      }

      final requiredIndexMax = [
        barcodeIndex,
        nameIndex,
        qtyIndex,
      ].reduce((a, b) => a > b ? a : b);
      final itemsByBarcode = <String, InventoryItem>{};
      var skippedCount = 0;
      var duplicateCount = 0;
      for (final row in rows.skip(1)) {
        final isBlankRow = row.every(
          (cell) => cell.toString().trim().isEmpty,
        );
        if (isBlankRow) {
          continue;
        }
        if (row.length <= requiredIndexMax) {
          skippedCount++;
          continue;
        }
        final barcode = row[barcodeIndex].toString().trim();
        final name = row[nameIndex].toString().trim();
        final qty = int.tryParse(row[qtyIndex].toString().trim());
        if (barcode.isEmpty ||
            name.isEmpty ||
            qty == null ||
            qty < 0 ||
            qty > 999999) {
          skippedCount++;
          continue;
        }
        final sku = skuIndex >= 0 && row.length > skuIndex
            ? row[skuIndex].toString().trim()
            : barcode;
        final description =
            descriptionIndex >= 0 && row.length > descriptionIndex
            ? row[descriptionIndex].toString().trim()
            : '';
        if (itemsByBarcode.containsKey(barcode)) {
          duplicateCount++;
        }
        // Last row wins for duplicate barcodes within one file.
        itemsByBarcode[barcode] = InventoryItem(
          id: barcode,
          sku: sku.isEmpty ? barcode : sku,
          barcode: barcode,
          name: name,
          description: description,
          quantityOnHand: qty,
          updatedAt: DateTime.now(),
        );
      }

      final imported = itemsByBarcode.values.toList(growable: false);
      if (imported.isEmpty) {
        return Err(
          mapInventoryFailure(
            const InventoryImportFailure(
              code: InventoryFailureCodes.importNoValidRows,
              message: 'No valid rows found in CSV',
            ),
          ),
        );
      }

      await _localSource.replaceAllItems(imported);
      return Success(
        CsvImportSummary(
          importedCount: imported.length,
          skippedCount: skippedCount,
          duplicateCount: duplicateCount,
        ),
      );
    } on Object catch (error) {
      return Err(
        mapInventoryFailure(
          InventoryImportFailure(message: 'Could not import inventory: $error'),
        ),
      );
    }
  }

  @override
  Future<Result<void>> purgeExpiredScanEvents() async {
    try {
      await _localSource.purgeExpiredScanEvents();
      return const Success(null);
    } on Object catch (error) {
      return Err(UnexpectedFailure('Could not purge scan events: $error'));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
