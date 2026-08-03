import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Maps stable [InventoryFailureCodes] to localized messages.
///
/// Inventory failures travel across the data/presentation boundary as a
/// [Failure] whose `message` is the failure code; anything that is not a
/// known code (raw technical details from non-inventory failures) is
/// returned unchanged.
extension InventoryFailureL10n on AppLocalizations {
  String inventoryFailureMessage(String code) {
    return switch (code) {
      InventoryFailureCodes.load => inventoryFailureLoad,
      InventoryFailureCodes.save => inventoryFailureSave,
      InventoryFailureCodes.create => inventoryFailureCreate,
      InventoryFailureCodes.duplicateBarcode => inventoryFailureDuplicate,
      InventoryFailureCodes.validationBarcode => inventoryErrorEnterBarcode,
      InventoryFailureCodes.validationName => inventoryErrorEnterName,
      InventoryFailureCodes.validationDescription =>
        inventoryFailureValidationDescription,
      InventoryFailureCodes.validationQuantity => inventoryErrorInvalidQuantity,
      InventoryFailureCodes.validationUnknownItem =>
        inventoryFailureValidationUnknown,
      InventoryFailureCodes.insufficientStock => inventoryFailureInsufficient,
      InventoryFailureCodes.decode => inventoryFailureDecode,
      InventoryFailureCodes.export => inventoryFailureExport,
      InventoryFailureCodes.exportEmpty => inventoryFailureExportEmpty,
      InventoryFailureCodes.import => inventoryFailureImport,
      InventoryFailureCodes.importEmpty => inventoryFailureImportEmpty,
      InventoryFailureCodes.importMissingColumns =>
        inventoryFailureImportColumns,
      InventoryFailureCodes.importNoValidRows => inventoryFailureImportNoRows,
      _ => code,
    };
  }
}

/// Localized labels for [ScanMode]; the domain enum stays locale-free.
extension ScanModeL10n on ScanMode {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ScanMode.receive => l10n.inventoryModeReceiveLabel,
      ScanMode.ship => l10n.inventoryModeShipLabel,
      ScanMode.count => l10n.inventoryModeCountLabel,
    };
  }

  String localizedDescription(AppLocalizations l10n) {
    return switch (this) {
      ScanMode.receive => l10n.inventoryModeReceiveDescription,
      ScanMode.ship => l10n.inventoryModeShipDescription,
      ScanMode.count => l10n.inventoryModeCountDescription,
    };
  }
}
