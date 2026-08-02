import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';

abstract class InventoryRepository {
  Future<Result<List<InventoryItem>>> loadItems();

  Future<Result<List<ScanEvent>>> loadRecentScans({int limit = 20});

  Future<Result<InventoryItem>> processScan({
    required String barcode,
    required ScanMode mode,
    int? countQuantity,
  });

  Future<Result<InventoryItem>> createItem({
    required String barcode,
    required String name,
    String description = '',
    required int startingQuantity,
  });

  Future<Result<InventoryItem>> updateItem({
    required String id,
    required String name,
    String description = '',
    required int quantityOnHand,
  });

  Future<Result<void>> deleteItem(String id);

  Future<Result<List<String>>> decodeBarcodesFromImagePath(String path);

  Future<Result<List<String>>> pickBarcodeImagePaths();

  Future<Result<MultiImageDecodeOutcome>> decodeBarcodeImagePaths(
    List<String> paths,
  );

  Future<Result<MultiImageDecodeOutcome>> pickAndDecodeBarcodeImages();

  Future<Result<String?>> exportInventoryCsv({String? outputPath});

  Future<Result<int>> importInventoryCsv(String path);

  Future<Result<void>> purgeExpiredScanEvents();
}
