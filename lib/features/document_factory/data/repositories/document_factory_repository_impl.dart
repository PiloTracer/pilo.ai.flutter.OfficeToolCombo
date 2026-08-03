import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/utils/isolate_runner.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/document_factory_local_source.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/document_factory_preferences_store.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/shared_preferences_document_factory_store.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_template.dart';
import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';
import 'package:office_tool_combo/features/document_factory/domain/services/placeholder_parser.dart';

class DocumentFactoryRepositoryImpl implements DocumentFactoryRepository {
  DocumentFactoryRepositoryImpl({
    DocumentFactoryLocalSource? localSource,
    IsolateRunner? isolateRunner,
    DocumentFactoryPreferencesStore? preferencesStore,
  }) : _localSource = localSource ?? const DocumentFactoryLocalSource(),
       _isolateRunner = isolateRunner ?? const IsolateRunner(),
       _preferencesStore =
           preferencesStore ?? SharedPreferencesDocumentFactoryStore();

  final DocumentFactoryLocalSource _localSource;
  final IsolateRunner _isolateRunner;
  final DocumentFactoryPreferencesStore _preferencesStore;

  @override
  Future<Result<String?>> pickTemplateFile() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select HTML template',
        type: FileType.custom,
        allowedExtensions: const ['html', 'htm'],
      );
      return Success<String?>(result?.files.single.path);
    } on Object catch (error) {
      return Err<String?>(IoFailure('Could not open file picker: $error'));
    }
  }

  @override
  Future<Result<String?>> pickDataSheetFile() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select data sheet',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      return Success<String?>(result?.files.single.path);
    } on Object catch (error) {
      return Err<String?>(IoFailure('Could not open file picker: $error'));
    }
  }

  @override
  Future<Result<String?>> pickOutputFolder() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select output folder',
      );
      return Success<String?>(path);
    } on Object catch (error) {
      return Err<String?>(IoFailure('Could not open folder picker: $error'));
    }
  }

  @override
  Future<Result<TemplateInspection>> inspectTemplate(String path) async {
    try {
      final html = await _localSource.readTemplateHtml(path);
      final placeholders = PlaceholderParser.discover(html);
      final restored = await _preferencesStore.readMapping(path);
      return Success<TemplateInspection>(
        TemplateInspection(
          template: DocumentTemplate(
            filePath: path,
            placeholders: placeholders,
          ),
          restoredMapping: restored,
        ),
      );
    } on DocumentFactoryIoException {
      return const Err<TemplateInspection>(
        IoFailure(DocumentFactoryFailureCodes.templateRead),
      );
    } on Object catch (error) {
      return Err<TemplateInspection>(
        IoFailure('${DocumentFactoryFailureCodes.templateRead}: $error'),
      );
    }
  }

  @override
  Future<Result<SheetInspection>> inspectDataSheet(String path) async {
    try {
      final sheet = await _localSource.readDataSheet(path);
      return Success<SheetInspection>(
        SheetInspection(
          headers: sheet.headers,
          dataRowCount: sheet.rows.length,
        ),
      );
    } on DocumentFactoryIoException catch (error) {
      return Err<SheetInspection>(IoFailure(error.code));
    } on Object catch (error) {
      return Err<SheetInspection>(
        IoFailure('${DocumentFactoryFailureCodes.sheetRead}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> saveMapping(
    String templatePath,
    Map<String, String> mapping,
  ) async {
    try {
      await _preferencesStore.writeMapping(templatePath, mapping);
      return const Success<void>(null);
    } on Object catch (error) {
      return Err<void>(
        IoFailure('${DocumentFactoryFailureCodes.mappingSave}: $error'),
      );
    }
  }

  @override
  Future<Result<DocumentJob>> runBatch({
    required String templatePath,
    required String dataSheetPath,
    required String outputDirPath,
    required Map<String, String> mapping,
    void Function(DocumentBatchProgress progress)? onProgress,
  }) async {
    // SPEC R4 — the job never starts when the output folder is not writable.
    final writable = await _localSource.probeOutputWritable(outputDirPath);
    if (!writable) {
      return const Err<DocumentJob>(
        IoFailure(DocumentFactoryFailureCodes.outputNotWritable),
      );
    }

    final startedAt = DateTime.now().toUtc();
    final jobId = startedAt.microsecondsSinceEpoch.toString();
    var job = DocumentJob(
      id: jobId,
      templatePath: templatePath,
      dataSheetPath: dataSheetPath,
      outputDirPath: outputDirPath,
      status: DocumentJobStatus.running,
      totalRows: 0,
      startedAt: startedAt,
    );
    // Persist `running` up front so an app exit mid-batch is detectable on
    // the next launch (SPEC §4.4).
    await _writeLastJob(job);

    DocumentBatchResponse response;
    try {
      response = await _isolateRunner
          .runWithProgress<
            DocumentBatchRequest,
            DocumentBatchResponse,
            DocumentBatchProgress
          >(
            DocumentBatchRequest(
              templatePath: templatePath,
              dataSheetPath: dataSheetPath,
              outputDirPath: outputDirPath,
              mapping: mapping,
            ),
            runDocumentBatchIsolate,
            onProgress: onProgress,
          );
    } on Object catch (error) {
      job = job.copyWith(
        status: DocumentJobStatus.failed,
        finishedAt: DateTime.now().toUtc(),
      );
      await _writeLastJob(job);
      return Err<DocumentJob>(
        IoFailure('${DocumentFactoryFailureCodes.generation}: $error'),
      );
    }

    if (response.errorCode != null) {
      job = job.copyWith(
        status: DocumentJobStatus.failed,
        finishedAt: DateTime.now().toUtc(),
      );
      await _writeLastJob(job);
      return Err<DocumentJob>(IoFailure(response.errorCode!));
    }

    final status = _statusFor(response);
    job = DocumentJob(
      id: job.id,
      templatePath: job.templatePath,
      dataSheetPath: job.dataSheetPath,
      outputDirPath: job.outputDirPath,
      status: status,
      totalRows: response.totalRows,
      startedAt: job.startedAt,
      doneCount: response.successCount,
      failedCount: response.failedCount,
      skippedCount: response.skippedCount,
      finishedAt: DateTime.now().toUtc(),
      failures: response.failures,
    );
    await _writeLastJob(job);

    return Success<DocumentJob>(job);
  }

  @override
  Future<DocumentJob?> readLastJob() {
    return _preferencesStore.readLastJob();
  }

  @override
  Future<void> markLastJobInterrupted() async {
    final job = await _preferencesStore.readLastJob();
    if (job == null || job.status != DocumentJobStatus.running) {
      return;
    }
    await _preferencesStore.writeLastJob(
      job.copyWith(
        status: DocumentJobStatus.failed,
        finishedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<Result<void>> revealOutputFolder(String path) async {
    if (!Directory(path).existsSync()) {
      return const Err<void>(IoFailure(DocumentFactoryFailureCodes.reveal));
    }

    final opened = await _openFolder(path);
    if (!opened) {
      return const Err<void>(IoFailure(DocumentFactoryFailureCodes.reveal));
    }
    return const Success<void>(null);
  }

  Future<bool> _openFolder(String path) async {
    try {
      if (Platform.isMacOS) {
        final result = await Process.run('open', [path]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('explorer', [path]);
        return result.exitCode == 0 || result.exitCode == 1;
      }
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [path]);
        return result.exitCode == 0;
      }
    } on Object {
      return false;
    }
    return false;
  }

  DocumentJobStatus _statusFor(DocumentBatchResponse response) {
    if (response.successCount == 0 && response.failedCount > 0) {
      return DocumentJobStatus.failed;
    }
    if (response.failedCount > 0) {
      return DocumentJobStatus.partial;
    }
    return DocumentJobStatus.succeeded;
  }

  Future<void> _writeLastJob(DocumentJob job) async {
    try {
      await _preferencesStore.writeLastJob(job);
    } on Object {
      // Job bookkeeping must not fail the batch itself.
    }
  }
}
