import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_ui_state.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view_model.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/widgets/failure_list.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/widgets/merge_history_list.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';

class ConsolidatorView extends ConsumerStatefulWidget {
  const ConsolidatorView({super.key});

  @override
  ConsumerState<ConsolidatorView> createState() => _ConsolidatorViewState();
}

class _ConsolidatorViewState extends ConsumerState<ConsolidatorView> {
  var _loadedInitialState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedInitialState) {
      _loadedInitialState = true;
      unawaited(
        ref.read(consolidatorViewModelProvider.notifier).loadInitialState(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consolidatorViewModelProvider);
    final viewModel = ref.read(consolidatorViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final isLoading = state.phase == ConsolidatorPhase.loading;

    return ToolShellScaffold(
      title: 'Report consolidator',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Merge Excel reports',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          spacing.gapSm,
          Text(
            'Pick a folder of .xlsx files. The app combines them into one '
            'workbook and lists any files that could not be read.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          spacing.gapLg,
          _OutputFolderCard(
            outputFolderPath: state.outputFolderPath,
            isLoading: isLoading,
            onChooseOutputFolder: viewModel.pickOutputFolder,
            onUseSourceFolder: viewModel.useSourceFolderForOutput,
          ),
          spacing.gapLg,
          FilledButton.icon(
            onPressed: isLoading ? null : viewModel.pickFolderAndMerge,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose folder and merge'),
          ),
          spacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: 2,
                  child: _StateBody(
                    state: state,
                    onRetry: viewModel.pickFolderAndMerge,
                  ),
                ),
                spacing.gapMd,
                Expanded(
                  flex: 3,
                  child: MergeHistoryList(
                    entries: state.mergeHistory,
                    onOpen: viewModel.openMergeOutput,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputFolderCard extends StatelessWidget {
  const _OutputFolderCard({
    required this.outputFolderPath,
    required this.isLoading,
    required this.onChooseOutputFolder,
    required this.onUseSourceFolder,
  });

  final String? outputFolderPath;
  final bool isLoading;
  final VoidCallback onChooseOutputFolder;
  final VoidCallback onUseSourceFolder;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final usesDefault = outputFolderPath == null || outputFolderPath!.isEmpty;

    return Card(
      child: Padding(
        padding: spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Output folder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            spacing.gapSm,
            Text(
              usesDefault
                  ? 'Same as the source folder (default)'
                  : outputFolderPath!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            spacing.gapMd,
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onChooseOutputFolder,
                  icon: const Icon(Icons.drive_file_move_outline),
                  label: const Text('Choose output folder'),
                ),
                if (!usesDefault)
                  TextButton(
                    onPressed: isLoading ? null : onUseSourceFolder,
                    child: const Text('Use source folder'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({required this.state, required this.onRetry});

  final ConsolidatorUiState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      ConsolidatorPhase.loading => _LoadingBody(progress: state.progress),
      ConsolidatorPhase.empty when state.selectedFolderPath != null =>
        StatePanel(
          icon: Icons.inbox_outlined,
          title: 'No spreadsheets found',
          message:
              'That folder did not contain any .xlsx files. '
              'Try a different folder with Excel reports inside.',
          action: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose another folder'),
          ),
        ),
      ConsolidatorPhase.empty => const SizedBox.shrink(),
      ConsolidatorPhase.partial => _SuccessBody(
        state: state,
        title: 'Merged with some failures',
        isPartial: true,
      ),
      ConsolidatorPhase.error => StatePanel(
        icon: Icons.error_outline,
        iconColor: AppStatusTone.errorForegroundOf(context),
        iconBackgroundColor: AppStatusTone.errorBackgroundOf(context),
        title: 'Merge could not finish',
        message:
            state.errorMessage ??
            'Something went wrong while reading the files. '
                'Check that the folder is readable and try again.',
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ),
      ConsolidatorPhase.offline => _SuccessBody(
        state: state,
        title: 'Merge complete',
        isPartial: false,
      ),
      ConsolidatorPhase.success => _SuccessBody(
        state: state,
        title: 'Merge complete',
        isPartial: false,
      ),
    };
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final percent = (progress * 100).round().clamp(0, 100);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress > 0 ? progress : null),
            spacing.gapMd,
            Text(
              progress > 0
                  ? 'Merging spreadsheets… $percent%'
                  : 'Preparing merge…',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            spacing.gapSm,
            Text(
              'Large folders may take a minute. You can keep this window open.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.state,
    required this.title,
    required this.isPartial,
  });

  final ConsolidatorUiState state;
  final String title;
  final bool isPartial;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final scheme = Theme.of(context).colorScheme;
    final failures =
        state.lastBatch?.files
            .where((f) => f.parseStatus == SpreadsheetParseStatus.failed)
            .toList(growable: false) ??
        const <SpreadsheetFileResult>[];

    return ListView(
      primary: false,
      children: [
        Card(
          child: Padding(
            padding: spacing.cardPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isPartial
                        ? AppStatusTone.warningBackgroundOf(context)
                        : AppStatusTone.successBackgroundOf(context),
                    borderRadius: radii.smAll,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.sm),
                    child: Icon(
                      isPartial
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                      color: isPartial
                          ? AppStatusTone.warningForegroundOf(context)
                          : AppStatusTone.successForegroundOf(context),
                      semanticLabel: '',
                    ),
                  ),
                ),
                spacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      spacing.gapXs,
                      Text(
                        state.outputFileName == null
                            ? 'Output saved in the chosen output folder.'
                            : 'Saved as ${state.outputFileName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (failures.isNotEmpty) ...[
          spacing.gapLg,
          Text(
            'Files that need attention',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          spacing.gapSm,
          Text(
            'These files were skipped or could not be read. '
            'Fix or remove them and run merge again.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          spacing.gapMd,
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.sm),
              child: FailureList(failures: failures),
            ),
          ),
        ],
      ],
    );
  }
}
