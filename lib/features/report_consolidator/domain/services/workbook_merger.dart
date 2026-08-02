import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';

/// Pure merge rules for spreadsheet rows (no IO, no Flutter).
class WorkbookMerger {
  const WorkbookMerger();

  /// Merges per-file sheet rows into one output sheet.
  ///
  /// The first non-empty file keeps its header row. Subsequent files skip their
  /// first row when it matches the established header.
  ///
  /// When the merge produces at least one row, a footer row is appended with
  /// the count of data rows (header excluded): `Row count` | `<n>`.
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
      mergedRows.add(_rowCountFooter(mergedRows: mergedRows, header: header));
    }

    return WorkbookMergeOutcome(rows: mergedRows, fileResults: fileResults);
  }
}

/// Footer: label in column 0, data-row count in column 1 (header excluded).
List<String?> _rowCountFooter({
  required List<List<String?>> mergedRows,
  required List<String?>? header,
}) {
  final dataCount = header == null ? mergedRows.length : mergedRows.length - 1;
  final width = header?.length ?? mergedRows.first.length;
  final footer = List<String?>.filled(width < 2 ? 2 : width, null);
  footer[0] = 'Row count';
  footer[1] = '$dataCount';
  return footer;
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
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
