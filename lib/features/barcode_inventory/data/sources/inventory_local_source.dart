import 'dart:io';

import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/mappers/inventory_mapper.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';

class InventoryLocalSource {
  InventoryLocalSource(this._db);

  final AppDatabase _db;

  Future<List<InventoryItem>> loadAllItems() async {
    final rows = await _db.loadAllItems();
    return rows.map(mapInventoryItemRow).toList(growable: false);
  }

  Future<List<ScanEvent>> loadRecentScans({int limit = 20}) async {
    final rows = await _db.loadRecentScanEvents(limit: limit);
    return rows.map(mapScanEventRow).toList(growable: false);
  }

  Future<InventoryItem?> findByBarcode(String barcode) async {
    final row = await _db.findItemByBarcode(barcode);
    return row == null ? null : mapInventoryItemRow(row);
  }

  Future<InventoryItem> insertOrUpdateItem({
    required String id,
    required String sku,
    required String barcode,
    required String name,
    String description = '',
    required int quantityOnHand,
  }) async {
    final now = DateTime.now();
    final row = await _db.upsertItem(
      inventoryItemCompanion(
        id: id,
        sku: sku,
        barcode: barcode,
        name: name,
        description: description,
        quantityOnHand: quantityOnHand,
        updatedAt: now,
      ),
    );
    return mapInventoryItemRow(row);
  }

  Future<void> deleteItem(String id) => _db.deleteItem(id);

  Future<InventoryItem> applyScanTransaction({
    required String barcode,
    required int delta,
    required ScanMode mode,
    int? countQuantity,
    String? createName,
    int? createStartingQuantity,
  }) async {
    return _db.transaction(() async {
      final existing = await _db.findItemByBarcode(barcode);
      final now = DateTime.now();

      late InventoryItem item;
      late int appliedDelta;

      if (existing == null) {
        if (mode == ScanMode.ship) {
          throw StateError('insufficient');
        }
        final startingQty =
            createStartingQuantity ??
            (mode == ScanMode.count ? countQuantity ?? 0 : 1);
        final row = await _db.upsertItem(
          inventoryItemCompanion(
            id: barcode,
            sku: barcode,
            barcode: barcode,
            name: createName ?? barcode,
            quantityOnHand: startingQty,
            updatedAt: now,
          ),
        );
        item = mapInventoryItemRow(row);
        appliedDelta = startingQty;
      } else {
        final nextQty = switch (mode) {
          ScanMode.receive => existing.quantityOnHand + 1,
          ScanMode.ship => existing.quantityOnHand - 1,
          ScanMode.count => countQuantity ?? existing.quantityOnHand,
        };
        if (nextQty < 0) {
          throw StateError('insufficient');
        }
        appliedDelta = switch (mode) {
          ScanMode.receive => 1,
          ScanMode.ship => -1,
          ScanMode.count => nextQty - existing.quantityOnHand,
        };
        final row = await _db.upsertItem(
          inventoryItemCompanion(
            id: existing.id,
            sku: existing.sku,
            barcode: existing.barcode,
            name: existing.name,
            description: existing.description,
            quantityOnHand: nextQty,
            updatedAt: now,
          ),
        );
        item = mapInventoryItemRow(row);
      }

      await _db.insertScanEvent(
        scanEventCompanion(
          barcode: barcode,
          itemId: item.id,
          scannedAt: now,
          delta: appliedDelta,
        ),
      );

      return item;
    });
  }

  Future<InventoryItem> createItem({
    required String barcode,
    required String name,
    String description = '',
    required int startingQuantity,
  }) async {
    return insertOrUpdateItem(
      id: barcode,
      sku: barcode,
      barcode: barcode,
      name: name,
      description: description,
      quantityOnHand: startingQuantity,
    );
  }

  Future<void> purgeExpiredScanEvents() async {
    final retentionDays = await _db.readScanRetentionDays();
    await _db.purgeOldScanEvents(retentionDays: retentionDays);
  }

  Future<void> replaceAllItems(List<InventoryItem> items) async {
    await _db.transaction(() async {
      await _db.delete(_db.inventoryItems).go();
      for (final item in items) {
        await _db.upsertItem(
          inventoryItemCompanion(
            id: item.id,
            sku: item.sku,
            barcode: item.barcode,
            name: item.name,
            description: item.description,
            quantityOnHand: item.quantityOnHand,
            updatedAt: item.updatedAt,
          ),
        );
      }
    });
  }

  Future<String> writeCsvExport(
    List<InventoryItem> items,
    String outputPath,
  ) async {
    final buffer = StringBuffer(
      'barcode,name,description,sku,quantity_on_hand,updated_at\n',
    );
    for (final item in items) {
      buffer.writeln(
        '${_escapeCsv(item.barcode)},'
        '${_escapeCsv(item.name)},'
        '${_escapeCsv(item.description)},'
        '${_escapeCsv(item.sku)},'
        '${item.quantityOnHand},'
        '${item.updatedAt.toIso8601String()}',
      );
    }
    await File(outputPath).writeAsString(buffer.toString());
    return outputPath;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
