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

  group('normalizeBarcodeText edge cases', () {
    test('empty and whitespace-only input normalizes to empty', () {
      expect(normalizeBarcodeText(''), '');
      expect(normalizeBarcodeText('   '), '');
    });

    test('extracts digits from dashed numeric strings', () {
      expect(normalizeBarcodeText('4-012345-678905'), '4012345678905');
    });

    test('collapses internal whitespace for alphanumeric codes', () {
      expect(normalizeBarcodeText('AB 12 CD'), 'AB12CD');
    });

    test('digit runs outside the 8-14 range keep non-digit characters', () {
      // 7 digits: not a plausible EAN/UPC, only whitespace is stripped.
      expect(normalizeBarcodeText('1234567'), '1234567');
      // 15 digits: same rule.
      expect(normalizeBarcodeText('123456789012345'), '123456789012345');
    });
  });

  group('barcodeFormatPriority', () {
    test('linear product codes outrank Code128 and QR', () {
      expect(
        barcodeFormatPriority(Format.ean13),
        greaterThan(barcodeFormatPriority(Format.upca)),
      );
      expect(
        barcodeFormatPriority(Format.upca),
        greaterThan(barcodeFormatPriority(Format.code128)),
      );
      expect(
        barcodeFormatPriority(Format.code128),
        greaterThan(barcodeFormatPriority(Format.qrCode)),
      );
    });

    test('covers every ranked linear format in descending order', () {
      expect(barcodeFormatPriority(Format.ean13), 300);
      expect(barcodeFormatPriority(Format.upca), 290);
      expect(barcodeFormatPriority(Format.ean8), 280);
      expect(barcodeFormatPriority(Format.upce), 270);
      expect(barcodeFormatPriority(Format.code128), 200);
      expect(barcodeFormatPriority(Format.code39), 190);
      expect(barcodeFormatPriority(Format.code93), 185);
      expect(barcodeFormatPriority(Format.itf), 180);
      expect(barcodeFormatPriority(Format.codabar), 170);
      expect(barcodeFormatPriority(Format.dataBar), 160);
      expect(barcodeFormatPriority(Format.dataBarExpanded), 150);
      expect(barcodeFormatPriority(Format.qrCode), 50);
      expect(barcodeFormatPriority(Format.microQRCode), 45);
      expect(barcodeFormatPriority(Format.rmqrCode), 44);
    });

    test('unknown or null format gets the low default priority', () {
      expect(barcodeFormatPriority(null), 80);
      expect(barcodeFormatPriority(Format.aztec), 80);
    });
  });

  group('looksLikeUrl', () {
    test('detects http/https/www and scheme-like strings', () {
      expect(looksLikeUrl('http://example.com'), isTrue);
      expect(looksLikeUrl('https://example.com/x'), isTrue);
      expect(looksLikeUrl('WWW.example.com'), isTrue);
      expect(looksLikeUrl('ftp://files.example.com'), isTrue);
    });

    test('plain identifiers are not URLs', () {
      expect(looksLikeUrl('7453078513034'), isFalse);
      expect(looksLikeUrl('example.com'), isFalse);
      expect(looksLikeUrl('ST-2355-C'), isFalse);
    });
  });

  group('selectInventoryIdentifiers branches', () {
    test('empty detection list selects nothing', () {
      expect(selectInventoryIdentifiers(const []), isEmpty);
    });

    test('detections that normalize to empty are skipped', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(text: '   ', format: Format.qrCode, priority: 50),
        const DetectedBarcode(
          text: 'SKU-C128',
          format: Format.code128,
          priority: 200,
        ),
      ]);

      expect(selected, ['SKU-C128']);
    });

    test(
      'returns all linear codes sorted by priority (EAN-13 > UPC > Code128)',
      () {
        final selected = selectInventoryIdentifiers([
          const DetectedBarcode(
            text: 'SKU-C128',
            format: Format.code128,
            priority: 200,
          ),
          const DetectedBarcode(
            text: '012345678905',
            format: Format.upca,
            priority: 290,
          ),
          const DetectedBarcode(
            text: '7 453078 513034',
            format: Format.ean13,
            priority: 300,
          ),
        ]);

        expect(selected, ['7453078513034', '012345678905', 'SKU-C128']);
      },
    );

    test('keeps the higher-priority duplicate after normalization', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(
          text: '8054041617576',
          format: Format.code128,
          priority: 200,
        ),
        const DetectedBarcode(
          text: '8 054041 617576',
          format: Format.ean13,
          priority: 300,
        ),
      ]);

      expect(selected, ['8054041617576']);
    });

    test('non-URL codes win over URL-looking strings', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(
          text: 'https://pointerline.com/p/123',
          format: Format.qrCode,
          priority: 50,
        ),
        const DetectedBarcode(
          text: 'INTERNAL-SKU-7',
          format: Format.qrCode,
          priority: 50,
        ),
      ]);

      expect(selected, ['INTERNAL-SKU-7']);
    });

    test('falls back to the URL when it is the only detection', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(
          text: 'https://pointerline.com',
          format: Format.qrCode,
          priority: 50,
        ),
      ]);

      expect(selected, ['https://pointerline.com']);
    });

    test('unknown-format codes take the non-URL path', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(
          text: 'AZTEC-CODE-1',
          format: Format.aztec,
          priority: 80,
        ),
        const DetectedBarcode(
          text: 'www.example.com',
          format: Format.qrCode,
          priority: 50,
        ),
      ]);

      expect(selected, ['AZTEC-CODE-1']);
    });

    test('returns empty when every detection normalizes to empty', () {
      final selected = selectInventoryIdentifiers([
        const DetectedBarcode(text: '   ', format: Format.qrCode, priority: 50),
        const DetectedBarcode(text: '', format: Format.ean13, priority: 130),
      ]);

      expect(selected, isEmpty);
    });
  });
}
