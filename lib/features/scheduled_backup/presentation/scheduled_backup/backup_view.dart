import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_l10n.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_ui_state.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_view_model.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class BackupView extends ConsumerStatefulWidget {
  const BackupView({super.key});

  @override
  ConsumerState<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends ConsumerState<BackupView> {
  var _loadedInitialState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedInitialState) {
      _loadedInitialState = true;
      unawaited(ref.read(backupViewModelProvider.notifier).loadInitialState());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupViewModelProvider);
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return ToolShellScaffold(
      title: l10n.toolScheduledBackupTitle,
      body: switch (state.status) {
        BackupScreenStatus.loading => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              spacing.gapMd,
              Text(l10n.backupLoading),
            ],
          ),
        ),
        BackupScreenStatus.error => StatePanel(
          icon: Icons.error_outline,
          iconColor: AppStatusTone.errorForegroundOf(context),
          iconBackgroundColor: AppStatusTone.errorBackgroundOf(context),
          title: l10n.backupLoadErrorTitle,
          message: l10n.backupLoadError,
          action: FilledButton.icon(
            onPressed: viewModel.retry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.backupRetry),
          ),
        ),
        BackupScreenStatus.ready => _ReadyBody(state: state),
      },
    );
  }
}

class _ReadyBody extends ConsumerWidget {
  const _ReadyBody({required this.state});

  final BackupUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final job = state.job;

    return ListView(
      children: [
        if (state.isOffline) ...[const _OfflineNote(), spacing.gapMd],
        if (state.notice != null) ...[
          _NoticeBanner(notice: state.notice!),
          spacing.gapMd,
        ],
        Text(
          l10n.backupSettingsSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        spacing.gapSm,
        _FolderRow(
          label: l10n.backupSourceFolderLabel,
          path: job.sourceFolder,
          placeholder: l10n.backupNoSourceSelected,
          chooseLabel: l10n.backupChooseSource,
          onChoose: viewModel.chooseSourceFolder,
        ),
        spacing.gapSm,
        _FolderRow(
          label: l10n.backupDestinationFolderLabel,
          path: job.destinationFolder,
          placeholder: l10n.backupNoDestinationSelected,
          chooseLabel: l10n.backupChooseDestination,
          onChoose: viewModel.chooseDestinationFolder,
        ),
        spacing.gapSm,
        _DailyHourRow(
          hour: job.dailyRunHour,
          onChanged: viewModel.setDailyRunHour,
        ),
        Row(
          children: [
            Expanded(child: Text(l10n.backupEnableSchedule)),
            Switch(
              value: job.scheduleEnabled,
              onChanged: viewModel.setScheduleEnabled,
            ),
          ],
        ),
        spacing.gapLg,
        _PrimaryAction(state: state),
        if (state.isRunning) ...[
          spacing.gapSm,
          LinearProgressIndicator(value: state.progress?.fraction),
          spacing.gapXs,
          if (state.progress != null)
            Text(
              l10n.backupProgressFiles(
                state.progress!.processedFiles,
                state.progress!.totalFiles,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
        spacing.gapLg,
        Text(
          l10n.backupLastRunSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        spacing.gapSm,
        _LastRunPanel(state: state),
        spacing.gapLg,
        Text(
          l10n.backupArchivesSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        spacing.gapSm,
        if (state.lastRun != null &&
            state.lastRun!.status != BackupRunStatus.succeeded &&
            state.archives.isNotEmpty) ...[
          _FailureBanner(messageCode: state.lastRun!.messageCode),
          spacing.gapSm,
        ],
        if (state.archives.isEmpty)
          StatePanel(
            icon: Icons.archive_outlined,
            title: l10n.backupNoArchivesYet,
            message: l10n.backupNoArchivesHelper,
          )
        else
          ...state.archives.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _ArchiveRow(entry: entry),
            ),
          ),
        spacing.gapLg,
      ],
    );
  }
}

class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.state});

  final BackupUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final canRun = !state.isRunning && state.job.isConfigured;

