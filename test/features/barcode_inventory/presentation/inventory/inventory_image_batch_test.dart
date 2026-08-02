import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';

void main() {
  group('MultiImageDecodeOutcome.batchSummary', () {
    test('reports processed scans and decode failures', () {
      const outcome = MultiImageDecodeOutcome(
        decodedBarcodes: ['A', 'B', 'C'],
        failedFileNames: ['bad.png'],
      );

      expect(
        outcome.batchSummary(scansHandled: 2),
        '2 scans processed · 1 image with no code found',
      );
    });

    test('reports when no barcodes decoded', () {
      const outcome = MultiImageDecodeOutcome(
        decodedBarcodes: [],
        failedFileNames: ['a.png', 'b.png'],
      );

      expect(
        outcome.batchSummary(scansHandled: 0),
        '2 images with no code found',
      );
    });
  });
}
