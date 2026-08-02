import 'package:flutter_zxing/flutter_zxing.dart';

/// Picks inventory-relevant identifiers from raw scan results.
List<String> selectInventoryIdentifiers(List<DetectedBarcode> detected) {
  if (detected.isEmpty) {
    return const [];
  }

  final normalized = <String, DetectedBarcode>{};
  for (final item in detected) {
    final value = normalizeBarcodeText(item.text);
    if (value.isEmpty) {
      continue;
    }
    final existing = normalized[value];
    if (existing == null || item.priority > existing.priority) {
      normalized[value] = item.copyWith(text: value);
    }
  }

  final linear =
      normalized.values
          .where((item) => item.priority >= 100)
          .toList(growable: false)
        ..sort((a, b) => b.priority.compareTo(a.priority));

  if (linear.isNotEmpty) {
    return linear.map((item) => item.text).toList(growable: false);
  }

  final nonUrl =
      normalized.values.where((item) => !item.isUrl).toList(growable: false)
        ..sort((a, b) => b.priority.compareTo(a.priority));

  if (nonUrl.isNotEmpty) {
    return [nonUrl.first.text];
  }

  return [normalized.values.first.text];
}

String normalizeBarcodeText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.length >= 8 && digitsOnly.length <= 14) {
    return digitsOnly;
  }

  return trimmed.replaceAll(RegExp(r'\s+'), '');
}

int barcodeFormatPriority(int? format) {
  return switch (format) {
    Format.ean13 => 300,
    Format.upca => 290,
    Format.ean8 => 280,
    Format.upce => 270,
    Format.code128 => 200,
    Format.code39 => 190,
    Format.code93 => 185,
    Format.itf => 180,
    Format.codabar => 170,
    Format.dataBar => 160,
    Format.dataBarExpanded => 150,
    Format.qrCode => 50,
    Format.microQRCode => 45,
    Format.rmqrCode => 44,
    _ => 80,
  };
}

bool looksLikeUrl(String text) {
  final lower = text.toLowerCase();
  return lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('www.') ||
      lower.contains('://');
}

class DetectedBarcode {
  const DetectedBarcode({
    required this.text,
    required this.format,
    required this.priority,
  });

  final String text;
  final int? format;
  final int priority;

  bool get isUrl => looksLikeUrl(text);

  DetectedBarcode copyWith({String? text}) {
    return DetectedBarcode(
      text: text ?? this.text,
      format: format,
      priority: priority,
    );
  }
}
