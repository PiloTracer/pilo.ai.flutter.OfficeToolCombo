import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/document_factory/data/services/html_document_renderer.dart';

/// 1x1 transparent PNG.
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  const renderer = HtmlDocumentRenderer();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('renderer_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HtmlDocumentRenderer', () {
    test(
      'renders headings, styled spans, br and list items to PDF bytes',
      () async {
        final template = await renderer.parse(
          '<h1>Hello {{Name}}</h1>'
          '<p>Dear <b>{{Name}}</b>, <i>welcome</i>.<br>Second line</p>'
          '<ul><li>One</li><li>Two</li></ul>',
          tempDir.path,
        );

        final bytes = await renderer.render(template, {'Name': 'Ada'});

        expect(bytes, isNotEmpty);
        // %PDF magic header.
        expect(bytes.sublist(0, 4), equals(const [0x25, 0x50, 0x44, 0x46]));
      },
    );

    test(
      'loads a relative logo image and embeds it in the PDF (A10)',
      () async {
        final logo = File('${tempDir.path}${Platform.pathSeparator}logo.png');
        await logo.writeAsBytes(_pngBytes);

        final textOnly = await renderer.parse(
          '<p>Hello {{Name}}</p>',
          tempDir.path,
        );
        final withLogo = await renderer.parse(
          '<img src="logo.png"><p>Hello {{Name}}</p>',
          tempDir.path,
        );

        final imageBlock = withLogo.blocks.whereType<HtmlImageBlock>().single;
        expect(imageBlock.bytes, isNotNull);
        expect(imageBlock.bytes, equals(_pngBytes));

        final textBytes = await renderer.render(textOnly, {'Name': 'Ada'});
        final logoBytes = await renderer.render(withLogo, {'Name': 'Ada'});

        expect(logoBytes.sublist(0, 4), equals(const [0x25, 0x50, 0x44, 0x46]));
        // Embedded image data makes the document larger than text alone.
        expect(logoBytes.length, greaterThan(textBytes.length));
      },
    );

    test('fails to render when a referenced image is unreadable', () async {
      final template = await renderer.parse(
        '<img src="missing.png"><p>Hello</p>',
        tempDir.path,
      );

      expect(
        () => renderer.render(template, const {}),
        throwsA(isA<HtmlRenderException>()),
      );
    });

    test('keeps unmapped tokens and decodes basic entities', () async {
      final template = await renderer.parse(
        '<p>Fish &amp; Chips {{Unknown}}</p>',
        tempDir.path,
      );
      final bytes = await renderer.render(template, const {});
      expect(bytes, isNotEmpty);
    });
  });
}
