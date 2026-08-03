import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/services/workbook_merger.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/services/workbook_numeric_parser.dart';

void main() {
  const merger = WorkbookMerger();

  group('WorkbookNumericParser', () {
    test('parses currency, parentheses, and CR or DR suffixes', () {
      expect(WorkbookNumericParser.parseAmount(r'$48.00'), 48);
      expect(WorkbookNumericParser.parseAmount('(20.00)'), -20);
      expect(WorkbookNumericParser.parseAmount('150 CR'), -150);
      expect(WorkbookNumericParser.parseAmount('75 DR'), 75);
    });

    test('applies row-level DR/CR hint to amount cells', () {
      expect(
        WorkbookNumericParser.parseForTotal(
          raw: '100',
          columnKind: ColumnTotalKind.amount,
          rowDrCrHint: 'CR',
        ),
        -100,
      );
      expect(
        WorkbookNumericParser.parseForTotal(
          raw: '100',
          columnKind: ColumnTotalKind.amount,
          rowDrCrHint: 'DR',
        ),
        100,
      );
    });
  });

  group('WorkbookMerger', () {
    test('empty input returns no rows and no file results', () {
      final outcome = merger.merge(const <WorkbookFileInput>[]);

      expect(outcome.rows, isEmpty);
      expect(outcome.fileResults, isEmpty);
    });

    test('one good file keeps header, data rows, and footer totals', () {
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
      expect(outcome.rows.last, ['Totals', '10.00']);
    });

    test('simple six-column branch layout totals quantity and amount', () {
      const header = ['Date', 'Branch', 'SKU', 'Product', 'Quantity', 'Amount'];

      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'branch_norte.xlsx',
          rows: [
            header,
            [
              '2026-07-01',
              'Norte',
              'SKU-100',
              'Coffee beans 1kg',
              '12',
              '48.00',
            ],
            ['2026-07-02', 'Norte', 'SKU-210', 'Paper A4 ream', '8', '32.00'],
          ],
        ),
        const WorkbookFileInput(
          fileName: 'branch_sur.xlsx',
          rows: [
            header,
            ['2026-07-01', 'Sur', 'SKU-100', 'Coffee beans 1kg', '6', '24.00'],
          ],
        ),
      ]);

      expect(outcome.rows.last, ['Totals', null, null, null, '26', '104.00']);
    });

    test(
      'header mismatch foreign header row does not block numeric totals',
      () {
        const header = [
          'Date',
          'Branch',
          'SKU',
          'Product',
          'Quantity',
          'Amount',
        ];

        final outcome = merger.merge([
          const WorkbookFileInput(
            fileName: 'branch_norte.xlsx',
            rows: [
              header,
              ['2026-07-01', 'Norte', 'SKU-100', 'Coffee', '12', '48.00'],
            ],
          ),
          const WorkbookFileInput(
            fileName: 'header_mismatch.xlsx',
            rows: [
              [
                'Fecha',
                'Sucursal',
                'Codigo',
                'Descripcion',
                'Cantidad',
                'Total',
              ],
              ['2026-07-01', 'Extra', 'X-1', 'Odd format row', '1', '9.99'],
            ],
          ),
        ]);

        expect(outcome.rows.last, ['Totals', null, null, null, '13', '57.99']);
      },
    );

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

      expect(outcome.rows.last, ['Totals', '30.00']);
    });

    test('case-variant or padded headers are still treated as duplicates', () {
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
            [' NAME ', 'amount'],
            ['Beta', '20'],
          ],
        ),
      ]);

      // The variant header must not land in the output as a data row.
      expect(
        outcome.rows.where((row) => row.first == ' NAME ').length,
        isZero,
      );
      expect(outcome.rows.last, ['Totals', '30.00']);
    });

    test('totals row sums every numeric column in wide sheets', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'branch_a.xlsx',
          rows: [
            ['Date', 'Branch', 'Quantity', 'Amount'],
            ['2026-07-01', 'North', '12', '48.00'],
            ['2026-07-02', 'North', '8', '32.00'],
          ],
        ),
        const WorkbookFileInput(
          fileName: 'branch_b.xlsx',
          rows: [
            ['Date', 'Branch', 'Quantity', 'Amount'],
            ['2026-07-01', 'South', '6', '24.00'],
          ],
        ),
      ]);

      expect(outcome.rows.last, ['Totals', null, '26', '104.00']);
    });

    test('credit and debit columns total as positive magnitudes', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'ledger.xlsx',
          rows: [
            ['Account', 'Debit', 'Credit'],
            ['Sales', '100.00', ''],
            ['Refund', '', '20.00'],
            ['Fee', '5.00', ''],
          ],
        ),
      ]);

      expect(outcome.rows.last, ['Totals', '105.00', '20.00']);
    });

    test('DR/CR type column adjusts amount totals', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'ledger.xlsx',
          rows: [
            ['Account', 'Type', 'Amount'],
            ['Sales', 'DR', '100'],
            ['Refund', 'CR', '20'],
            ['Fee', 'DR', '5'],
          ],
        ),
      ]);

      expect(outcome.rows.last, ['Totals', null, '85.00']);
    });

    test('signed amounts and credits reduce net amount total', () {
      final outcome = merger.merge([
        const WorkbookFileInput(
          fileName: 'returns.xlsx',
          rows: [
            ['Branch', 'Quantity', 'Line Total'],
            ['North', '10', '100.00'],
            ['North', '-2', '-20.00'],
          ],
        ),
      ]);

      expect(outcome.rows.last, ['Totals', '8', '80.00']);
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

      expect(outcome.rows, [
        ['Name', 'Amount'],
        ['Row count', '0'],
      ]);
    });
  });
}
