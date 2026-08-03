import 'dart:async';

import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/repositories/consolidator_repository.dart';

/// Configurable in-memory [ConsolidatorRepository] for presentation tests.
///
/// Every method returns a canned answer; [consolidateCompleter] lets a test
/// hold the merge in-flight to observe the loading phase.
class FakeConsolidatorRepository implements ConsolidatorRepository {
  String? savedOutputFolderPath;
  List<MergeHistoryEntry> mergeHistory = [];

  Result<String?>? pickSourceFolderResult;
  Result<String?>? pickOutputFolderResult;
  Result<WorkbookBatch>? consolidateResult;
  Completer<Result<WorkbookBatch>>? consolidateCompleter;
  Result<void> revealResult = const Success<void>(null);

  /// Progress values emitted synchronously before the merge resolves.
  List<double> progressToEmit = const [];

  var consolidateCalls = 0;
  String? lastConsolidatedFolder;
  String? lastOutputFolderPath;
  final List<String> revealedPaths = [];

  @override
  Future<Result<String?>> pickSourceFolder() async {
    return pickSourceFolderResult ?? const Success<String?>(null);
  }

  @override
  Future<Result<String?>> pickOutputFolder() async {
    return pickOutputFolderResult ?? const Success<String?>(null);
  }

  @override
  Future<String?> readSavedOutputFolderPath() async => savedOutputFolderPath;

  @override
  Future<void> saveOutputFolderPath(String? path) async {
    savedOutputFolderPath = path;
  }

  @override
  Future<List<MergeHistoryEntry>> readMergeHistory() async {
    return List<MergeHistoryEntry>.from(mergeHistory);
  }

  @override
  Future<Result<WorkbookBatch>> consolidateFolder({
    required String folderPath,
    String? outputFolderPath,
    void Function(double progress)? onProgress,
  }) async {
    consolidateCalls++;
    lastConsolidatedFolder = folderPath;
    lastOutputFolderPath = outputFolderPath;
    for (final value in progressToEmit) {
      onProgress?.call(value);
    }
    final completer = consolidateCompleter;
    if (completer != null) {
      return completer.future;
    }
    return consolidateResult ?? Success<WorkbookBatch>(buildBatch());
  }

  @override
  Future<Result<void>> revealOutputFile(String outputPath) async {
    revealedPaths.add(outputPath);
    return revealResult;
  }
}

WorkbookBatch buildBatch({
  WorkbookBatchStatus status = WorkbookBatchStatus.succeeded,
  String? outputPath = '/tmp/out/consolidated_2026-08-01.xlsx',
  String? errorMessage,
  List<SpreadsheetFileResult> files = const [
    SpreadsheetFileResult(
      fileName: 'report_a.xlsx',
      parseStatus: SpreadsheetParseStatus.success,
    ),
  ],
}) {
  return WorkbookBatch(
    id: 'batch-1',
    sourceFolderPath: '/tmp/source',
    outputPath: outputPath,
    status: status,
    startedAt: DateTime.utc(2026, 8, 1, 12),
    finishedAt: DateTime.utc(2026, 8, 1, 12, 1),
    errorMessage: errorMessage,
    files: files,
  );
}

MergeHistoryEntry buildHistoryEntry({
  String outputPath = '/tmp/out/consolidated_2026-08-01.xlsx',
  String fileName = 'consolidated_2026-08-01.xlsx',
  String sourceFolderPath = '/tmp/source',
  DateTime? mergedAt,
  String status = 'succeeded',
}) {
  return MergeHistoryEntry(
    outputPath: outputPath,
    fileName: fileName,
    sourceFolderPath: sourceFolderPath,
    mergedAt: mergedAt ?? DateTime(2026, 8, 1, 12, 30),
    status: status,
  );
}
