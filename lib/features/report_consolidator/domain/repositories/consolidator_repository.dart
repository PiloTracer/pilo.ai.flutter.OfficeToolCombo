import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';

abstract class ConsolidatorRepository {
  Future<Result<String?>> pickSourceFolder();

  Future<Result<String?>> pickOutputFolder();

  Future<String?> readSavedOutputFolderPath();

  Future<void> saveOutputFolderPath(String? path);

  Future<List<MergeHistoryEntry>> readMergeHistory();

  Future<Result<WorkbookBatch>> consolidateFolder({
    required String folderPath,
    String? outputFolderPath,
    void Function(double progress)? onProgress,
  });

  Future<Result<void>> revealOutputFile(String outputPath);
}
