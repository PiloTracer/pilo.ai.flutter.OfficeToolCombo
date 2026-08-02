/// Outcome of decoding one or more barcode/QR image files.
class MultiImageDecodeOutcome {
  const MultiImageDecodeOutcome({
    required this.decodedBarcodes,
    required this.failedFileNames,
  });

  /// Successfully decoded identifiers, in picker order.
  final List<String> decodedBarcodes;

  /// Basenames of files where no code was found or read failed.
  final List<String> failedFileNames;

  bool get isEmpty => decodedBarcodes.isEmpty && failedFileNames.isEmpty;

  int get successCount => decodedBarcodes.length;

  int get failureCount => failedFileNames.length;

  String batchSummary({required int scansHandled}) {
    final parts = <String>[];
    if (scansHandled > 0) {
      parts.add('$scansHandled scan${scansHandled == 1 ? '' : 's'} processed');
    }
    if (failureCount > 0) {
      parts.add(
        '$failureCount image${failureCount == 1 ? '' : 's'} with no code found',
      );
    }
    if (parts.isEmpty) {
      return 'No barcodes found in selected images';
    }
    return parts.join(' · ');
  }
}
