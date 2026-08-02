import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [InventoryItems, ScanEvents, AppSettingsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.inMemory() : super(openInMemoryDatabaseConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(
        appSettingsTable,
      ).insert(AppSettingsTableCompanion.insert(id: const Value(1)));
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(inventoryItems, inventoryItems.description);
      }
    },
  );

  Future<List<InventoryItem>> loadAllItems() {
    return (select(inventoryItems)..orderBy([
          (row) => OrderingTerm.asc(row.name),
          (row) => OrderingTerm.asc(row.barcode),
        ]))
        .get();
  }

  Future<InventoryItem?> findItemByBarcode(String barcode) {
    return (select(
      inventoryItems,
    )..where((row) => row.barcode.equals(barcode))).getSingleOrNull();
  }

  Future<InventoryItem> upsertItem(InventoryItemsCompanion companion) {
    return into(inventoryItems).insertReturning(
      companion,
      onConflict: DoUpdate(
        (old) => companion,
        target: [inventoryItems.barcode],
      ),
    );
  }

  Future<void> deleteItem(String id) {
    return (delete(inventoryItems)..where((row) => row.id.equals(id))).go();
  }

  Future<int> insertScanEvent(ScanEventsCompanion event) {
    return into(scanEvents).insert(event);
  }

  Future<List<ScanEvent>> loadRecentScanEvents({int limit = 20}) {
    return (select(scanEvents)
          ..orderBy([(row) => OrderingTerm.desc(row.scannedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> purgeOldScanEvents({required int retentionDays}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    await (delete(
      scanEvents,
    )..where((row) => row.scannedAt.isSmallerThanValue(cutoff))).go();
  }

  Future<int> readScanRetentionDays() async {
    final row = await (select(
      appSettingsTable,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    return row?.scanRetentionDays ?? 90;
  }
}
