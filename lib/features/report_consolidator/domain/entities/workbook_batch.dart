import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';

part 'workbook_batch.freezed.dart';

enum WorkbookBatchStatus { pending, running, succeeded, partial, failed }

@freezed
abstract class WorkbookBatch with _$WorkbookBatch {
  const factory WorkbookBatch({
    required String id,
    required String sourceFolderPath,
    String? outputPath,
    required WorkbookBatchStatus status,
    required DateTime startedAt,
    DateTime? finishedAt,
    @Default(<SpreadsheetFileResult>[]) List<SpreadsheetFileResult> files,
  }) = _WorkbookBatch;
}
