import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/services/barcode_identifier_selector.dart';

void main() {
  group('normalizeBarcodeText', () {
    test('strips spaces from EAN-13 human-readable text', () {
      expect(normalizeBarcodeText('7 453078 513034'), '7453078513034');
      expect(normalizeBarcodeText('8 054041 617576'), '8054041617576');
    });

    test('preserves alphanumeric SKUs', () {
      expect(normalizeBarcodeText('ST-2355-C'), 'ST-2355-C');
    });
  });

  group('selectInventoryIdentifiers', () {
    test('prefers EAN over marketing QR URL', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(
          text: 'https://pointerline.com',
          format: Format.qrCode,
          priority: 50,
        ),
        const DetectedBarcode(
          text: '7 453078 513034',
          format: Format.ean13,
          priority: 300,
        ),
      ]);

      expect(selected, ['7453078513034']);
    });

    test('deduplicates same value across preprocessing passes', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(
          text: '8054041617576',
          format: Format.ean13,
          priority: 300,
        ),
        const DetectedBarcode(
          text: '8054041617576',
          format: Format.ean13,
          priority: 300,
        ),
      ]);

      expect(selected, ['8054041617576']);
    });
  });
}
