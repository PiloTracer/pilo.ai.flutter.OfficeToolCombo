import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';

abstract class ConsolidatorRepository {
  Future<Result<String?>> pickSourceFolder();

  Future<Result<WorkbookBatch>> consolidateFolder({
    required String folderPath,
    void Function(double progress)? onProgress,
  });
}
