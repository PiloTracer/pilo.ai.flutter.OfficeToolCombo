import 'package:file_picker/file_picker.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/utils/isolate_runner.dart';
import 'package:office_tool_combo/features/report_consolidator/data/mappers/consolidator_failure_mapper.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_local_source.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/repositories/consolidator_repository.dart';

class ConsolidatorRepositoryImpl implements ConsolidatorRepository {
  ConsolidatorRepositoryImpl({
    ConsolidatorLocalSource? localSource,
    IsolateRunner? isolateRunner,
  }) : _localSource = localSource ?? const ConsolidatorLocalSource(),
       _isolateRunner = isolateRunner ?? const IsolateRunner();

  final ConsolidatorLocalSource _localSource;
  final IsolateRunner _isolateRunner;

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
  Future<Result<WorkbookBatch>> consolidateFolder({
    required String folderPath,
    void Function(double progress)? onProgress,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final batchId = startedAt.microsecondsSinceEpoch.toString();

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
        .run<ConsolidatorIsolateRequest, ConsolidatorIsolateResponse>(
          ConsolidatorIsolateRequest(folderPath: folderPath),
          runConsolidationIsolate,
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
          startedAt: startedAt,
          response: response,
          status: WorkbookBatchStatus.failed,
        ),
      );
    }

    final status = _statusFor(response.fileResults);
    return Success<WorkbookBatch>(
      _batchFromResponse(
        id: batchId,
        folderPath: folderPath,
        startedAt: startedAt,
        response: response,
        status: status,
      ),
    );
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
      files: response.fileResults,
    );
  }
}
