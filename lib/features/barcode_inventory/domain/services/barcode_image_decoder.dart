import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image/image.dart' as img;
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/services/barcode_identifier_selector.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/services/barcode_image_decode_worker.dart';

/// Decodes QR and linear barcodes (EAN-13, UPC-A, Code128, etc.) from image bytes.
class BarcodeImageDecoder {
  BarcodeImageDecoder({Zxing? zxing}) : _zxing = zxing ?? Zxing();

  final Zxing _zxing;

  Future<Result<List<String>>> decodeBytesAsync(Uint8List bytes) async {
    try {
      final identifiers = await Isolate.run(
        () => decodeBarcodesInBackground(bytes),
      );
      if (identifiers.isEmpty) {
        return Err<List<String>>(
          IoFailure(const InventoryDecodeFailure().message),
        );
      }
      return Success(identifiers);
    } on Object {
      return Err<List<String>>(
        IoFailure(const InventoryDecodeFailure().message),
      );
    }
  }

  Result<List<String>> decodeBytes(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const Err<List<String>>(
        IoFailure('Could not read that image file'),
      );
    }

    final detected = <DetectedBarcode>[];
    for (final variant in _preprocessedVariants(image)) {
      detected.addAll(_scanImage(variant));
    }

    final identifiers = selectInventoryIdentifiers(detected);
    if (identifiers.isEmpty) {
      return Err<List<String>>(
        IoFailure(const InventoryDecodeFailure().message),
      );
    }
    return Success(identifiers);
  }

  List<DetectedBarcode> _scanImage(img.Image image) {
    final resized = resizeToMaxSize(image, 2048);
    final params = DecodeParams(
      imageFormat: ImageFormat.lum,
      tryHarder: true,
      tryRotate: true,
      tryInverted: true,
      tryDownscale: true,
      maxSize: 2048,
      maxNumberOfSymbols: 8,
      width: resized.width,
      height: resized.height,
    );

    final results = _zxing.readBarcodes(
      resized.getBytes(order: img.ChannelOrder.red),
      params,
    );
    return results.codes
        .where(
          (code) => code.isValid && (code.text?.trim().isNotEmpty ?? false),
        )
        .map(
          (code) => DetectedBarcode(
            text: code.text!.trim(),
            format: code.format,
            priority: barcodeFormatPriority(code.format),
          ),
        )
        .toList(growable: false);
  }

  Iterable<img.Image> _preprocessedVariants(img.Image source) sync* {
    final gray = img.grayscale(source);
    yield gray;
    yield _adjustContrast(img.Image.from(gray), amount: 120);
    yield _adjustContrast(img.Image.from(gray), amount: 180);
    yield img.invert(img.Image.from(gray));
  }

  img.Image _adjustContrast(img.Image image, {required int amount}) {
    return img.adjustColor(image, contrast: amount);
  }
}
