import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';

void main() {
  test('WorkbookBatch defaults files to empty list', () {
    final batch = WorkbookBatch(
      id: '1',
      sourceFolderPath: '/tmp/reports',
      status: WorkbookBatchStatus.pending,
      startedAt: DateTime.utc(2026, 8, 2),
    );

    expect(batch.files, isEmpty);
    expect(batch.outputPath, isNull);
  });

  test('SpreadsheetFileResult stores failure details', () {
    const result = SpreadsheetFileResult(
      fileName: 'broken.xlsx',
      parseStatus: SpreadsheetParseStatus.failed,
      errorMessage: 'Invalid format',
    );

    expect(result.fileName, 'broken.xlsx');
    expect(result.errorMessage, 'Invalid format');
  });
}
