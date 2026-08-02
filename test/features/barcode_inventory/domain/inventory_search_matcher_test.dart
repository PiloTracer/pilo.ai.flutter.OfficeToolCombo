import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/inventory_search_matcher.dart';

InventoryItem _item({
  required String barcode,
  required String name,
  String description = '',
  int quantity = 1,
}) {
  return InventoryItem(
    id: barcode,
    sku: barcode,
    barcode: barcode,
    name: name,
    description: description,
    quantityOnHand: quantity,
    updatedAt: DateTime(2026, 8, 2),
  );
}

void main() {
  final items = [
    _item(
      barcode: '7453078513034',
      name: 'Tornillo hexagonal',
      description: 'Paquete grande · pasillo B',
    ),
    _item(barcode: 'bolt-99', name: 'Hex bolt pack', description: 'Steel M8'),
    _item(
      barcode: 'nut-44',
      name: 'Small nut',
      description: 'Aisle C',
      quantity: 12,
    ),
  ];

  group('InventorySearchMatcher', () {
    test('matches all items when query is empty', () {
      expect(InventorySearchMatcher.filterAndRank(items, ''), hasLength(3));
    });

    test('matches non-consecutive terms anywhere in item fields', () {
      final matches = InventorySearchMatcher.filterAndRank(items, 'hex paq');
      expect(matches, hasLength(2));
      expect(matches.map((item) => item.barcode), contains('bolt-99'));
      expect(matches.map((item) => item.barcode), contains('7453078513034'));
    });

    test('ignores accents in query and item text', () {
      final matches = InventorySearchMatcher.filterAndRank(items, 'tornillo');
      expect(matches, hasLength(1));
      expect(matches.first.barcode, '7453078513034');

      final accentQuery = InventorySearchMatcher.filterAndRank(
        items,
        'torníllo hexagonal',
      );
      expect(accentQuery, hasLength(1));
    });

    test('fuzzy matches typos in item names', () {
      final matches = InventorySearchMatcher.filterAndRank(items, 'bult');
      expect(matches, hasLength(1));
      expect(matches.first.name, 'Hex bolt pack');
    });

    test('matches compact barcode fragments', () {
      final matches = InventorySearchMatcher.filterAndRank(
        items,
        '7453078513034',
      );
      expect(matches.first.barcode, '7453078513034');

      final partial = InventorySearchMatcher.filterAndRank(items, '7453078');
      expect(partial.first.barcode, '7453078513034');
    });

    test('matches quantity numbers', () {
      final matches = InventorySearchMatcher.filterAndRank(items, '12');
      expect(matches, hasLength(1));
      expect(matches.first.barcode, 'nut-44');
    });

    test('ranks exact name matches ahead of fuzzy matches', () {
      final matches = InventorySearchMatcher.filterAndRank(items, 'bolt');
      expect(matches.first.barcode, 'bolt-99');
    });

    test('normalizeForSearch folds accents and lowercases', () {
      expect(
        InventorySearchMatcher.normalizeForSearch('  TORNÍLLO  '),
        'tornillo',
      );
    });

    test('levenshteinDistance handles insertions', () {
      expect(InventorySearchMatcher.levenshteinDistance('bolt', 'blt'), 1);
    });
  });
}
