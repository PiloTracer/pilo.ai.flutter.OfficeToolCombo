import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InventoryRepositoryImpl(database: db);
});
