import 'dart:io';
import 'dart:typed_data';

import 'package:office_tool_combo/features/document_factory/domain/services/placeholder_parser.dart';
import 'package:pdf/widgets.dart' as pw;

/// One inline text run inside a block element.
class HtmlSpan {
  const HtmlSpan(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;
}

/// A parsed block of the constrained template subset.
sealed class HtmlBlock {
  const HtmlBlock();
}

/// Heading (level 1–3), paragraph (level 0), or list item.
final class HtmlTextBlock extends HtmlBlock {
  const HtmlTextBlock({
    required this.spans,
    this.headingLevel = 0,
    this.isListItem = false,
  });

  final List<HtmlSpan> spans;
  final int headingLevel;
  final bool isListItem;
}

/// `<img src="...">` — [bytes] are loaded eagerly at parse time so the
/// per-row render loop never touches disk (SPEC R7, A10).
final class HtmlImageBlock extends HtmlBlock {
  const HtmlImageBlock({required this.sourcePath, this.bytes});

  final String sourcePath;
  final Uint8List? bytes;
}

/// Template parsed once per batch and reused for every row.
class ParsedHtmlTemplate {
  const ParsedHtmlTemplate(this.blocks);

  final List<HtmlBlock> blocks;
}

/// Thrown when a single document cannot be rendered (e.g. missing image).
class HtmlRenderException implements Exception {
  HtmlRenderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Renders the constrained HTML template subset (h1–h3, p, b/strong, i/em,
/// br, ul/li, img) into PDF bytes using package:pdf.
class HtmlDocumentRenderer {
  const HtmlDocumentRenderer();

  static final RegExp _anyTag = RegExp(r'<[^>]+>', caseSensitive: false);
  static final RegExp _srcAttribute = RegExp(
    r'''src\s*=\s*"([^"]*)"|src\s*=\s*'([^']*)' ''',
    caseSensitive: false,
  );

  /// Parses [html] into blocks and loads referenced image bytes.
  ///
  /// [templateDirPath] resolves relative `<img src>` paths (SPEC A10).
  Future<ParsedHtmlTemplate> parse(String html, String templateDirPath) async {
    final blocks = <HtmlBlock>[];

    var headingLevel = 0;
    var isListItem = false;
    var bold = false;
    var italic = false;
    final spans = <HtmlSpan>[];

    void flushSpans() {
      final hasText = spans.any((span) => span.text.trim().isNotEmpty);
      if (hasText) {
        blocks.add(
          HtmlTextBlock(
            spans: List<HtmlSpan>.unmodifiable(spans),
            headingLevel: headingLevel,
            isListItem: isListItem,
          ),
        );
      }
      spans.clear();
    }

    void appendText(String raw) {
      if (raw.isEmpty) {
        return;
      }
      final decoded = _decodeEntities(raw);
      if (decoded.isEmpty) {
        return;
      }
      spans.add(HtmlSpan(decoded, bold: bold, italic: italic));
    }

    var cursor = 0;
    for (final match in _anyTag.allMatches(html)) {
      appendText(html.substring(cursor, match.start));
      cursor = match.end;

      final tag = match.group(0)!;
      final parsed = _parseTag(tag);
      if (parsed == null) {
        continue; // Unknown tag — stripped, text content kept.
      }
      final name = parsed.$1;
      final isClose = parsed.$2;

      switch (name) {
        case 'h1' || 'h2' || 'h3':
          if (isClose) {
            flushSpans();
            headingLevel = 0;
          } else {
            flushSpans();
            headingLevel = int.parse(name.substring(1));
          }
        case 'p':
          flushSpans();
          if (isClose) {
            headingLevel = 0;
          }
        case 'ul' || 'ol':
          flushSpans();
        case 'li':
          if (isClose) {
            flushSpans();
            isListItem = false;
          } else {
            flushSpans();
            isListItem = true;
          }
        case 'b' || 'strong':
          bold = !isClose;
        case 'i' || 'em':
          italic = !isClose;
        case 'br':
          spans.add(const HtmlSpan('\n'));
        case 'img':
          flushSpans();
          final src = _imageSource(tag);
          if (src != null && src.isNotEmpty) {
            final resolved = _resolvePath(src, templateDirPath);
            blocks.add(
              HtmlImageBlock(
                sourcePath: resolved,
                bytes: await _read(resolved),
              ),
            );
          }
        default:
          break; // Formatting/structural tags we ignore (html, body, div…).
      }
    }
    appendText(html.substring(cursor));
    flushSpans();

    return ParsedHtmlTemplate(List<HtmlBlock>.unmodifiable(blocks));
  }

  /// Renders one personalized PDF for [values] (placeholder → cell text).
  Future<Uint8List> render(
    ParsedHtmlTemplate template,
    Map<String, String> values,
  ) {
    final widgets = <pw.Widget>[];
    for (final block in template.blocks) {
      switch (block) {
        case HtmlTextBlock(
          :final spans,
          :final headingLevel,
          :final isListItem,
        ):
          final substituted = spans
              .map(
                (span) => HtmlSpan(
                  PlaceholderParser.substituteTokens(span.text, values),
                  bold: span.bold,
                  italic: span.italic,
                ),
              )
              .toList(growable: false);
          widgets.add(_textWidget(substituted, headingLevel, isListItem));
        case HtmlImageBlock(:final bytes):
          if (bytes == null) {
            throw HtmlRenderException('Template image could not be loaded');
          }
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Image(
                pw.MemoryImage(bytes),
                fit: pw.BoxFit.contain,
                width: 220,
                height: 140,
              ),
            ),
          );
      }
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(48),
        build: (context) => widgets,
      ),
    );
    return document.save();
  }

