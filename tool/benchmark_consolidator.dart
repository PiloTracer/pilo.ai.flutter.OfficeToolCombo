// NFR10 profile: merge a 100-file folder and report wall time.
// Uses the local source directly so the script stays pure-Dart
// (`dart run` — the repository pulls in Flutter plugin imports).
// Usage: dart run tool/benchmark_consolidator.dart
// Benchmark results are reported via stdout (dart:io).
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_local_source.dart';

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('nfr10_corpus_');
  final outDir = await Directory.systemTemp.createTemp('nfr10_out_');
  try {
    // 100 workbooks x 25 data rows, 6 columns (branch-report shape).
    for (var i = 0; i < 100; i++) {
      final excel = Excel.createExcel();
      final sheet = excel.sheets.values.first;
      sheet.removeRow(0);
      final header = ['Date', 'Branch', 'Product', 'Qty', 'Unit', 'Amount'];
      for (var c = 0; c < header.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .value = TextCellValue(
          header[c],
        );
      }
      for (var r = 1; r <= 25; r++) {
        final row = [
          TextCellValue('2026-08-01'),
          TextCellValue('Branch ${i % 5}'),
          TextCellValue('SKU-$i-$r'),
          IntCellValue(r % 17 + 1),
          const DoubleCellValue(3.5),
          DoubleCellValue((r % 17 + 1) * 3.5),
        ];
        for (var c = 0; c < row.length; c++) {
          sheet
                  .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
                  .value =
              row[c];
        }
      }
      await File(
        '${dir.path}${Platform.pathSeparator}report_$i.xlsx',
      ).writeAsBytes(excel.encode()!);
    }

    const source = ConsolidatorLocalSource();
    final stopwatch = Stopwatch()..start();
    final data = await source.consolidate(folderPath: dir.path);
    final outputPath = await source.writeWorkbook(
      outputFolderPath: outDir.path,
      rows: data.rows,
    );
    stopwatch.stop();

    stdout.writeln(
      'Files merged: ${data.successCount} ok / ${data.failureCount} failed '
      '· rows: ${data.rows.length} · output: ${outputPath.split(Platform.pathSeparator).last}',
    );
    stdout.writeln('Elapsed: ${stopwatch.elapsedMilliseconds} ms for 100 files');
    stdout.writeln(
      'NFR10 check (100-file profile completes, no failure): '
      '${data.failureCount == 0 ? 'PASS' : 'FAIL'}',
    );
  } finally {
    await dir.delete(recursive: true);
    await outDir.delete(recursive: true);
  }
}
