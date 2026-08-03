import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_l10n.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_ui_state.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_view_model.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/widgets/field_mapping_editor.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/widgets/row_failure_list.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class DocumentFactoryView extends ConsumerStatefulWidget {
  const DocumentFactoryView({super.key});

  @override
  ConsumerState<DocumentFactoryView> createState() =>
      _DocumentFactoryViewState();
}

class _DocumentFactoryViewState extends ConsumerState<DocumentFactoryView> {
  var _loadedInitialState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedInitialState) {
      _loadedInitialState = true;
      unawaited(
        ref.read(documentFactoryViewModelProvider.notifier).loadInitialState(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentFactoryViewModelProvider);
    final viewModel = ref.read(documentFactoryViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return ToolShellScaffold(
      title: l10n.toolDocumentFactoryTitle,
      body: ListView(
        children: [
          Text(
            l10n.documentFactoryHeadline,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          spacing.gapSm,
          Text(
            l10n.documentFactoryDescription('{{Placeholder}}'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          spacing.gapLg,
          if (state.showInterruptedNotice) ...[
            _InterruptedNotice(message: l10n.documentFactoryInterrupted),
            spacing.gapMd,
          ],
          _TemplateCard(state: state, onChoose: viewModel.pickTemplate),
          spacing.gapMd,
          _DataSheetCard(state: state, onChoose: viewModel.pickDataSheet),
          spacing.gapMd,
          _MappingCard(state: state, viewModel: viewModel),
          spacing.gapMd,
          _OutputCard(state: state, onChoose: viewModel.pickOutputFolder),
          spacing.gapLg,
          _GenerateSection(state: state, onGenerate: viewModel.generate),
          spacing.gapLg,
          _StatusRegion(state: state, viewModel: viewModel),
          spacing.gapLg,
        ],
      ),
    );
  }
}

class _InterruptedNotice extends StatelessWidget {
  const _InterruptedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppStatusTone.warningBackgroundOf(context),
          borderRadius: radii.smAll,
        ),
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: AppStatusTone.warningForegroundOf(context),
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppStatusTone.warningForegroundOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Card(
      child: Padding(
        padding: spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            spacing.gapMd,
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.state, required this.onChoose});

  final DocumentFactoryUiState state;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _SectionCard(
      title: l10n.documentFactoryTemplateSection,
      children: [
        Text(
          state.templateName ?? l10n.documentFactoryNoTemplate,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (state.templatePath != null) ...[
          spacing.gapXs,
          Text(
            l10n.documentFactoryPlaceholderCount(state.placeholders.length),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        spacing.gapMd,
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: state.isGenerating ? null : onChoose,
            icon: const Icon(Icons.description_outlined),
            label: Text(l10n.documentFactoryChooseTemplate),
          ),
        ),
      ],
    );
  }
}

class _DataSheetCard extends StatelessWidget {
  const _DataSheetCard({required this.state, required this.onChoose});

  final DocumentFactoryUiState state;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _SectionCard(
      title: l10n.documentFactoryDataSection,
      children: [
        Text(
          state.dataSheetName ?? l10n.documentFactoryNoDataSheet,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (state.dataSheetPath != null) ...[
          spacing.gapXs,
          Text(
            '${l10n.documentFactorySheetRowCount(state.dataRowCount)} · '
            '${l10n.documentFactorySheetColumnCount(state.sheetHeaders.length)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        spacing.gapMd,
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: state.isGenerating ? null : onChoose,
            icon: const Icon(Icons.grid_on),
            label: Text(l10n.documentFactoryChooseDataSheet),
          ),
        ),
      ],
    );
  }
}

class _MappingCard extends StatelessWidget {
  const _MappingCard({required this.state, required this.viewModel});

  final DocumentFactoryUiState state;
  final DocumentFactoryViewModel viewModel;

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await viewModel.saveMapping();
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? l10n.documentFactoryMappingSaved
              : l10n.documentFactoryMappingSaveError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final hasInputs = state.templatePath != null && state.dataSheetPath != null;

    return _SectionCard(
      title: l10n.documentFactoryMappingSection,
      children: [
        if (!hasInputs)
          Text(
            l10n.documentFactoryMappingEmptyHint,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else if (state.placeholders.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppStatusTone.warningBackgroundOf(context),
              borderRadius: radii.smAll,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.sm),
              child: Text(
                l10n.documentFactoryZeroPlaceholders('{{FieldName}}'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppStatusTone.warningForegroundOf(context),
                ),
              ),
            ),
          )
        else ...[
          FieldMappingEditor(
            placeholders: state.placeholders,
            headers: state.sheetHeaders,
            mapping: state.mapping,
            onChanged: viewModel.updateMapping,
          ),
          spacing.gapMd,
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: state.canSaveMapping ? () => _save(context) : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.documentFactorySaveMapping),
            ),
          ),
        ],
      ],
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.state, required this.onChoose});

  final DocumentFactoryUiState state;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _SectionCard(
      title: l10n.documentFactoryOutputSection,
      children: [
        Text(
          state.outputDirName ?? l10n.documentFactoryNoOutput,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        spacing.gapMd,
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: state.isGenerating ? null : onChoose,
            icon: const Icon(Icons.drive_file_move_outline),
            label: Text(l10n.documentFactoryChooseOutputFolder),
          ),
        ),
      ],
    );
  }
}

