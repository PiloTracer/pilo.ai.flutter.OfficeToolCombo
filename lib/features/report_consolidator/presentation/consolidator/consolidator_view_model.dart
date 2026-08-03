import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/repositories/consolidator_repository.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_providers.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_ui_state.dart';

class ConsolidatorViewModel extends Notifier<ConsolidatorUiState> {
  ConsolidatorRepository get _repository =>
      ref.read(consolidatorRepositoryProvider);

  @override
  ConsolidatorUiState build() {
    return const ConsolidatorUiState();
  }

  Future<void> loadInitialState() async {
    final savedPath = await _repository.readSavedOutputFolderPath();
    if (!ref.mounted) return;
    final history = await _repository.readMergeHistory();
    if (!ref.mounted) return;
    state = state.copyWith(outputFolderPath: savedPath, mergeHistory: history);
  }

  Future<void> loadSavedOutputFolder() => loadInitialState();

  Future<void> pickOutputFolder() async {
    final pickResult = await _repository.pickOutputFolder();
    if (!ref.mounted) return;
    pickResult.when(
      success: (path) {
        if (path == null || path.isEmpty) {
          return;
        }
        state = state.copyWith(outputFolderPath: path);
      },
      failure: (failure) {
        state = state.copyWith(
          phase: ConsolidatorPhase.error,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> useSourceFolderForOutput() async {
    await _repository.saveOutputFolderPath(null);
    if (!ref.mounted) return;
    state = state.copyWith(outputFolderPath: null);
  }

  Future<void> pickFolderAndMerge() async {
    final pickResult = await _repository.pickSourceFolder();
    if (!ref.mounted) return;
    await pickResult.when(
      success: (path) async {
        if (path == null || path.isEmpty) {
          return;
        }
        await _mergeFolder(path);
      },
      failure: (failure) {
        state = state.copyWith(
          phase: ConsolidatorPhase.error,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> openMergeOutput(String outputPath) async {
    final result = await _repository.revealOutputFile(outputPath);
    if (!ref.mounted) return;
    result.when(
      success: (_) {},
      failure: (failure) {
        state = state.copyWith(
          phase: ConsolidatorPhase.error,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> _mergeFolder(String folderPath) async {
    state = state.copyWith(
      phase: ConsolidatorPhase.loading,
      selectedFolderPath: folderPath,
      progress: 0,
      errorMessage: null,
      outputFileName: null,
      lastBatch: null,
    );

    final result = await _repository.consolidateFolder(
      folderPath: folderPath,
      outputFolderPath: state.outputFolderPath,
      onProgress: (value) {
        if (!ref.mounted) return;
        state = state.copyWith(progress: value);
      },
    );
    if (!ref.mounted) return;

    await result.when(
      success: (batch) async {
        final history = await _repository.readMergeHistory();
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: _phaseForBatch(batch),
          progress: 1,
          lastBatch: batch,
          outputFileName: _basename(batch.outputPath),
          mergeHistory: history,
          errorMessage:
              batch.status == WorkbookBatchStatus.failed
              ? batch.errorMessage
              : null,
        );
      },
      failure: (failure) async {
        state = state.copyWith(
          phase: _phaseForFailure(failure),
          errorMessage: failure.message,
        );
      },
    );
  }

  ConsolidatorPhase _phaseForBatch(WorkbookBatch batch) {
    return switch (batch.status) {
      WorkbookBatchStatus.succeeded => ConsolidatorPhase.success,
      WorkbookBatchStatus.partial => ConsolidatorPhase.partial,
      WorkbookBatchStatus.failed => ConsolidatorPhase.error,
      WorkbookBatchStatus.pending ||
      WorkbookBatchStatus.running => ConsolidatorPhase.loading,
    };
  }

  ConsolidatorPhase _phaseForFailure(Failure failure) {
    if (failure.message == EmptyFolderFailure.emptyFolderMessage) {
      return ConsolidatorPhase.empty;
    }
    return ConsolidatorPhase.error;
  }

  String? _basename(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    final segments = path.split(RegExp(r'[/\\]'));
    return segments.isEmpty ? path : segments.last;
  }
}

final consolidatorViewModelProvider =
    NotifierProvider<ConsolidatorViewModel, ConsolidatorUiState>(
      ConsolidatorViewModel.new,
    );
