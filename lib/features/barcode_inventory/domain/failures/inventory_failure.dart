/// Domain failures for barcode inventory. Mapped to [Failure] at boundaries.
///
/// Each failure carries a stable machine-readable [code] (see
/// [InventoryFailureCodes]) so the presentation layer can map it to a
/// localized message. [message] stays an English technical description for
/// logs and debugging — domain and data layers remain locale-free.
sealed class InventoryFailure {
  const InventoryFailure({required this.code, required this.message});

  final String code;
  final String message;
}

/// Stable failure codes consumed by the presentation layer for localization.
abstract final class InventoryFailureCodes {
  static const load = 'inventory.load';
  static const save = 'inventory.save';
  static const create = 'inventory.create';
  static const duplicateBarcode = 'inventory.duplicateBarcode';
  static const validationBarcode = 'inventory.validation.barcode';
  static const validationName = 'inventory.validation.name';
  static const validationDescription = 'inventory.validation.description';
  static const validationQuantity = 'inventory.validation.quantity';
  static const validationUnknownItem = 'inventory.validation.unknownItem';
  static const insufficientStock = 'inventory.insufficientStock';
  static const decode = 'inventory.decode';
  static const export = 'inventory.export';
  static const exportEmpty = 'inventory.exportEmpty';
  static const import = 'inventory.import';
  static const importEmpty = 'inventory.importEmpty';
  static const importMissingColumns = 'inventory.importMissingColumns';
  static const importNoValidRows = 'inventory.importNoValidRows';
}

final class InventoryLoadFailure extends InventoryFailure {
  const InventoryLoadFailure([String message = 'Could not load inventory'])
    : super(code: InventoryFailureCodes.load, message: message);
}

final class InventorySaveFailure extends InventoryFailure {
  const InventorySaveFailure([String message = 'Could not save scan'])
    : super(code: InventoryFailureCodes.save, message: message);
}

final class InventoryCreateFailure extends InventoryFailure {
  const InventoryCreateFailure([String message = 'Could not save item'])
    : super(code: InventoryFailureCodes.create, message: message);
}

final class InventoryDuplicateBarcodeFailure extends InventoryFailure {
  const InventoryDuplicateBarcodeFailure([
    String message = 'An item with this barcode already exists',
  ]) : super(code: InventoryFailureCodes.duplicateBarcode, message: message);
}

final class InventoryValidationFailure extends InventoryFailure {
  const InventoryValidationFailure({
    required super.code,
    required super.message,
  });
}

final class InventoryInsufficientStockFailure extends InventoryFailure {
  const InventoryInsufficientStockFailure([
    String message = 'Not enough stock to ship this quantity',
  ]) : super(code: InventoryFailureCodes.insufficientStock, message: message);
}

final class InventoryDecodeFailure extends InventoryFailure {
  const InventoryDecodeFailure([
    String message = 'No barcode or QR code found in that image',
  ]) : super(code: InventoryFailureCodes.decode, message: message);
}

final class InventoryExportFailure extends InventoryFailure {
  const InventoryExportFailure({
    super.code = InventoryFailureCodes.export,
    super.message = 'Could not export inventory',
  });
}

final class InventoryImportFailure extends InventoryFailure {
  const InventoryImportFailure({
    super.code = InventoryFailureCodes.import,
    super.message = 'Could not import inventory',
  });
}
