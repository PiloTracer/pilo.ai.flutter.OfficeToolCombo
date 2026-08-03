import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/services/workbook_numeric_parser.dart';

/// Pure merge rules for spreadsheet rows (no IO, no Flutter).
class WorkbookMerger {
  const WorkbookMerger();

  /// Merges per-file sheet rows into one output sheet.
  ///
  /// The first non-empty file keeps its header row. Subsequent files skip their
  /// first row when it matches the established header.
  ///
  /// When the merge produces at least one row, footer rows are appended:
  /// 1. `Row count` | data-row count (header excluded)
  /// 2. `Totals` | sums for numeric columns (amount, count, debit, credit)
  WorkbookMergeOutcome merge(List<WorkbookFileInput> inputs) {
    if (inputs.isEmpty) {
      return const WorkbookMergeOutcome(
        rows: <List<String?>>[],
        fileResults: <SpreadsheetFileResult>[],
      );
    }

    final mergedRows = <List<String?>>[];
    final fileResults = <SpreadsheetFileResult>[];
    List<String?>? header;

    for (final input in inputs) {
      if (input.rows.isEmpty) {
        fileResults.add(
          SpreadsheetFileResult(
            fileName: input.fileName,
            parseStatus: SpreadsheetParseStatus.failed,
            errorMessage: 'Workbook has no rows on the first sheet',
          ),
        );
        continue;
      }

      final rowsToAppend = <List<String?>>[];
      if (header == null) {
        header = List<String?>.from(input.rows.first);
        mergedRows.add(header);
        rowsToAppend.addAll(input.rows.skip(1));
      } else if (_rowsEqual(header, input.rows.first)) {
        rowsToAppend.addAll(input.rows.skip(1));
      } else {
        rowsToAppend.addAll(input.rows);
      }

      mergedRows.addAll(rowsToAppend);
      fileResults.add(
        SpreadsheetFileResult(
          fileName: input.fileName,
          parseStatus: SpreadsheetParseStatus.success,
        ),
      );
    }

    if (mergedRows.isNotEmpty) {
      // Width covers the widest row, not just the header, so columns that
      // only exist in data rows still get totals.
      var width = 0;
      for (final row in mergedRows) {
        if (row.length > width) {
          width = row.length;
        }
      }
      final dataRows = header == null
          ? List<List<String?>>.from(mergedRows)
          : mergedRows.skip(1).toList(growable: false);

      mergedRows.add(
        _rowCountFooter(dataRowCount: dataRows.length, width: width),
      );
      if (dataRows.isNotEmpty) {
        mergedRows.add(
          _columnTotalsFooter(header: header, dataRows: dataRows, width: width),
        );
      }
    }

    return WorkbookMergeOutcome(rows: mergedRows, fileResults: fileResults);
  }
}

List<String?> _rowCountFooter({required int dataRowCount, required int width}) {
  final footer = List<String?>.filled(width < 2 ? 2 : width, null);
  footer[0] = 'Row count';
  footer[1] = '$dataRowCount';
  return footer;
}

List<String?> _columnTotalsFooter({
  required List<String?>? header,
  required List<List<String?>> dataRows,
  required int width,
}) {
  final footer = List<String?>.filled(width < 1 ? 1 : width, null);
  footer[0] = 'Totals';

  final drCrColumnIndex = WorkbookColumnClassifier.findDrCrColumnIndex(header);
  final rowsForTotals = dataRows
      .where(
        (row) => !WorkbookColumnClassifier.isDuplicateHeaderRow(row, header),
      )
      .toList(growable: false);

  for (var columnIndex = 1; columnIndex < width; columnIndex++) {
    final kind = WorkbookColumnClassifier.classify(
      header: header,
      dataRows: rowsForTotals,
      columnIndex: columnIndex,
    );

    if (kind == ColumnTotalKind.notTotalizable) {
      continue;
    }

    final total = _sumColumn(
      dataRows: rowsForTotals,
      columnIndex: columnIndex,
      columnKind: kind,
      drCrColumnIndex: drCrColumnIndex,
    );

    if (total != null) {
      footer[columnIndex] = _formatColumnTotal(
        rowsForTotals,
        columnIndex,
        total,
        kind,
      );
    }
  }

  return footer;
}

double? _sumColumn({
  required List<List<String?>> dataRows,
  required int columnIndex,
  required ColumnTotalKind columnKind,
  required int? drCrColumnIndex,
}) {
  var sawValue = false;
  var sum = 0.0;

  for (final row in dataRows) {
    if (columnIndex >= row.length) {
      continue;
    }

    final drCrHint = drCrColumnIndex != null && drCrColumnIndex < row.length
        ? row[drCrColumnIndex]
        : null;

    final parsed = WorkbookNumericParser.parseForTotal(
      raw: row[columnIndex],
      columnKind: columnKind,
      rowDrCrHint: drCrHint,
    );

    if (parsed == null) {
      continue;
    }

    sawValue = true;
    sum += parsed;
  }

  return sawValue ? sum : null;
}

String _formatColumnTotal(
  List<List<String?>> dataRows,
  int columnIndex,
  double total,
  ColumnTotalKind kind,
) {
  if (kind == ColumnTotalKind.count && total == total.roundToDouble()) {
    return total.toInt().toString();
  }

  final hasDecimalInput = dataRows.any((row) {
    if (columnIndex >= row.length) {
      return false;
    }
    final raw = row[columnIndex]?.trim();
    if (raw == null || raw.isEmpty) {
      return false;
    }
    return raw.contains('.') || raw.contains(',');
  });

  if (hasDecimalInput || kind == ColumnTotalKind.amount) {
    return total.toStringAsFixed(2);
  }
  if (total == total.roundToDouble()) {
    return total.toInt().toString();
  }
  return total.toStringAsFixed(2);
}

class WorkbookFileInput {
  const WorkbookFileInput({required this.fileName, required this.rows});

  final String fileName;
  final List<List<String?>> rows;
}

class WorkbookMergeOutcome {
  const WorkbookMergeOutcome({required this.rows, required this.fileResults});

  final List<List<String?>> rows;
  final List<SpreadsheetFileResult> fileResults;

  int get successCount => fileResults
      .where((f) => f.parseStatus == SpreadsheetParseStatus.success)
      .length;

  int get failureCount => fileResults
      .where((f) => f.parseStatus == SpreadsheetParseStatus.failed)
      .length;
}

bool _rowsEqual(List<String?> a, List<String?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    final left = a[i]?.trim().toLowerCase() ?? '';
    final right = b[i]?.trim().toLowerCase() ?? '';
    if (left != right) {
      return false;
    }
  }
  return true;
}
