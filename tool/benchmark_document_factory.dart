import 'dart:io';

import 'package:excel/excel.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/document_factory_local_source.dart';

/// F3-T5 / NFR12 — throughput benchmark.
///
/// Generates a 100-row corpus plus a simple template in a temp dir, runs the
/// batch worker directly (no UI), and prints PDFs/min. Target: ≥ 50/min.
Future<void> main() async {
  const rowCount = 100;

  final tempDir = await Directory.systemTemp.createTemp('docfactory_bench_');
  final outputDir = await Directory(
    '${tempDir.path}${Platform.pathSeparator}out',
  ).create();

  try {
    final templateFile = File(
      '${tempDir.path}${Platform.pathSeparator}template.html',
    );
    await templateFile.writeAsString(
      '<h1>Statement for {{Name}}</h1>'
      '<p>Amount due: <b>{{Amount}}</b></p>'
      '<p>City: {{City}}</p>'
      '<p>Due date: {{DueDate}}</p>'
      '<p>Reference: {{Reference}}</p>',
    );

    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    sheet.removeRow(0);
    const headers = ['Name', 'Amount', 'City', 'DueDate', 'Reference'];
    for (var col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(
        headers[col],
      );
    }
    for (var row = 0; row < rowCount; row++) {
      final values = [
        'Customer $row',
        '${100 + row}.50',
        'City ${row % 20}',
        '2026-09-${(row % 28) + 1}',
        'REF-${1000 + row}',
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
            )
            .value = TextCellValue(
          values[col],
        );
      }
    }
    final dataFile = File('${tempDir.path}${Platform.pathSeparator}data.xlsx');
    await dataFile.writeAsBytes(excel.encode()!);

    final stopwatch = Stopwatch()..start();
    final response = await runDocumentBatchIsolate(
      DocumentBatchRequest(
        templatePath: templateFile.path,
        dataSheetPath: dataFile.path,
        outputDirPath: outputDir.path,
        mapping: {for (final header in headers) header: header},
      ),
      null,
    );
    stopwatch.stop();

    final pdfsOnDisk = outputDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.pdf'))
        .length;

    final minutes = stopwatch.elapsedMilliseconds / 60000;
    final perMinute = response.successCount / minutes;

    stdout.writeln(
      'Rows: $rowCount · succeeded: ${response.successCount} · '
      'failed: ${response.failedCount} · skipped: ${response.skippedCount}',
    );
    stdout.writeln('PDFs on disk: $pdfsOnDisk');
    stdout.writeln('Elapsed: ${stopwatch.elapsedMilliseconds} ms');
    stdout.writeln('Throughput: ${perMinute.toStringAsFixed(1)} PDFs/min');
    stdout.writeln(
      perMinute >= 50
          ? 'NFR12 target (>= 50/min): PASS'
          : 'NFR12 target (>= 50/min): FAIL',
    );
  } finally {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  }
}
