/// Discovers `{{Placeholder}}` tokens in an HTML template.
///
/// Tokens inside `<img src="...">` attributes are ignored — a `{{...}}`
/// sequence there is part of a file path, not a data placeholder.
abstract final class PlaceholderParser {
  static final RegExp tokenPattern = RegExp(r'\{\{\s*([A-Za-z0-9_ ]+)\s*\}\}');
  static final RegExp _imgTag = RegExp(r'<img\b[^>]*>', caseSensitive: false);
  static final RegExp _srcAttribute = RegExp(
    r'''src\s*=\s*("[^"]*"|'[^']*')''',
    caseSensitive: false,
  );

  /// Ordered, de-duplicated placeholder names found in [templateHtml].
  static List<String> discover(String templateHtml) {
    final searchable = stripImageSources(templateHtml);
    final seen = <String>{};
    final placeholders = <String>[];
    for (final match in tokenPattern.allMatches(searchable)) {
      final name = match.group(1)!.trim();
      if (name.isNotEmpty && seen.add(name)) {
        placeholders.add(name);
      }
    }
    return placeholders;
  }

  /// Replaces `{{token}}` occurrences with row [values], leaving `<img>`
  /// `src` attributes untouched.
  static String substitute(String templateHtml, Map<String, String> values) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in _imgTag.allMatches(templateHtml)) {
      buffer.write(
        substituteTokens(templateHtml.substring(cursor, match.start), values),
      );
      buffer.write(match.group(0));
      cursor = match.end;
    }
    buffer.write(substituteTokens(templateHtml.substring(cursor), values));
    return buffer.toString();
  }

  /// Replaces `{{token}}` occurrences in a plain-text fragment.
  static String substituteTokens(String text, Map<String, String> values) {
    return text.replaceAllMapped(tokenPattern, (match) {
      final name = match.group(1)!.trim();
      return values[name] ?? match.group(0)!;
    });
  }

  /// Blanks out `src` attribute values inside `<img>` tags so token
  /// discovery never treats a path segment as a placeholder.
  static String stripImageSources(String templateHtml) {
    return templateHtml.replaceAllMapped(_imgTag, (match) {
      return match.group(0)!.replaceAll(_srcAttribute, 'src=""');
    });
  }
}
