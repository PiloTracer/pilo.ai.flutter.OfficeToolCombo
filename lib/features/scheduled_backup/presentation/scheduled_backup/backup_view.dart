import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
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
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return ListView(
      children: [
        if (state.isOffline) ...[const _OfflineNote(), spacing.gapMd],
        if (state.notice != null) ...[
          _NoticeBanner(notice: state.notice!),
          spacing.gapMd,
        ],
        Text(
          l10n.backupJobsSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        spacing.gapSm,
        if (state.jobs.isEmpty)
          StatePanel(
            icon: Icons.backup_outlined,
            title: l10n.backupNoJobsYet,
            message: l10n.backupNoJobsHelper,
          )
        else
          ...state.jobs.map(
            (job) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _JobRow(job: job, state: state),
            ),
          ),
        spacing.gapSm,
        // Dominant primary action: create a new labeled backup job.
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: state.isRunning
                ? null
                : () => _openJobEditor(context, ref, null),
            icon: const Icon(Icons.add),
            label: Text(l10n.backupAddJob),
          ),
        ),
        if (state.isRunning) ...[
          spacing.gapMd,
          LinearProgressIndicator(value: state.progress?.fraction),
          spacing.gapXs,
          Text(
            state.progress != null
                ? l10n.backupProgressFiles(
                    state.progress!.processedFiles,
                    state.progress!.totalFiles,
                  )
                : l10n.backupRunning,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        spacing.gapLg,
        Text(
          l10n.backupRunLogSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        spacing.gapSm,
        if (state.runLog.isEmpty)
          StatePanel(
            icon: Icons.history,
            title: l10n.backupNoRunsYet,
            message: l10n.backupNoRunsHelper,
          )
        else
          ...state.runLog.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _RunLogRow(entry: entry),
            ),
          ),
        spacing.gapLg,
      ],
    );
  }
}

class _JobRow extends ConsumerWidget {
  const _JobRow({required this.job, required this.state});

  final BackupJob job;
  final BackupUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isThisJobRunning = state.isRunning && state.runningJobId == job.id;

