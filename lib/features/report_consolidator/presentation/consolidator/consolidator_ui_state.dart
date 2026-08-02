import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';

part 'consolidator_ui_state.freezed.dart';

enum ConsolidatorPhase { loading, empty, partial, error, offline, success }

@freezed
abstract class ConsolidatorUiState with _$ConsolidatorUiState {
  const factory ConsolidatorUiState({
    @Default(ConsolidatorPhase.empty) ConsolidatorPhase phase,
    String? selectedFolderPath,
    String? outputFolderPath,
    String? outputFileName,
    @Default(0) double progress,
    String? errorMessage,
    WorkbookBatch? lastBatch,
    @Default(<MergeHistoryEntry>[]) List<MergeHistoryEntry> mergeHistory,
  }) = _ConsolidatorUiState;
}
