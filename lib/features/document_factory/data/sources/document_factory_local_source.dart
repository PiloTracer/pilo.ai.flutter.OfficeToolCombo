import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:office_tool_combo/features/document_factory/data/services/html_document_renderer.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';

/// Typed cell grid of the data sheet: header row plus data rows.
class SheetData {
  const SheetData({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String?>> rows;
}

/// IO failure whose [code] is a stable DocumentFactoryFailureCodes value.
class DocumentFactoryIoException implements Exception {
  DocumentFactoryIoException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// File/data access for the document factory. Runs in the UI isolate for
/// inspections and inside the batch isolate for generation.
class DocumentFactoryLocalSource {
  const DocumentFactoryLocalSource();

  Future<String> readTemplateHtml(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw DocumentFactoryIoException(
          DocumentFactoryFailureCodes.templateRead,
          'Template file does not exist',
        );
      }
      return await file.readAsString();
    } on DocumentFactoryIoException {
      rethrow;
    } on Object catch (error) {
      throw DocumentFactoryIoException(
        DocumentFactoryFailureCodes.templateRead,
        'Could not read template: $error',
      );
    }
  }

  /// Reads the first sheet of an `.xlsx` workbook (SPEC R2).
  ///
  /// Throws [DocumentFactoryIoException] with `duplicateHeaders` when two
  /// header cells share a name (SPEC §9).
  Future<SheetData> readDataSheet(String path) async {
    Uint8List bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on Object catch (error) {
      throw DocumentFactoryIoException(
        DocumentFactoryFailureCodes.sheetRead,
        'Could not read data sheet: $error',
      );
    }

    Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } on Object catch (error) {
      throw DocumentFactoryIoException(
        DocumentFactoryFailureCodes.sheetRead,
        'Could not parse data sheet: $error',
      );
    }
    if (workbook.tables.isEmpty || workbook.tables.values.first.rows.isEmpty) {
      throw DocumentFactoryIoException(
        DocumentFactoryFailureCodes.sheetRead,
        'Data sheet has no header row',
      );
    }

    final sheet = workbook.tables.values.first;
    final headerRow = sheet.rows.first;
    final headers = headerRow
        .map((cell) => (_cellValueToString(cell?.value) ?? '').trim())
        .toList(growable: false);

    final seen = <String>{};
    for (final header in headers) {
      if (header.isNotEmpty && !seen.add(header)) {
        throw DocumentFactoryIoException(
          DocumentFactoryFailureCodes.duplicateHeaders,
          'Duplicate column header: $header',
        );
      }
    }

    final rows = sheet.rows
        .skip(1)
        .map(
          (row) => List<String?>.generate(
            headers.length,
            (index) => index < row.length
                ? _cellValueToString(row[index]?.value)
                : null,
            growable: false,
          ),
        )
        .toList(growable: false);

    return SheetData(
      headers: List<String>.unmodifiable(headers),
      rows: List<List<String?>>.unmodifiable(rows),
    );
  }

  /// SPEC R4 — probe writability before the job starts.
  Future<bool> probeOutputWritable(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      if (!directory.existsSync()) {
        return false;
      }
      final probe = File(
        '$dirPath${Platform.pathSeparator}.document_factory_probe',
      );
      await probe.writeAsBytes(const <int>[0], flush: true);
      await probe.delete();
      return true;
    } on Object {
      return false;
    }
  }

  Future<String> writePdf(String path, Uint8List bytes) async {
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Same typed-cell decode as the consolidator: dates `yyyy-MM-dd`,
  /// bools TRUE/FALSE, numbers plain.
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
}

/// Serializable payload for the batch isolate.
class DocumentBatchRequest {
  const DocumentBatchRequest({
    required this.templatePath,
    required this.dataSheetPath,
    required this.outputDirPath,
    required this.mapping,
  });

  final String templatePath;
  final String dataSheetPath;
  final String outputDirPath;
  final Map<String, String> mapping;
}

/// Outcome of a finished batch. [errorCode] is a stable
/// DocumentFactoryFailureCodes value when the batch could not run at all.
class DocumentBatchResponse {
  const DocumentBatchResponse({
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.totalRows,
    required this.failures,
    this.errorCode,
  });

  final int successCount;
  final int failedCount;
  final int skippedCount;
  final int totalRows;
  final List<RowFailure> failures;
  final String? errorCode;
}

/// Batch worker — must stay top-level so it can cross the isolate boundary.
///
/// SPEC R3: rows whose mapped cells are all blank are skipped (counted
/// separately, never success/failure). SPEC R5: a row failure does not
/// abort the batch. Output files are `{rowNumber}.pdf` with the 1-based
/// data row number.
Future<DocumentBatchResponse> runDocumentBatchIsolate(
  DocumentBatchRequest request,
  void Function(DocumentBatchProgress progress)? emitProgress,
) async {
  const source = DocumentFactoryLocalSource();
  const renderer = HtmlDocumentRenderer();

  try {
    final html = await source.readTemplateHtml(request.templatePath);
    final sheet = await source.readDataSheet(request.dataSheetPath);
    final templateDir = File(request.templatePath).parent.path;
    final template = await renderer.parse(html, templateDir);

    final headerIndex = <String, int>{
      for (var i = 0; i < sheet.headers.length; i++) sheet.headers[i]: i,
    };

    final total = sheet.rows.length;
    var done = 0;
    var failed = 0;
    var skipped = 0;
    final failures = <RowFailure>[];

    for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
      final rowNumber = rowIndex + 1;
      final row = sheet.rows[rowIndex];

      final values = <String, String>{};
      for (final entry in request.mapping.entries) {
        final columnIndex = headerIndex[entry.value];
        final cell = columnIndex != null && columnIndex < row.length
            ? row[columnIndex]
            : null;
        values[entry.key] = cell ?? '';
      }

      if (values.values.every((value) => value.trim().isEmpty)) {
        skipped++;
      } else if (values.values.any((value) => value.trim().isEmpty)) {
        failed++;
        failures.add(
          RowFailure(
            rowNumber: rowNumber,
            code: DocumentFactoryFailureCodes.rowMissingValue,
            message: 'Row $rowNumber has an empty mapped cell',
          ),
        );
      } else {
        try {
          final bytes = await renderer.render(template, values);
          final outputPath =
              '${request.outputDirPath}${Platform.pathSeparator}$rowNumber.pdf';
          await source.writePdf(outputPath, bytes);
          done++;
        } on Object catch (error) {
          failed++;
          failures.add(
            RowFailure(
              rowNumber: rowNumber,
              code: DocumentFactoryFailureCodes.rowRender,
              message: 'Row $rowNumber render failed: $error',
            ),
          );
        }
      }

      emitProgress?.call(
        DocumentBatchProgress(
          done: done,
          failed: failed,
          skipped: skipped,
          total: total,
        ),
      );
    }

    return DocumentBatchResponse(
      successCount: done,
      failedCount: failed,
      skippedCount: skipped,
      totalRows: total,
      failures: List<RowFailure>.unmodifiable(failures),
    );
  } on DocumentFactoryIoException catch (error) {
    return DocumentBatchResponse(
      successCount: 0,
      failedCount: 0,
      skippedCount: 0,
      totalRows: 0,
      failures: const <RowFailure>[],
      errorCode: error.code,
    );
  } on Object {
    return const DocumentBatchResponse(
      successCount: 0,
      failedCount: 0,
      skippedCount: 0,
      totalRows: 0,
      failures: <RowFailure>[],
      errorCode: DocumentFactoryFailureCodes.generation,
    );
  }
}
