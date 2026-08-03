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
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final isLoading = state.phase == ConsolidatorPhase.loading;

    return ToolShellScaffold(
      title: l10n.consolidatorTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.consolidatorHeadline,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          spacing.gapSm,
          Text(
            l10n.consolidatorDescription,
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
            label: Text(l10n.consolidatorChooseAndMerge),
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
    final l10n = AppLocalizations.of(context);
    final usesDefault = outputFolderPath == null || outputFolderPath!.isEmpty;

    return Card(
      child: Padding(
        padding: spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.consolidatorOutputFolderTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            spacing.gapSm,
            Text(
              usesDefault
                  ? l10n.consolidatorOutputFolderDefault
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
                  label: Text(l10n.consolidatorChooseOutputFolder),
                ),
                if (!usesDefault)
                  TextButton(
                    onPressed: isLoading ? null : onUseSourceFolder,
                    child: Text(l10n.consolidatorUseSourceFolder),
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
    final l10n = AppLocalizations.of(context);
    return switch (state.phase) {
      ConsolidatorPhase.loading => _LoadingBody(progress: state.progress),
      ConsolidatorPhase.empty when state.selectedFolderPath != null =>
        StatePanel(
          icon: Icons.inbox_outlined,
          title: l10n.consolidatorNoSpreadsheetsTitle,
          message: l10n.consolidatorNoSpreadsheetsMessage,
          action: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.consolidatorChooseAnotherFolder),
          ),
        ),
      ConsolidatorPhase.empty => const SizedBox.shrink(),
      ConsolidatorPhase.partial => _SuccessBody(
        state: state,
        title: l10n.consolidatorPartialTitle,
        isPartial: true,
      ),
      ConsolidatorPhase.error => StatePanel(
        icon: Icons.error_outline,
        iconColor: AppStatusTone.errorForegroundOf(context),
        iconBackgroundColor: AppStatusTone.errorBackgroundOf(context),
        title: l10n.consolidatorErrorTitle,
        message: state.errorMessage ?? l10n.consolidatorErrorFallback,
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.consolidatorTryAgain),
        ),
      ),
      ConsolidatorPhase.offline => _SuccessBody(
        state: state,
        title: l10n.consolidatorSuccessTitle,
        isPartial: false,
      ),
      ConsolidatorPhase.success => _SuccessBody(
        state: state,
        title: l10n.consolidatorSuccessTitle,
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
    final l10n = AppLocalizations.of(context);
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
                  ? l10n.consolidatorMergingProgress(percent)
                  : l10n.consolidatorPreparing,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            spacing.gapSm,
            Text(
              l10n.consolidatorMergingHint,
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
    final l10n = AppLocalizations.of(context);
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
                            ? l10n.consolidatorSavedInOutput
                            : l10n.consolidatorSavedAs(state.outputFileName!),
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
            l10n.consolidatorFailuresTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          spacing.gapSm,
          Text(
            l10n.consolidatorFailuresMessage,
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