    // A9 — dominant full-width primary action, minimum 48 logical px.
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: canRun ? viewModel.runNow : null,
        icon: state.isRunning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.backup_outlined),
        label: Text(state.isRunning ? l10n.backupRunning : l10n.backupRunNow),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.label,
    required this.path,
    required this.placeholder,
    required this.chooseLabel,
    required this.onChoose,
  });

  final String label;
  final String? path;
  final String placeholder;
  final String chooseLabel;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final hasPath = path != null && path!.isNotEmpty;

    return Card(
      child: Padding(
        padding: spacing.cardPadding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  spacing.gapXs,
                  Text(
                    hasPath ? _displayName(path!) : placeholder,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasPath ? null : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasPath && _parentName(path!) != null)
                    Text(
                      _parentName(path!)!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            spacing.gapSm,
            OutlinedButton.icon(
              onPressed: onChoose,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: Text(chooseLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyHourRow extends StatelessWidget {
  const _DailyHourRow({required this.hour, required this.onChanged});

  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(child: Text(l10n.backupDailyRunHour)),
        DropdownButton<int>(
          value: hour,
          items: [
            for (var value = 0; value < 24; value++)
              DropdownMenuItem<int>(
                value: value,
                child: Text(_hourLabel(value)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _LastRunPanel extends ConsumerWidget {
  const _LastRunPanel({required this.state});

  final BackupUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final record = state.lastRun;

    if (record == null) {
      // Empty vs Partial (SPEC §6): nothing ran yet vs record missing while
      // config or archives exist.
      final text = state.archives.isEmpty && !state.job.isConfigured
          ? l10n.backupNoBackupsYet
          : l10n.backupLastRunUnknown;
      return Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final succeeded = record.status == BackupRunStatus.succeeded;
    final statusText = succeeded
        ? l10n.backupLastRunSucceeded
        : l10n.backupLastRunFailed;
    final statusColor = succeeded
        ? AppStatusTone.successForegroundOf(context)
        : AppStatusTone.errorForegroundOf(context);
    final timestamp = DateFormat.yMd(
      locale,
    ).add_jm().format(record.timestamp.toLocal());

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: statusColor),
          ),
          spacing.gapXs,
          Text(
            timestamp,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (!succeeded && record.messageCode.isNotEmpty) ...[
            spacing.gapXs,
            Text(
              l10n.backupFailureMessage(record.messageCode),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppStatusTone.errorForegroundOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchiveRow extends ConsumerWidget {
  const _ArchiveRow({required this.entry});

  final BackupArchiveEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMd(
      locale,
    ).add_jm().format(entry.finishedAt.toLocal());
    final size = _formatBytes(entry.bytes);

    return Semantics(
      label: l10n.backupArchiveRowSemantics(entry.name, date, size),
      child: Card(
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                Icons.archive_outlined,
                color: scheme.onSurfaceVariant,
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$date · $size',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.backupShowInFolder,
                icon: const Icon(Icons.folder_open_outlined),
                onPressed: () => viewModel.revealArchive(entry.path),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radii.smAll,
        ),
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: scheme.onSurfaceVariant,
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Text(
                  l10n.backupOfflineNote,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends ConsumerWidget {
  const _NoticeBanner({required this.notice});

  final BackupNotice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final spacing = context.spacing;
    final radii = context.radii;
    final l10n = AppLocalizations.of(context);
    final isComplete = notice == BackupNotice.complete;
    final foreground = isComplete
        ? AppStatusTone.successForegroundOf(context)
        : AppStatusTone.warningForegroundOf(context);
    final background = isComplete
        ? AppStatusTone.successBackgroundOf(context)
        : AppStatusTone.warningBackgroundOf(context);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: radii.smAll),
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle_outline : Icons.info_outline,
                color: foreground,
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Text(
                  isComplete
                      ? l10n.backupComplete
                      : l10n.backupFolderSelectionCancelled,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ),
              TextButton(
                onPressed: viewModel.dismissNotice,
                child: Text(l10n.backupDismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.messageCode});

  final String messageCode;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppStatusTone.errorBackgroundOf(context),
          borderRadius: radii.smAll,
        ),
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppStatusTone.errorForegroundOf(context),
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Text(
                  l10n.backupFailureMessage(messageCode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppStatusTone.errorForegroundOf(context),
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

/// NFR8 — basenames only in the UI, never full paths.
String _displayName(String path) {
  final segments = path.split(RegExp('[\\/]'))
    ..removeWhere((segment) => segment.isEmpty);
  return segments.isEmpty ? path : segments.last;
}

String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

String? _parentName(String path) {
  final segments = path.split(RegExp('[\\/]'))
    ..removeWhere((segment) => segment.isEmpty);
  if (segments.length < 2) {
    return null;
  }
  return segments[segments.length - 2];
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kib = bytes / 1024;
  if (kib < 1024) {
    return '${kib.toStringAsFixed(1)} KB';
  }
  final mib = kib / 1024;
  if (mib < 1024) {
    return '${mib.toStringAsFixed(1)} MB';
  }
  return '${(mib / 1024).toStringAsFixed(1)} GB';
}
