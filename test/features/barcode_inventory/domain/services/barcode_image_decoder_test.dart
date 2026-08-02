import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/services/barcode_image_decoder.dart';

bool _nativeZxingAvailable() {
  if (!Platform.isLinux) {
    return true;
  }
  try {
    DynamicLibrary.open('libflutter_zxing.so');
    return true;
  } on Object {
    return false;
  }
}

final _skipWithoutNativeLib = Platform.isLinux && !_nativeZxingAvailable()
    ? 'Run `flutter build linux` first (needs libflutter_zxing.so)'
    : false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BarcodeImageDecoder decoder;

  setUp(() {
    decoder = BarcodeImageDecoder();
  });

  group('BarcodeImageDecoder', () {
    test('decodes EAN-13 from clear product label photo', () async {
      final bytes = await File(
        'test/fixtures/barcode_inventory/ean_clear.png',
      ).readAsBytes();

      final result = decoder.decodeBytes(bytes);

      expect(result, isA<Success<List<String>>>());
      final barcodes = (result as Success<List<String>>).data;
      expect(barcodes, contains('8054041617576'));
    }, skip: _skipWithoutNativeLib);

    test('decodes EAN-13 from label with QR and glare', () async {
      final bytes = await File(
        'test/fixtures/barcode_inventory/ean_with_qr_glare.png',
      ).readAsBytes();

      final result = decoder.decodeBytes(bytes);

      expect(result, isA<Success<List<String>>>());
      final barcodes = (result as Success<List<String>>).data;
      expect(barcodes, contains('7453078513034'));
    }, skip: _skipWithoutNativeLib);
  });
}
