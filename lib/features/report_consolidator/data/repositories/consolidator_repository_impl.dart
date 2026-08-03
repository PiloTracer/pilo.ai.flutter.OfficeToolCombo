import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/platform/desktop_file_reveal.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/utils/isolate_runner.dart';
import 'package:office_tool_combo/features/report_consolidator/data/mappers/consolidator_failure_mapper.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_local_source.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_preferences_store.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/shared_preferences_consolidator_preferences_store.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/repositories/consolidator_repository.dart';

class ConsolidatorRepositoryImpl implements ConsolidatorRepository {
  ConsolidatorRepositoryImpl({
    ConsolidatorLocalSource? localSource,
    IsolateRunner? isolateRunner,
    ConsolidatorPreferencesStore? preferencesStore,
  }) : _localSource = localSource ?? const ConsolidatorLocalSource(),
       _isolateRunner = isolateRunner ?? const IsolateRunner(),
       _preferencesStore =
           preferencesStore ?? SharedPreferencesConsolidatorPreferencesStore();

  final ConsolidatorLocalSource _localSource;
  final IsolateRunner _isolateRunner;
  final ConsolidatorPreferencesStore _preferencesStore;

  @override
  Future<Result<String?>> pickSourceFolder() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select folder of Excel reports',
      );
      return Success<String?>(path);
    } on Object catch (error) {
      return Err<String?>(IoFailure('Could not open folder picker: $error'));
    }
  }

  @override
  Future<Result<String?>> pickOutputFolder() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select folder for consolidated workbook',
      );
      if (path != null && path.isNotEmpty) {
        await saveOutputFolderPath(path);
      }
      return Success<String?>(path);
    } on Object catch (error) {
      return Err<String?>(IoFailure('Could not open folder picker: $error'));
    }
  }

  @override
  Future<String?> readSavedOutputFolderPath() {
    return _preferencesStore.readOutputFolderPath();
  }

  @override
  Future<void> saveOutputFolderPath(String? path) {
    return _preferencesStore.writeOutputFolderPath(path);
  }

  @override
  Future<List<MergeHistoryEntry>> readMergeHistory() {
    return _preferencesStore.readMergeHistory();
  }

  @override
  Future<Result<void>> revealOutputFile(String outputPath) async {
    if (!File(outputPath).existsSync()) {
      return const Err<void>(
        IoFailure('That merged file no longer exists on disk.'),
      );
    }

    final revealed = await DesktopFileReveal.revealInFileManager(outputPath);
    if (!revealed) {
      return const Err<void>(
        IoFailure('Could not open the file location on this desktop.'),
      );
    }

    return const Success<void>(null);
  }

  @override
  Future<Result<WorkbookBatch>> consolidateFolder({
    required String folderPath,
    String? outputFolderPath,
    void Function(double progress)? onProgress,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final batchId = startedAt.microsecondsSinceEpoch.toString();
    final resolvedOutputFolder =
        outputFolderPath ?? await readSavedOutputFolderPath() ?? folderPath;

    try {
      final paths = await _localSource.listSpreadsheetFiles(folderPath);
      if (paths.isEmpty) {
        return Err<WorkbookBatch>(
          mapConsolidatorFailure(const EmptyFolderFailure()),
        );
      }
    } on ConsolidatorIoException catch (error) {
      return Err<WorkbookBatch>(
        mapConsolidatorFailure(UnreadableFolderFailure(error.message)),
      );
    }

    onProgress?.call(0);

    final response = await _isolateRunner
        .runWithProgress<
          ConsolidatorIsolateRequest,
          ConsolidatorIsolateResponse,
          double
        >(
          ConsolidatorIsolateRequest(
            folderPath: folderPath,
            outputFolderPath: resolvedOutputFolder,
          ),
          runConsolidationIsolateWithProgress,
          onProgress: onProgress,
        );

    onProgress?.call(1);

    if (response.errorMessage != null && response.outputPath == null) {
      if (response.fileResults.isEmpty) {
        return Err<WorkbookBatch>(
          mapConsolidatorFailure(
            UnreadableFolderFailure(response.errorMessage!),
          ),
        );
      }
      return Success<WorkbookBatch>(
        _batchFromResponse(
          id: batchId,
          folderPath: folderPath,
          outputFolderPath: resolvedOutputFolder,
          startedAt: startedAt,
          response: response,
          status: WorkbookBatchStatus.failed,
        ),
      );
    }

    final status = _statusFor(response.fileResults);
    final batch = _batchFromResponse(
      id: batchId,
      folderPath: folderPath,
      outputFolderPath: resolvedOutputFolder,
      startedAt: startedAt,
      response: response,
      status: status,
    );

    if (batch.outputPath != null &&
        batch.status != WorkbookBatchStatus.failed) {
      await _recordMergeHistory(batch);
    }

    return Success<WorkbookBatch>(batch);
  }

  Future<void> _recordMergeHistory(WorkbookBatch batch) async {
    final outputPath = batch.outputPath;
    if (outputPath == null) {
      return;
    }

    await _preferencesStore.prependMergeHistory(
      MergeHistoryEntry(
        outputPath: outputPath,
        fileName: _basename(outputPath),
        sourceFolderPath: batch.sourceFolderPath,
        mergedAt: (batch.finishedAt ?? DateTime.now()).toLocal(),
        status: batch.status.name,
      ),
    );
  }

  String _basename(String path) {
    final segments = path.split(Platform.pathSeparator);
    return segments.isEmpty ? path : segments.last;
  }

  WorkbookBatchStatus _statusFor(List<SpreadsheetFileResult> files) {
    final failures = files.where(
      (f) => f.parseStatus == SpreadsheetParseStatus.failed,
    );
    if (failures.isEmpty) {
      return WorkbookBatchStatus.succeeded;
    }
    final successes = files.where(
      (f) => f.parseStatus == SpreadsheetParseStatus.success,
    );
    if (successes.isEmpty) {
      return WorkbookBatchStatus.failed;
    }
    return WorkbookBatchStatus.partial;
  }

  WorkbookBatch _batchFromResponse({
    required String id,
    required String folderPath,
    required String outputFolderPath,
    required DateTime startedAt,
    required ConsolidatorIsolateResponse response,
    required WorkbookBatchStatus status,
  }) {
    return WorkbookBatch(
      id: id,
      sourceFolderPath: folderPath,
      outputPath: response.outputPath,
      status: status,
      startedAt: startedAt,
      finishedAt: DateTime.now().toUtc(),
      errorMessage: status == WorkbookBatchStatus.failed
          ? response.errorMessage
          : null,
      files: response.fileResults,
    );
  }
}
