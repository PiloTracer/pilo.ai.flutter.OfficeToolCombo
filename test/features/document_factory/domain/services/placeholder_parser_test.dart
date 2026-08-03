import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/document_factory/domain/services/placeholder_parser.dart';

void main() {
  group('PlaceholderParser.discover', () {
    test('finds simple tokens in order', () {
      const html = '<h1>Hello {{Name}}</h1><p>{{City}}</p>';
      expect(PlaceholderParser.discover(html), ['Name', 'City']);
    });

    test('accepts whitespace variants and trims names', () {
      const html =
          '<p>{{ Name }}</p><p>{{  Customer Name }}</p><p>{{Total_2}}</p>';
      expect(PlaceholderParser.discover(html), [
        'Name',
        'Customer Name',
        'Total_2',
      ]);
    });

    test('de-duplicates repeated tokens keeping first occurrence order', () {
      const html = '<p>{{Name}} and {{City}} and {{Name}}</p>';
      expect(PlaceholderParser.discover(html), ['Name', 'City']);
    });

    test('ignores tokens inside img src attributes', () {
      const html =
          '<img src="{{Logo}}.png"><p>{{Name}}</p>'
          "<img src='images/{{ theme }}/logo.png'>";
      expect(PlaceholderParser.discover(html), ['Name']);
    });

    test('returns empty list when no tokens present', () {
      expect(PlaceholderParser.discover('<p>No tokens here</p>'), isEmpty);
    });

    test('ignores non-matching brace sequences', () {
      const html = '<p>{{ }}</p><p>{{!Name}}</p><p>{Name}</p>';
      expect(PlaceholderParser.discover(html), isEmpty);
    });
  });

  group('PlaceholderParser.substitute', () {
    test('replaces tokens with values', () {
      const html = '<h1>Hello {{Name}}</h1>';
      expect(
        PlaceholderParser.substitute(html, {'Name': 'Ada'}),
        '<h1>Hello Ada</h1>',
      );
    });

    test('leaves img src attributes untouched', () {
      const html = '<img src="{{Logo}}.png"><p>{{Logo}}</p>';
      expect(
        PlaceholderParser.substitute(html, {'Logo': 'acme'}),
        '<img src="{{Logo}}.png"><p>acme</p>',
      );
    });

    test('keeps unmapped tokens as-is', () {
      const html = '<p>{{Unknown}}</p>';
      expect(
        PlaceholderParser.substitute(html, const {}),
        '<p>{{Unknown}}</p>',
      );
    });
  });
}
