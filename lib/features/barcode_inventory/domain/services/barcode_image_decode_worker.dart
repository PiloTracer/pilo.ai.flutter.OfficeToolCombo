import 'dart:typed_data';

import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/services/barcode_image_decoder.dart';

/// Top-level entry for [Isolate.run] — keeps heavy ZXing work off the UI thread.
List<String> decodeBarcodesInBackground(Uint8List bytes) {
  final result = BarcodeImageDecoder().decodeBytes(bytes);
  return switch (result) {
    Success(:final data) => data,
    Err() => const <String>[],
  };
}
