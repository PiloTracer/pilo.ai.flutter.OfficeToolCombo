import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/repositories/backup_repository.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/scheduling/backup_scheduler.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_providers.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_ui_state.dart';

class BackupViewModel extends Notifier<BackupUiState> {
  BackupRepository get _repository => ref.read(backupRepositoryProvider);

  late final BackupScheduler _scheduler;
  final AppLogger _logger = AppLogger();
  Timer? _noticeTimer;

  @override
  BackupUiState build() {
    // Captured up front: Riverpod 3 forbids ref.read inside onDispose.
    final repository = _repository;
    _scheduler = BackupScheduler(
      readJob: () async => state.job,
      readLastRunAt: () async => (await repository.readLastRun())?.timestamp,
      isRunInProgress: () => state.isRunning || repository.isRunInProgress,
      startRun: () => _runBackup(BackupTrigger.scheduled),
      log: _logger.info,
    );
    ref.onDispose(() {
      _scheduler.stop();
      _noticeTimer?.cancel();
      // F6 — leaving the app mid-run cancels it; navigation away keeps it
      // running because this provider stays alive under the router.
      unawaited(repository.cancelActiveRun());
    });
    return const BackupUiState();
  }

  Future<void> loadInitialState() async {
    final loaded = await _repository.loadJob();
    if (!ref.mounted) return;
    await loaded.when(
      success: (job) async {
        final lastRun = await _repository.readLastRun();
        final archives = await _repository.readArchives();
        final online = await ref
            .read(backupConnectivityServiceProvider)
            .isOnline();
        if (!ref.mounted) return;
        // A killed process may have left partial archives behind (F6).
        final destination = job.destinationFolder;
        if (destination != null) {
          unawaited(_repository.cleanupStalePartials(destination));
        }
        state = state.copyWith(
          status: BackupScreenStatus.ready,
          job: job,
          lastRun: lastRun,
          archives: archives,
          isOffline: !online,
          clearError: true,
          clearLastRun: lastRun == null,
        );
        _scheduler.start();
      },
      failure: (failure) async {
        state = state.copyWith(
          status: BackupScreenStatus.error,
          errorCode: failure.message,
        );
      },
    );
  }

  /// SPEC §6 Error state — "Retry" reloads from the local store.
  Future<void> retry() async {
    state = state.copyWith(
      status: BackupScreenStatus.loading,
      clearError: true,
    );
    await loadInitialState();
  }

  Future<void> chooseSourceFolder() => _chooseFolder(isSource: true);

  Future<void> chooseDestinationFolder() => _chooseFolder(isSource: false);

  Future<void> _chooseFolder({required bool isSource}) async {
    final result = await _repository.pickFolder(
      dialogTitle: isSource
          ? 'Select source folder'
          : 'Select destination folder',
    );
    if (!ref.mounted) return;
    result.when(
      success: (path) {
        if (path == null) {
          // SPEC §11 — cancelled picker keeps the stored path; hint
          // dismisses after 3 s.
          _showNotice(BackupNotice.pickerCancelled, autoDismiss: true);
          return;
        }
        final updated = isSource
            ? state.job.copyWith(sourceFolder: path)
            : state.job.copyWith(destinationFolder: path);
        unawaited(_saveJob(updated));
      },
      failure: (_) {},
    );
  }

  Future<void> setDailyRunHour(int hour) {
    return _saveJob(state.job.copyWith(dailyRunHour: hour));
  }

  Future<void> setScheduleEnabled(bool enabled) {
    return _saveJob(state.job.copyWith(scheduleEnabled: enabled));
  }

  /// F1 — configuration is saved per-field on change; no Save button.
  Future<void> _saveJob(BackupJob job) async {
    final result = await _repository.saveJob(job);
    if (!ref.mounted) return;
    result.when(
      success: (_) {
        state = state.copyWith(job: job);
      },
      failure: (_) {},
    );
  }

  Future<void> runNow() => _runBackup(BackupTrigger.manual);

  Future<void> _runBackup(BackupTrigger trigger) async {
    if (state.isRunning) {
      return;
    }
    _noticeTimer?.cancel();
    state = state.copyWith(
      isRunning: true,
      clearProgress: true,
      clearNotice: true,
    );
    final result = await _repository.runBackup(
      job: state.job,
      trigger: trigger,
      onProgress: (progress) {
        if (ref.mounted) {
          state = state.copyWith(progress: progress);
        }
      },
    );
    if (!ref.mounted) return;
    final lastRun = await _repository.readLastRun();
    final archives = await _repository.readArchives();
    if (!ref.mounted) return;
    result.when(
      success: (_) {
        state = state.copyWith(
          isRunning: false,
          lastRun: lastRun,
          archives: archives,
          notice: BackupNotice.complete,
        );
      },
      failure: (_) {
        // Failure detail surfaces through the last-run record (SPEC §9).
        state = state.copyWith(
          isRunning: false,
          lastRun: lastRun,
          archives: archives,
        );
      },
    );
  }

  void dismissNotice() {
    _noticeTimer?.cancel();
    state = state.copyWith(clearNotice: true);
  }

  Future<void> revealArchive(String path) async {
    await _repository.revealArchive(path);
  }

  void _showNotice(BackupNotice notice, {bool autoDismiss = false}) {
    _noticeTimer?.cancel();
    state = state.copyWith(notice: notice);
    if (autoDismiss) {
      _noticeTimer = Timer(const Duration(seconds: 3), () {
        if (ref.mounted) {
          state = state.copyWith(clearNotice: true);
        }
      });
    }
  }
}

final backupViewModelProvider =
    NotifierProvider<BackupViewModel, BackupUiState>(BackupViewModel.new);
