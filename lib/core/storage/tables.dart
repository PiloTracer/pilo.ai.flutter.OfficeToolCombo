import 'package:drift/drift.dart';

class InventoryItems extends Table {
  TextColumn get id => text()();

  TextColumn get sku => text()();

  TextColumn get barcode => text().unique()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get description =>
      text().withLength(min: 0, max: 500).withDefault(const Constant(''))();

  IntColumn get quantityOnHand => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ScanEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get barcode => text()();

  TextColumn get itemId => text().nullable()();

  DateTimeColumn get scannedAt => dateTime()();

  IntColumn get delta => integer()();
}

class AppSettingsTable extends Table {
  IntColumn get id => integer()();

  TextColumn get locale => text().withDefault(const Constant('en'))();

  IntColumn get scanRetentionDays =>
      integer().withDefault(const Constant(90))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
