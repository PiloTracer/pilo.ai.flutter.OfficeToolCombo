import 'dart:io';

import 'package:excel/excel.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';

/// Builds minimal `.xlsx` fixtures for repository tests.
class ConsolidatorTestFixtures {
  static Future<File> writeWorkbook({
    required Directory directory,
    required String fileName,
    required List<List<String>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    sheet.removeRow(0);

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          row[colIndex],
        );
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode workbook $fileName');
    }

    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File> writeBrokenFile({
    required Directory directory,
    required String fileName,
  }) async {
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(<int>[0, 1, 2, 3, 4]);
    return file;
  }
}

SpreadsheetFileResult failedResult(String fileName, String message) {
  return SpreadsheetFileResult(
    fileName: fileName,
    parseStatus: SpreadsheetParseStatus.failed,
    errorMessage: message,
  );
}
