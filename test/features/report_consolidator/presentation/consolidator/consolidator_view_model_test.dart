import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_providers.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_ui_state.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view_model.dart';

import '../../fakes/fake_consolidator_repository.dart';

void main() {
  late FakeConsolidatorRepository repository;
  late ProviderContainer container;

  ConsolidatorViewModel viewModel() =>
      container.read(consolidatorViewModelProvider.notifier);

  ConsolidatorUiState uiState() =>
      container.read(consolidatorViewModelProvider);

  setUp(() {
    repository = FakeConsolidatorRepository();
    container = ProviderContainer(
      overrides: [consolidatorRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('loadInitialState populates saved path and merge history', () async {
    repository.savedOutputFolderPath = '/tmp/saved-out';
    repository.mergeHistory = [buildHistoryEntry()];

    await viewModel().loadInitialState();

    expect(uiState().outputFolderPath, '/tmp/saved-out');
    expect(uiState().mergeHistory, hasLength(1));
    expect(
      uiState().mergeHistory.single.fileName,
      'consolidated_2026-08-01.xlsx',
    );
  });

  test('pickOutputFolder stores the chosen path', () async {
    repository.pickOutputFolderResult = const Success<String?>('/tmp/new-out');

    await viewModel().pickOutputFolder();

    expect(uiState().outputFolderPath, '/tmp/new-out');
  });

  test('pickOutputFolder ignores null or empty selections', () async {
    await viewModel().loadInitialState();
    final before = uiState();

    repository.pickOutputFolderResult = const Success<String?>(null);
    await viewModel().pickOutputFolder();
    expect(uiState(), before);

    repository.pickOutputFolderResult = const Success<String?>('');
    await viewModel().pickOutputFolder();
    expect(uiState(), before);
  });

  test('pickOutputFolder failure surfaces the error phase', () async {
    repository.pickOutputFolderResult = const Err<String?>(
      IoFailure('picker exploded'),
    );

    await viewModel().pickOutputFolder();

    expect(uiState().phase, ConsolidatorPhase.error);
    expect(uiState().errorMessage, 'picker exploded');
  });

  test('useSourceFolderForOutput clears the saved path', () async {
    repository.savedOutputFolderPath = '/tmp/saved-out';
    await viewModel().loadInitialState();
    expect(uiState().outputFolderPath, '/tmp/saved-out');

    await viewModel().useSourceFolderForOutput();

    expect(uiState().outputFolderPath, isNull);
    expect(repository.savedOutputFolderPath, isNull);
  });

  test('pickFolderAndMerge ignores a cancelled picker', () async {
    repository.pickSourceFolderResult = const Success<String?>(null);

    await viewModel().pickFolderAndMerge();

    expect(uiState().phase, ConsolidatorPhase.empty);
    expect(repository.consolidateCalls, 0);
  });

  test('pickFolderAndMerge surfaces a picker failure', () async {
    repository.pickSourceFolderResult = const Err<String?>(
      IoFailure('picker unavailable'),
    );

    await viewModel().pickFolderAndMerge();

    expect(uiState().phase, ConsolidatorPhase.error);
    expect(uiState().errorMessage, 'picker unavailable');
  });

  test(
    'successful merge ends in success phase with file name and history',
    () async {
      repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
      repository.consolidateResult = Success<WorkbookBatch>(buildBatch());
      repository.mergeHistory = [buildHistoryEntry()];

      await viewModel().pickFolderAndMerge();

      final state = uiState();
      expect(state.phase, ConsolidatorPhase.success);
      expect(state.progress, 1);
      expect(state.selectedFolderPath, '/tmp/source');
      expect(state.outputFileName, 'consolidated_2026-08-01.xlsx');
      expect(state.errorMessage, isNull);
      expect(state.mergeHistory, hasLength(1));
      expect(repository.lastConsolidatedFolder, '/tmp/source');
    },
  );

  test('partial merge ends in partial phase', () async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = Success<WorkbookBatch>(
      buildBatch(status: WorkbookBatchStatus.partial),
    );

    await viewModel().pickFolderAndMerge();

    expect(uiState().phase, ConsolidatorPhase.partial);
    expect(uiState().errorMessage, isNull);
  });

  test(
    'failed batch ends in error phase with the batch error message',
    () async {
      repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
      repository.consolidateResult = Success<WorkbookBatch>(
        buildBatch(
          status: WorkbookBatchStatus.failed,
          outputPath: null,
          errorMessage: 'Nothing could be merged',
        ),
      );

      await viewModel().pickFolderAndMerge();

      expect(uiState().phase, ConsolidatorPhase.error);
      expect(uiState().errorMessage, 'Nothing could be merged');
    },
  );

  test('merge forwards the saved output folder to the repository', () async {
    repository.savedOutputFolderPath = '/tmp/saved-out';
    await viewModel().loadInitialState();
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = Success<WorkbookBatch>(buildBatch());

    await viewModel().pickFolderAndMerge();

    expect(repository.lastOutputFolderPath, '/tmp/saved-out');
  });

  test('empty-folder failure maps to the empty phase', () async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = const Err<WorkbookBatch>(
      IoFailure(EmptyFolderFailure.emptyFolderMessage),
    );

    await viewModel().pickFolderAndMerge();

    expect(uiState().phase, ConsolidatorPhase.empty);
    expect(uiState().selectedFolderPath, '/tmp/source');
    expect(uiState().errorMessage, EmptyFolderFailure.emptyFolderMessage);
  });

  test('other merge failures map to the error phase', () async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = const Err<WorkbookBatch>(
      IoFailure('Could not read folder: permission denied'),
    );

    await viewModel().pickFolderAndMerge();

    expect(uiState().phase, ConsolidatorPhase.error);
    expect(uiState().errorMessage, 'Could not read folder: permission denied');
  });

  test('openMergeOutput failure surfaces the error phase', () async {
    repository.revealResult = const Err<void>(IoFailure('file is gone'));

    await viewModel().openMergeOutput('/tmp/out/missing.xlsx');

    expect(uiState().phase, ConsolidatorPhase.error);
    expect(uiState().errorMessage, 'file is gone');
    expect(repository.revealedPaths, ['/tmp/out/missing.xlsx']);
  });

  test('openMergeOutput success leaves the phase untouched', () async {
    repository.revealResult = const Success<void>(null);

    await viewModel().openMergeOutput('/tmp/out/report.xlsx');

    expect(uiState().phase, ConsolidatorPhase.empty);
    expect(repository.revealedPaths, ['/tmp/out/report.xlsx']);
  });
}
