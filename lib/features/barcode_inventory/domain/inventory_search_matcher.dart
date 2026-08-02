import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';

/// Fuzzy, accent-insensitive inventory search with multi-term AND matching.
abstract final class InventorySearchMatcher {
  static List<InventoryItem> filterAndRank(
    List<InventoryItem> items,
    String query,
  ) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return items;
    }

    final scored = <({InventoryItem item, int score})>[];
    for (final item in items) {
      final score = scoreItem(item, trimmed);
      if (score > 0) {
        scored.add((item: item, score: score));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
    });

    return scored.map((entry) => entry.item).toList(growable: false);
  }

  static int scoreItem(InventoryItem item, String query) {
    final terms = tokenizeQuery(query);
    if (terms.isEmpty) {
      return 0;
    }

    final fields = <String>[
      item.name,
      item.barcode,
      item.sku,
      item.description,
      '${item.quantityOnHand}',
    ];

    var total = 0;
    for (final term in terms) {
      final termScore = _bestTermScore(term, fields);
      if (termScore <= 0) {
        return 0;
      }
      total += termScore;
    }
    return total;
  }

  static int _bestTermScore(String term, List<String> fields) {
    var best = 0;
    for (final field in fields) {
      if (field.isEmpty) {
        continue;
      }
      best = best > _termScoreInField(term, field)
          ? best
          : _termScoreInField(term, field);
    }
    return best;
  }

  static int _termScoreInField(String term, String field) {
    final normalizedField = normalizeForSearch(field);
    final normalizedTerm = normalizeForSearch(term);
    if (normalizedTerm.isEmpty) {
      return 0;
    }

    if (normalizedField.contains(normalizedTerm)) {
      return normalizedField.startsWith(normalizedTerm) ? 120 : 100;
    }

    final compactField = compactIdentifier(field);
    final compactTerm = compactIdentifier(term);
    if (compactTerm.isNotEmpty && compactField.contains(compactTerm)) {
      return 95;
    }

    final words = _words(normalizedField);
    var best = 0;
    for (final word in words) {
      final fuzzy = _fuzzyWordScore(normalizedTerm, word);
      if (fuzzy > best) {
        best = fuzzy;
      }
    }
    return best;
  }

  static int _fuzzyWordScore(String term, String word) {
    if (word.isEmpty) {
      return 0;
    }
    if (word == term) {
      return 90;
    }
    if (word.startsWith(term)) {
      return 85;
    }

    final maxDistance = _maxEditDistance(term.length);
    if (maxDistance == 0) {
      return 0;
    }

    final distance = levenshteinDistance(term, word);
    if (distance <= maxDistance) {
      return 70 - (distance * 10);
    }

    if (term.length >= 3 && word.length >= term.length) {
      for (var start = 0; start <= word.length - term.length; start++) {
        final slice = word.substring(start, start + term.length);
        final sliceDistance = levenshteinDistance(term, slice);
        if (sliceDistance <= maxDistance) {
          return 60 - (sliceDistance * 10);
        }
      }
    }

    return 0;
  }

  static List<String> tokenizeQuery(String query) {
    return normalizeForSearch(query)
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
  }

  static Iterable<String> _words(String normalizedText) {
    return normalizedText
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty);
  }

  static String normalizeForSearch(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.toLowerCase().trim().codeUnits) {
      buffer.write(_accentFold[codeUnit] ?? String.fromCharCode(codeUnit));
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String compactIdentifier(String value) {
    return normalizeForSearch(value).replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static int _maxEditDistance(int termLength) {
    if (termLength <= 2) {
      return 0;
    }
    if (termLength <= 4) {
      return 1;
    }
    if (termLength <= 7) {
      return 2;
    }
    return 3;
  }

  static int levenshteinDistance(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        current[j + 1] = _min3(
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + cost,
        );
      }
      for (var j = 0; j < current.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }

  static int _min3(int a, int b, int c) {
    return a < b ? (a < c ? a : c) : (b < c ? b : c);
  }

  static const Map<int, String> _accentFold = {
    224: 'a', 225: 'a', 226: 'a', 227: 'a', 228: 'a', 229: 'a', // àáâãäå
    232: 'e', 233: 'e', 234: 'e', 235: 'e', // èéêë
    236: 'i', 237: 'i', 238: 'i', 239: 'i', // ìíîï
    242: 'o', 243: 'o', 244: 'o', 245: 'o', 246: 'o', // òóôõö
    249: 'u', 250: 'u', 251: 'u', 252: 'u', // ùúûü
    253: 'y', 255: 'y', // ýÿ
    241: 'n', // ñ
    231: 'c', // ç
  };
}
