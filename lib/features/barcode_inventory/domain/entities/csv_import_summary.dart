/// Report of a CSV inventory import.
class CsvImportSummary {
  const CsvImportSummary({
    required this.importedCount,
    required this.skippedCount,
    required this.duplicateCount,
  });

  /// Items actually written (unique barcodes, last row wins on duplicates).
  final int importedCount;

  /// Rows skipped because the barcode/name was missing or the quantity cell
  /// was unparseable or out of range.
  final int skippedCount;

  /// Rows whose barcode already appeared earlier in the same file; the last
  /// row wins and earlier duplicates are merged away.
  final int duplicateCount;
}
