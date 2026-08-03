import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/services/workbook_merger.dart';

class ConsolidatorLocalSource {
  const ConsolidatorLocalSource({WorkbookMerger? merger})
    : _merger = merger ?? const WorkbookMerger();

  final WorkbookMerger _merger;

  Future<List<String>> listSpreadsheetFiles(String folderPath) async {
    final directory = Directory(folderPath);
    if (!directory.existsSync()) {
      throw ConsolidatorIoException('Folder does not exist');
    }

    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => _isSpreadsheet(file.path))
            .map((file) => file.path)
            .toList()
          ..sort();

    return files;
  }

  Future<ConsolidatorRunData> consolidate({
    required String folderPath,
    void Function(double progress)? onProgress,
  }) async {
    final paths = await listSpreadsheetFiles(folderPath);
    if (paths.isEmpty) {
      return const ConsolidatorRunData(
        rows: <List<String?>>[],
        fileResults: <SpreadsheetFileResult>[],
      );
    }

    final inputs = <WorkbookFileInput>[];
    final fileResults = <SpreadsheetFileResult>[];
    final total = paths.length;

    for (var index = 0; index < paths.length; index++) {
      final path = paths[index];
      final fileName = _basename(path);
      try {
        final bytes = await File(path).readAsBytes();
        final rows = _decodeFirstSheet(bytes);
        inputs.add(WorkbookFileInput(fileName: fileName, rows: rows));
      } on Object catch (error) {
        fileResults.add(
          SpreadsheetFileResult(
            fileName: fileName,
            parseStatus: SpreadsheetParseStatus.failed,
            errorMessage: error.toString(),
          ),
        );
      }
      onProgress?.call((index + 1) / total);
    }

    final mergeOutcome = _merger.merge(inputs);
    return ConsolidatorRunData(
      rows: mergeOutcome.rows,
      fileResults: [...fileResults, ...mergeOutcome.fileResults],
    );
  }

  Future<String> writeWorkbook({
    required String outputFolderPath,
    required List<List<String?>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    sheet.removeRow(0);

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        final value = row[colIndex];
        if (value != null) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = _cellValueFor(value);
        }
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw ConsolidatorIoException('Failed to encode consolidated workbook');
    }

    final outputPath = _outputPathFor(outputFolderPath);
    await File(outputPath).writeAsBytes(encoded, flush: true);
    return outputPath;
  }

  List<List<String?>> _decodeFirstSheet(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const <List<String?>>[];
    }

    final sheet = workbook.tables.values.first;
    if (sheet.rows.isEmpty) {
      return const <List<String?>>[];
    }

    return sheet.rows
        .map(
          (row) => row
              .map((cell) => _cellValueToString(cell?.value))
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  /// Converts an Excel cell to a clean string for merging.
  ///
  /// Formula cells keep their formula text (the `excel` package does not
  /// evaluate formulas); date/time cells get readable ISO formats instead of
  /// debug dumps.
  String? _cellValueToString(CellValue? value) {
    if (value == null) {
      return null;
    }
    return switch (value) {
      TextCellValue() => value.toString(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value ? 'TRUE' : 'FALSE',
      FormulaCellValue() => value.formula,
      DateCellValue() => _twoPartDate(value.year, value.month, value.day),
      TimeCellValue() =>
        '${_pad(value.hour)}:${_pad(value.minute)}:${_pad(value.second)}',
      DateTimeCellValue() =>
        '${_twoPartDate(value.year, value.month, value.day)}'
            'T${_pad(value.hour)}:${_pad(value.minute)}:${_pad(value.second)}',
    };
  }

  String _twoPartDate(int year, int month, int day) {
    return '${year.toString().padLeft(4, '0')}-${_pad(month)}-${_pad(day)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  /// Writes numbers as real numeric cells so totals and quantities stay
  /// computable in Excel; identifiers with leading zeros (`007`, `01`)
  /// and non-plain formats (`1e5`) stay text.
  CellValue _cellValueFor(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty && trimmed == raw && !_hasLeadingZero(trimmed)) {
      final intValue = int.tryParse(trimmed);
      if (intValue != null) {
        return IntCellValue(intValue);
      }
      if (trimmed.contains('.')) {
        final doubleValue = double.tryParse(trimmed);
        if (doubleValue != null) {
          return DoubleCellValue(doubleValue);
        }
      }
    }
    return TextCellValue(raw);
  }

  bool _hasLeadingZero(String digits) {
    final start = digits.startsWith('-') ? 1 : 0;
    return digits.length > start + 1 &&
        digits[start] == '0' &&
        digits.codeUnitAt(start + 1) >= 0x30 &&
        digits.codeUnitAt(start + 1) <= 0x39;
  }

  String _outputPathFor(String outputFolderPath) {
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    return '$outputFolderPath${Platform.pathSeparator}consolidated_$timestamp.xlsx';
  }

  bool _isSpreadsheet(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.xlsx') && !lower.contains('consolidated_');
  }

  String _basename(String path) {
    final segments = path.split(Platform.pathSeparator);
    return segments.isEmpty ? path : segments.last;
  }
}

class ConsolidatorRunData {
  const ConsolidatorRunData({required this.rows, required this.fileResults});

  final List<List<String?>> rows;
  final List<SpreadsheetFileResult> fileResults;

  int get successCount => fileResults
      .where((f) => f.parseStatus == SpreadsheetParseStatus.success)
      .length;

  int get failureCount => fileResults
      .where((f) => f.parseStatus == SpreadsheetParseStatus.failed)
      .length;
}

class ConsolidatorIoException implements Exception {
  ConsolidatorIoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Serializable payload for isolate merge work.
class ConsolidatorIsolateRequest {
  const ConsolidatorIsolateRequest({
    required this.folderPath,
    required this.outputFolderPath,
  });

  final String folderPath;
  final String outputFolderPath;
}

class ConsolidatorIsolateResponse {
  const ConsolidatorIsolateResponse({
    required this.rows,
    required this.fileResults,
    this.outputPath,
    this.errorMessage,
  });

  final List<List<String?>> rows;
  final List<SpreadsheetFileResult> fileResults;
  final String? outputPath;
  final String? errorMessage;
}

Future<ConsolidatorIsolateResponse> runConsolidationIsolate(
  ConsolidatorIsolateRequest request,
) {
  return runConsolidationIsolateWithProgress(request, null);
}

/// Variant of [runConsolidationIsolate] that reports per-file progress
/// (0..1) through [emitProgress] so callers can stream it out of the
/// isolate.
Future<ConsolidatorIsolateResponse> runConsolidationIsolateWithProgress(
  ConsolidatorIsolateRequest request,
  void Function(double progress)? emitProgress,
) async {
  const source = ConsolidatorLocalSource();
  try {
    final data = await source.consolidate(
      folderPath: request.folderPath,
      onProgress: emitProgress,
    );
    if (data.fileResults.isEmpty && data.rows.isEmpty) {
      return ConsolidatorIsolateResponse(
        rows: data.rows,
        fileResults: data.fileResults,
      );
    }

    if (data.successCount == 0) {
      return ConsolidatorIsolateResponse(
        rows: data.rows,
        fileResults: data.fileResults,
        errorMessage: 'No readable spreadsheets in folder',
      );
    }

    final outputPath = await source.writeWorkbook(
      outputFolderPath: request.outputFolderPath,
      rows: data.rows,
    );

    return ConsolidatorIsolateResponse(
      rows: data.rows,
      fileResults: data.fileResults,
      outputPath: outputPath,
    );
  } on ConsolidatorIoException catch (error) {
    return ConsolidatorIsolateResponse(
      rows: const <List<String?>>[],
      fileResults: const <SpreadsheetFileResult>[],
      errorMessage: error.message,
    );
  } on Object catch (error) {
    return ConsolidatorIsolateResponse(
      rows: const <List<String?>>[],
      fileResults: const <SpreadsheetFileResult>[],
      errorMessage: error.toString(),
    );
  }
}
