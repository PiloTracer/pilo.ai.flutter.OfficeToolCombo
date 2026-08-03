import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/price_monitor/domain/services/price_parser.dart';

void main() {
  const parser = PriceParser();

  group('PriceParser — JSON bodies', () {
    test('flat price key', () {
      expect(parser.parse('{"price": 12.99}'), Decimal.parse('12.99'));
    });

    test('nested price key as string', () {
      expect(
        parser.parse('{"data": {"product": {"price": "19.95"}}}'),
        Decimal.parse('19.95'),
      );
    });

    test('amount and value keys fall back in priority order', () {
      expect(parser.parse('{"amount": 5}'), Decimal.parse('5'));
      expect(parser.parse('{"value": 7.5}'), Decimal.parse('7.5'));
      // price wins over value/amount regardless of document order.
      expect(parser.parse('{"value": 1, "price": 2}'), Decimal.parse('2'));
    });

    test('price inside an array of offers', () {
      expect(
        parser.parse('{"offers": [{"name": "a"}, {"amount": 42.5}]}'),
        Decimal.parse('42.5'),
      );
    });

    test('key match is case-insensitive', () {
      expect(parser.parse('{"Price": 3.5}'), Decimal.parse('3.5'));
    });

    test('JSON without a price key yields no price', () {
      expect(parser.parse('{"name": "widget"}'), isNull);
    });
  });

  group('PriceParser — HTML and text fallback', () {
    test('currency with thousands separator', () {
      expect(
        parser.parse('<span class="price">\$1,234.56</span>'),
        Decimal.parse('1234.56'),
      );
    });

    test('plain decimal in text', () {
      expect(
        parser.parse('Now only 12.99 USD while stocks last'),
        Decimal.parse('12.99'),
      );
    });

    test('currency symbol with integer amount', () {
      expect(parser.parse('Price: £7 today'), Decimal.parse('7'));
    });

    test('first currency-looking number wins', () {
      expect(
        parser.parse('<b>\$9.99</b> was <i>\$19.99</i>'),
        Decimal.parse('9.99'),
      );
    });

    test('garbage yields no price', () {
      expect(parser.parse('no prices on this page'), isNull);
      expect(parser.parse(''), isNull);
      // A bare integer with no symbol or decimals is not currency-looking.
      expect(parser.parse('In stock: 5 items'), isNull);
    });
  });
}