class _GenerateSection extends StatelessWidget {
  const _GenerateSection({required this.state, required this.onGenerate});

  final DocumentFactoryUiState state;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: state.canGenerate ? onGenerate : null,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.documentFactoryGenerate),
        ),
        // SPEC R1 / A4 — inline hint while any placeholder is unmapped.
        if (state.placeholders.isNotEmpty && !state.isFullyMapped) ...[
          spacing.gapSm,
          Text(
            l10n.documentFactoryMapAllHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppStatusTone.warningForegroundOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _StatusRegion extends StatelessWidget {
  const _StatusRegion({required this.state, required this.viewModel});

  final DocumentFactoryUiState state;
  final DocumentFactoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (state.status) {
      DocumentFactoryStatus.generating => _ProgressBody(state: state),
      DocumentFactoryStatus.success => _OutcomeBody(
        state: state,
        isPartial: false,
        onOpenFolder: viewModel.openOutputFolder,
      ),
      DocumentFactoryStatus.partial => _OutcomeBody(
        state: state,
        isPartial: true,
        onOpenFolder: viewModel.openOutputFolder,
      ),
      DocumentFactoryStatus.error => StatePanel(
        icon: Icons.error_outline,
        iconColor: AppStatusTone.errorForegroundOf(context),
        iconBackgroundColor: AppStatusTone.errorBackgroundOf(context),
        title: l10n.documentFactoryErrorBatchTitle,
        message: l10n.documentFactoryFailureMessage(
          state.errorCode ?? DocumentFactoryFailureCodes.generation,
        ),
        action: FilledButton.icon(
          onPressed: viewModel.dismissError,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.documentFactoryTryAgain),
        ),
      ),
      DocumentFactoryStatus.idle => _IdleBody(
        state: state,
        onOpenFolder: viewModel.openOutputFolder,
      ),
    };
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.state});

  final DocumentFactoryUiState state;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final done = state.doneCount + state.failedCount + state.skippedCount;

    return Semantics(
      liveRegion: true,
      label: l10n.documentFactoryProgressAnnouncement(done, state.totalRows),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: state.totalRows > 0 ? state.progressFraction : null,
          ),
          spacing.gapMd,
          Text(
            l10n.documentFactoryProgress(done, state.totalRows),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (state.failedCount > 0) ...[
            spacing.gapSm,
            Text(
              l10n.documentFactoryRowsFailedCount(state.failedCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppStatusTone.errorForegroundOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.state, required this.onOpenFolder});

  final DocumentFactoryUiState state;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final lastJob = state.lastJob;
    if (lastJob == null ||
        lastJob.status == DocumentJobStatus.pending ||
        lastJob.status == DocumentJobStatus.running) {
      return const SizedBox.shrink();
    }
    // SPEC §4.4 — returning to the tool shows the last completed job.
    return _OutcomeBody(
      state: state,
      isPartial: lastJob.status == DocumentJobStatus.partial,
      job: lastJob,
      onOpenFolder: onOpenFolder,
    );
  }
}

class _OutcomeBody extends StatelessWidget {
  const _OutcomeBody({
    required this.state,
    required this.isPartial,
    required this.onOpenFolder,
    this.job,
  });

  final DocumentFactoryUiState state;
  final bool isPartial;
  final VoidCallback onOpenFolder;

  /// When null, the current state counts are shown.
  final DocumentJob? job;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final l10n = AppLocalizations.of(context);

    final done = job?.doneCount ?? state.doneCount;
    final failed = job?.failedCount ?? state.failedCount;
    final skipped = job?.skippedCount ?? state.skippedCount;
    final failures = job?.failures ?? state.lastJob?.failures;
    final folderName = job?.outputDirName ?? state.outputDirName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: spacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                            isPartial
                                ? l10n.documentFactoryPartialTitle
                                : l10n.documentFactorySuccessTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          spacing.gapXs,
                          Text(
                            isPartial
                                ? l10n.documentFactoryPartialCounts(
                                    done,
                                    failed,
                                  )
                                : l10n.documentFactorySuccessSummary(
                                    done,
                                    folderName,
                                  ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (skipped > 0) ...[
                            spacing.gapXs,
                            Text(
                              l10n.documentFactoryEmptyRowsSkipped(skipped),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                spacing.gapMd,
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onOpenFolder,
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.documentFactoryOpenOutputFolder),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isPartial && failures != null && failures.isNotEmpty) ...[
          spacing.gapMd,
          Card(
            child: Padding(
              padding: spacing.cardPadding,
              child: RowFailureList(failures: failures),
            ),
          ),
        ],
      ],
    );
  }
}
