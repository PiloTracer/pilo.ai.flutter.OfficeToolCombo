import 'package:drift/drift.dart';
import 'package:office_tool_combo/core/storage/app_database.dart' as db;
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';

InventoryItem mapInventoryItemRow(db.InventoryItem row) {
  return InventoryItem(
    id: row.id,
    sku: row.sku,
    barcode: row.barcode,
    name: row.name,
    description: row.description,
    quantityOnHand: row.quantityOnHand,
    updatedAt: row.updatedAt,
  );
}

ScanEvent mapScanEventRow(db.ScanEvent row) {
  return ScanEvent(
    id: row.id,
    barcode: row.barcode,
    itemId: row.itemId,
    scannedAt: row.scannedAt,
    delta: row.delta,
  );
}

db.InventoryItemsCompanion inventoryItemCompanion({
  required String id,
  required String sku,
  required String barcode,
  required String name,
  String description = '',
  required int quantityOnHand,
  required DateTime updatedAt,
}) {
  return db.InventoryItemsCompanion.insert(
    id: id,
    sku: sku,
    barcode: barcode,
    name: name,
    description: Value(description),
    quantityOnHand: Value(quantityOnHand),
    updatedAt: updatedAt,
  );
}

db.ScanEventsCompanion scanEventCompanion({
  required String barcode,
  String? itemId,
  required DateTime scannedAt,
  required int delta,
}) {
  return db.ScanEventsCompanion.insert(
    barcode: barcode,
    itemId: Value(itemId),
    scannedAt: scannedAt,
    delta: delta,
  );
}
