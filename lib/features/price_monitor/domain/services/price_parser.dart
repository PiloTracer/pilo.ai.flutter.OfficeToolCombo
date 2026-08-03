import 'dart:convert';

import 'package:decimal/decimal.dart';

/// Pure price extraction service (SPEC §2 — one numeric price or failure).
///
/// Strategy, in order:
/// 1. JSON body — first numeric value under a `price` / `amount` / `value`
///    key, searching nested objects and arrays (keys matched
///    case-insensitively, in that priority order).
/// 2. HTML / plain text — first currency-looking number such as
///    `$1,234.56` or `12.99`.
///
/// Returns null when no single price can be extracted.
class PriceParser {
  const PriceParser();

  static const _jsonKeys = ['price', 'amount', 'value'];

  /// Matches `$1,234.56`, `1,234.56`, `12.99`, `€ 99.5`, `£7`. A bare
  /// integer without a currency symbol is not price-looking enough.
  static final _currencyPattern = RegExp(
    r'[$€£]\s?\d[\d,]*(?:\.\d{1,2})?'
    r'|\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?'
    r'|\d+\.\d{1,2}',
  );

  Decimal? parse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _parseJson(trimmed) ?? _parseText(trimmed);
  }

  Decimal? _parseJson(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on Object {
      return null;
    }
    for (final key in _jsonKeys) {
      final found = _findNumericKey(decoded, key);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Depth-first search for [key]; objects first, then nested arrays.
  Decimal? _findNumericKey(Object? node, String key) {
    if (node is Map) {
      Decimal? nested;
      for (final entry in node.entries) {
        if (entry.key is String && (entry.key as String).toLowerCase() == key) {
          final direct = _asDecimal(entry.value);
          if (direct != null) {
            return direct;
          }
        }
      }
      for (final value in node.values) {
        nested = _findNumericKey(value, key);
        if (nested != null) {
          return nested;
        }
      }
      return null;
    }
    if (node is List) {
      for (final item in node) {
        final nested = _findNumericKey(item, key);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  Decimal? _asDecimal(Object? value) {
    if (value is num) {
      return Decimal.parse(value.toString());
    }
    if (value is String) {
      return Decimal.tryParse(value.trim());
    }
    return null;
  }

  Decimal? _parseText(String body) {
    final match = _currencyPattern.firstMatch(body);
    if (match == null) {
      return null;
    }
    final normalized = match.group(0)!.replaceAll(RegExp(r'[$€£\s,]'), '');
    return Decimal.tryParse(normalized);
  }
}
