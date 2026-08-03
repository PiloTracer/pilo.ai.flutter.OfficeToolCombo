import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_local_source.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('consolidator_source_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeWorkbookFile(
    String name,
    List<List<CellValue?>> rows,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    sheet.removeRow(0);
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final value = rows[r][c];
        if (value != null) {
          sheet
                  .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
                  .value =
              value;
        }
      }
    }
    final bytes = excel.encode()!;
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  group('ConsolidatorLocalSource decode', () {
    test('decodes typed cells into clean strings', () async {
      await writeWorkbookFile('typed.xlsx', [
        [TextCellValue('Sku'), TextCellValue('Qty'), TextCellValue('When')],
        [
          TextCellValue('A-1'),
          const IntCellValue(3),
          const DateCellValue(year: 2026, month: 8, day: 2),
        ],
        [
          TextCellValue('B-2'),
          const DoubleCellValue(2.5),
          const DateTimeCellValue(
            year: 2026,
            month: 8,
            day: 2,
            hour: 9,
            minute: 30,
          ),
        ],
        [TextCellValue('C-3'), const BoolCellValue(true), null],
      ]);

      const source = ConsolidatorLocalSource();
      final data = await source.consolidate(folderPath: tempDir.path);

      // Row 0 is the header; footers are the last two rows.
      expect(data.rows[0], ['Sku', 'Qty', 'When']);
      expect(data.rows[1], ['A-1', '3', '2026-08-02']);
      expect(data.rows[2], ['B-2', '2.5', '2026-08-02T09:30:00']);
      expect(data.rows[3], ['C-3', 'TRUE', null]);
    });
  });

  group('ConsolidatorLocalSource write', () {
    test(
      'writes plain numbers as numeric cells, keeps identifiers as text',
      () async {
        const source = ConsolidatorLocalSource();
        final outputPath = await source.writeWorkbook(
          outputFolderPath: tempDir.path,
          rows: [
            ['Sku', 'Qty', 'Price', 'Note'],
            ['007', '42', '19.99', '1e5'],
            ['Totals', '42', '19.99', null],
          ],
        );

        final decoded = Excel.decodeBytes(await File(outputPath).readAsBytes());
        final sheet = decoded.tables.values.first;

        CellValue? cellAt(int row, int col) => sheet.rows[row][col]?.value;

        expect(cellAt(1, 0), isA<TextCellValue>()); // '007' stays text
        expect((cellAt(1, 0) as TextCellValue).toString(), '007');
        expect(cellAt(1, 1), isA<IntCellValue>());
        expect((cellAt(1, 1) as IntCellValue).value, 42);
        expect(cellAt(1, 2), isA<DoubleCellValue>());
        expect((cellAt(1, 2) as DoubleCellValue).value, 19.99);
        expect(cellAt(1, 3), isA<TextCellValue>()); // '1e5' stays text
        expect(cellAt(2, 1), isA<IntCellValue>()); // totals row numeric
      },
    );
  });
}
