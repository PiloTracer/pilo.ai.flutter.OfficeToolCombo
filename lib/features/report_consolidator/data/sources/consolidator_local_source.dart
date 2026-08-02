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
    required String folderPath,
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
              .value = TextCellValue(
            value,
          );
        }
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw ConsolidatorIoException('Failed to encode consolidated workbook');
    }

    final outputPath = _outputPathFor(folderPath);
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
              .map((cell) => cell?.value?.toString())
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  String _outputPathFor(String folderPath) {
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    return '$folderPath${Platform.pathSeparator}consolidated_$timestamp.xlsx';
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
  const ConsolidatorIsolateRequest({required this.folderPath});

  final String folderPath;
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
) async {
  const source = ConsolidatorLocalSource();
  try {
    final data = await source.consolidate(
      folderPath: request.folderPath,
      onProgress: null,
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
      folderPath: request.folderPath,
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