  pw.Widget _textWidget(
    List<HtmlSpan> spans,
    int headingLevel,
    bool isListItem,
  ) {
    final baseSize = switch (headingLevel) {
      1 => 22.0,
      2 => 17.0,
      3 => 14.0,
      _ => 11.0,
    };
    final baseStyle = pw.TextStyle(
      fontSize: baseSize,
      fontWeight: headingLevel > 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    final richText = pw.RichText(
      text: pw.TextSpan(
        style: baseStyle,
        children: spans
            .map(
              (span) => pw.TextSpan(
                text: span.text,
                style: baseStyle.copyWith(
                  fontWeight: span.bold || headingLevel > 0
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  fontStyle: span.italic
                      ? pw.FontStyle.italic
                      : pw.FontStyle.normal,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );

    final padded = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: richText,
    );

    if (!isListItem) {
      return padded;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: baseStyle),
          pw.Expanded(child: padded),
        ],
      ),
    );
  }

  /// Returns (tagName, isClosingTag) for recognized tags, else null.
  (String, bool)? _parseTag(String tag) {
    final inner = tag.substring(1, tag.length - 1).trim();
    if (inner.isEmpty) {
      return null;
    }
    final isClose = inner.startsWith('/');
    final body = isClose ? inner.substring(1).trim() : inner;
    final spaceIndex = body.indexOf(RegExp(r'\s'));
    final name = (spaceIndex == -1 ? body : body.substring(0, spaceIndex))
        .toLowerCase();
    const recognized = {
      'h1',
      'h2',
      'h3',
      'p',
      'ul',
      'ol',
      'li',
      'b',
      'strong',
      'i',
      'em',
      'br',
      'img',
    };
    if (!recognized.contains(name)) {
      return null;
    }
    return (name, isClose);
  }

  String? _imageSource(String imgTag) {
    final match = _srcAttribute.firstMatch(imgTag);
    if (match == null) {
      return null;
    }
    return match.group(1) ?? match.group(2);
  }

  String _resolvePath(String src, String templateDirPath) {
    if (src.startsWith('/') ||
        src.contains('://') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(src)) {
      return src;
    }
    return '$templateDirPath${Platform.pathSeparator}$src';
  }

  Future<Uint8List?> _read(String path) async {
    try {
      return await File(path).readAsBytes();
    } on Object {
      return null;
    }
  }

  String _decodeEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');
  }
}
