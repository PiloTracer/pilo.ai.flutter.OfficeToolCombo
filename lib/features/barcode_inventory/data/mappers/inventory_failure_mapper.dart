import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';

/// Maps a domain [InventoryFailure] to the cross-cutting [Failure] type.
///
/// The stable [InventoryFailure.code] travels in [Failure.message] so the
/// presentation layer can resolve a localized message from it.
Failure mapInventoryFailure(InventoryFailure failure) {
  return IoFailure(failure.code);
}

InventoryFailure? mapFailureToInventory(Failure failure) {
  for (final candidate in _knownFailures) {
    if (failure.message == candidate.code) {
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
