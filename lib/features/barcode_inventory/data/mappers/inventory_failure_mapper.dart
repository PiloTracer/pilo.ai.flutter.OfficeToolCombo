import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';

Failure mapInventoryFailure(InventoryFailure failure) {
  return IoFailure(failure.message);
}

InventoryFailure? mapFailureToInventory(Failure failure) {
  for (final candidate in _knownFailures) {
    if (failure.message == candidate.message) {
      return candidate;
    }
  }
  return null;
}

const _knownFailures = <InventoryFailure>[
  InventoryLoadFailure(),
  InventorySaveFailure(),
  InventoryCreateFailure(),
  InventoryDuplicateBarcodeFailure(),
  InventoryInsufficientStockFailure(),
  InventoryDecodeFailure(),
  InventoryExportFailure(),
  InventoryImportFailure(),
];