    return Card(
      child: Padding(
        padding: spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      spacing.gapXs,
                      Text(
                        l10n.backupScheduleSummary(job.schedule),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.backupEditJobTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: state.isRunning
                      ? null
                      : () => _openJobEditor(context, ref, job),
                ),
                IconButton(
                  tooltip: l10n.backupDeleteJobTooltip,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.isRunning
                      ? null
                      : () => _confirmDelete(context, ref, job),
                ),
                Switch(
                  value: job.enabled,
                  onChanged: state.isRunning
                      ? null
                      : (enabled) => viewModel.setJobEnabled(job, enabled),
                ),
              ],
            ),
            spacing.gapSm,
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: state.isRunning || !job.isConfigured
                    ? null
                    : () => viewModel.runNow(job),
                icon: isThisJobRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup_outlined, size: 18),
                label: Text(
                  isThisJobRunning ? l10n.backupRunning : l10n.backupRunNow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunLogRow extends ConsumerWidget {
  const _RunLogRow({required this.entry});

  final BackupRunLogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(backupViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final succeeded = entry.status == BackupRunStatus.succeeded;
    final date = DateFormat.yMd(
      locale,
    ).add_jm().format(entry.finishedAt.toLocal());
    final statusText = switch (entry.status) {
      BackupRunStatus.succeeded => l10n.backupRunStatusSucceeded,
      BackupRunStatus.failed => l10n.backupRunStatusFailed,
      BackupRunStatus.cancelled => l10n.backupRunStatusCancelled,
    };
    final statusColor = succeeded
        ? AppStatusTone.successForegroundOf(context)
        : AppStatusTone.errorForegroundOf(context);

    return Semantics(
      label: l10n.backupRunLogRowSemantics(entry.jobLabel, statusText, date),
      child: Card(
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                succeeded ? Icons.archive_outlined : Icons.error_outline,
                color: succeeded ? scheme.onSurfaceVariant : statusColor,
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.jobLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$statusText · $date',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: statusColor),
                    ),
                    // NFR8 — archive basename only, never the full path.
                    if (succeeded && entry.archiveName != null)
                      Text(
                        '${entry.archiveName} · ${_formatBytes(entry.archiveBytes ?? 0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (!succeeded && entry.messageCode.isNotEmpty)
                      Text(
                        l10n.backupFailureMessage(entry.messageCode),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: statusColor),
                      ),
                  ],
                ),
              ),
              if (succeeded && entry.archivePath != null)
                IconButton(
                  tooltip: l10n.backupShowInFolder,
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: () => viewModel.revealArchive(entry.archivePath!),
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

Future<void> _openJobEditor(
  BuildContext context,
  WidgetRef ref,
  BackupJob? existing,
) async {
  final viewModel = ref.read(backupViewModelProvider.notifier);
  final edited = await showDialog<BackupJob>(
    context: context,
    builder: (dialogContext) => _JobEditorDialog(
      existing: existing,
      newJobId: viewModel.newJobId,
      onPickFolder: (isSource) => viewModel.pickFolder(isSource: isSource),
    ),
  );
  if (edited != null) {
    await viewModel.saveJob(edited);
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  BackupJob job,
) async {
  final viewModel = ref.read(backupViewModelProvider.notifier);
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.backupDeleteJobTitle),
      content: Text(l10n.backupDeleteJobMessage(job.label)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.backupDeleteConfirm),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await viewModel.deleteJob(job.id);
  }
}

/// Create/edit dialog for one labeled backup job.
class _JobEditorDialog extends StatefulWidget {
  const _JobEditorDialog({
    required this.existing,
    required this.newJobId,
    required this.onPickFolder,
  });

  final BackupJob? existing;
  final String Function() newJobId;
  final Future<String?> Function(bool isSource) onPickFolder;

  @override
  State<_JobEditorDialog> createState() => _JobEditorDialogState();
}

class _JobEditorDialogState extends State<_JobEditorDialog> {
  late final TextEditingController _labelController;
  late String? _sourceFolder;
  late String? _destinationFolder;
  late BackupScheduleKind _kind;
  late int _everyHours;
  late int _hour;
  late int _weekday;
  late int _dayOfMonth;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _sourceFolder = existing?.sourceFolder;
    _destinationFolder = existing?.destinationFolder;
    _kind = existing?.schedule.kind ?? BackupScheduleKind.daily;
    _everyHours =
        existing?.schedule.everyHours ?? BackupSchedule.defaultEveryHours;
    _hour = existing?.schedule.hour ?? BackupSchedule.defaultDailyRunHour;
    _weekday = existing?.schedule.weekday ?? DateTime.monday;
    _dayOfMonth = existing?.schedule.dayOfMonth ?? 1;
    _enabled = existing?.enabled ?? true;
    _labelController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _labelValid => BackupJob.isValidLabel(_labelController.text);

  BackupSchedule get _schedule => switch (_kind) {
    BackupScheduleKind.hourly => BackupSchedule.hourly(everyHours: _everyHours),
    BackupScheduleKind.daily => BackupSchedule.daily(hour: _hour),
    BackupScheduleKind.weekly => BackupSchedule.weekly(
      weekday: _weekday,
      hour: _hour,
    ),
    BackupScheduleKind.monthly => BackupSchedule.monthly(
      dayOfMonth: _dayOfMonth,
      hour: _hour,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isNew = widget.existing == null;

    return AlertDialog(
      scrollable: true,
      title: Text(
        isNew ? l10n.backupJobDialogTitleNew : l10n.backupJobDialogTitleEdit,
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              maxLength: BackupJob.maxLabelLength,
              decoration: InputDecoration(
                labelText: l10n.backupJobLabelField,
                errorText: _labelValid ? null : l10n.backupJobLabelInvalid,
              ),
            ),
            spacing.gapSm,
            _DialogFolderRow(
              label: l10n.backupSourceFolderLabel,
              path: _sourceFolder,
              placeholder: l10n.backupNoSourceSelected,
              chooseLabel: l10n.backupChooseSource,
              onChoose: () async {
                final path = await widget.onPickFolder(true);
                if (path != null) {
                  setState(() => _sourceFolder = path);
                }
              },
            ),
            spacing.gapSm,
            _DialogFolderRow(
              label: l10n.backupDestinationFolderLabel,
              path: _destinationFolder,
              placeholder: l10n.backupNoDestinationSelected,
              chooseLabel: l10n.backupChooseDestination,
              onChoose: () async {
                final path = await widget.onPickFolder(false);
                if (path != null) {
                  setState(() => _destinationFolder = path);
                }
              },
            ),
            spacing.gapMd,
            Row(
              children: [
                Expanded(child: Text(l10n.backupScheduleKindLabel)),
                DropdownButton<BackupScheduleKind>(
                  value: _kind,
                  items: [
                    DropdownMenuItem(
                      value: BackupScheduleKind.hourly,
                      child: Text(l10n.backupScheduleHourly),
                    ),
                    DropdownMenuItem(
                      value: BackupScheduleKind.daily,
                      child: Text(l10n.backupScheduleDaily),
                    ),
                    DropdownMenuItem(
                      value: BackupScheduleKind.weekly,
                      child: Text(l10n.backupScheduleWeekly),
                    ),
                    DropdownMenuItem(
                      value: BackupScheduleKind.monthly,
                      child: Text(l10n.backupScheduleMonthly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _kind = value);
                    }
                  },
                ),
              ],
            ),
            if (_kind == BackupScheduleKind.hourly)
              Row(
                children: [
                  Expanded(child: Text(l10n.backupIntervalLabel)),
                  DropdownButton<int>(
                    value: _everyHours,
                    items: [
                      for (final option in BackupSchedule.hourlyOptions)
                        DropdownMenuItem<int>(
                          value: option,
                          child: Text(l10n.backupScheduleEveryHours(option)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _everyHours = value);
                      }
                    },
                  ),
                ],
              ),
            if (_kind == BackupScheduleKind.weekly)
              Row(
                children: [
                  Expanded(child: Text(l10n.backupWeekdayLabel)),
                  DropdownButton<int>(
                    value: _weekday,
                    items: [
                      for (
                        var day = DateTime.monday;
                        day <= DateTime.sunday;
                        day++
                      )
                        DropdownMenuItem<int>(
                          value: day,
                          child: Text(l10n.backupWeekdayName(day)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _weekday = value);
                      }
                    },
                  ),
                ],
              ),
            if (_kind == BackupScheduleKind.monthly)
              Row(
                children: [
                  Expanded(child: Text(l10n.backupDayOfMonthLabel)),
                  DropdownButton<int>(
                    value: _dayOfMonth,
                    items: [
                      for (var day = 1; day <= 31; day++)
                        DropdownMenuItem<int>(
                          value: day,
                          child: Text(day.toString()),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _dayOfMonth = value);
                      }
                    },
                  ),
                ],
              ),
            if (_kind != BackupScheduleKind.hourly)
              Row(
                children: [
                  Expanded(child: Text(l10n.backupHourLabel)),
                  DropdownButton<int>(
                    value: _hour,
                    items: [
                      for (var value = 0; value < 24; value++)
                        DropdownMenuItem<int>(
                          value: value,
                          child: Text(_hourLabel(value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _hour = value);
                      }
                    },
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(child: Text(l10n.backupEnabledLabel)),
                Switch(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ],
            ),
            if (!_labelValid)
              Text(
                l10n.backupJobLabelInvalid,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(
          onPressed: _labelValid
              ? () => Navigator.of(context).pop(
                  BackupJob(
                    id: widget.existing?.id ?? widget.newJobId(),
                    label: _labelController.text.trim(),
                    sourceFolder: _sourceFolder,
                    destinationFolder: _destinationFolder,
                    schedule: _schedule,
                    enabled: _enabled,
                  ),
                )
              : null,
          child: Text(l10n.backupSave),
        ),
      ],
    );
  }
}

class _DialogFolderRow extends StatelessWidget {
  const _DialogFolderRow({
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
    final scheme = Theme.of(context).colorScheme;
    final hasPath = path != null && path!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text(
                hasPath ? _displayName(path!) : placeholder,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasPath ? null : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onChoose,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: Text(chooseLabel),
        ),
      ],
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
