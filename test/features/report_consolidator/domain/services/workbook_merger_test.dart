import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/services/workbook_merger.dart';

void main() {
  const merger = WorkbookMerger();

  group('WorkbookMerger', () {
    test('empty input returns no rows and no file results', () {
      final outcome = merger.merge(const <WorkbookFileInput>[]);

      expect(outcome.rows, isEmpty);
      expect(outcome.fileResults, isEmpty);
    });

    test('one good file keeps header and data rows', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'report_a.xlsx',
          rows: [
            ['Name', 'Amount'],
            ['Alpha', '10'],
          ],
        ),
      ]);

      expect(outcome.successCount, 1);
      expect(outcome.failureCount, 0);
      expect(outcome.rows, [
        ['Name', 'Amount'],
        ['Alpha', '10'],
        ['Row count', '1'],
      ]);
      expect(
        outcome.fileResults.first.parseStatus,
        SpreadsheetParseStatus.success,
      );
    });

    test('matching headers skip duplicate header rows from later files', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'report_a.xlsx',
          rows: [
            ['Name', 'Amount'],
            ['Alpha', '10'],
          ],
        ),
        const WorkbookFileInput(
          fileName: 'report_b.xlsx',
          rows: [
            ['Name', 'Amount'],
            ['Beta', '20'],
          ],
        ),
      ]);

      expect(outcome.successCount, 2);
      expect(outcome.rows, [
        ['Name', 'Amount'],
        ['Alpha', '10'],
        ['Beta', '20'],
        ['Row count', '2'],
      ]);
    });

    test('empty sheet rows are recorded as failed file results', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'empty.xlsx',
          rows: <List<String?>>[],
        ),
      ]);

      expect(outcome.successCount, 0);
      expect(outcome.failureCount, 1);
      expect(outcome.rows, isEmpty);
      expect(
        outcome.fileResults.single.parseStatus,
        SpreadsheetParseStatus.failed,
      );
    });

    test('footer counts only data rows when header-only file succeeds', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'header_only.xlsx',
          rows: [
            ['Name', 'Amount'],
          ],
        ),
      ]);

      expect(outcome.successCount, 1);
      expect(outcome.rows, [
        ['Name', 'Amount'],
        ['Row count', '0'],
      ]);
    });
  });
}
