import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/result/result.dart';
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
      readJobs: () async => state.jobs,
      readLastRunAt: repository.lastRunAt,
      isRunInProgress: () => state.isRunning || repository.isRunInProgress,
      startRun: (job) => _runBackup(job, BackupTrigger.scheduled),
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
    final loaded = await _repository.loadJobs();
    if (!ref.mounted) return;
    await loaded.when(
      success: (jobs) async {
        final runLog = await _repository.readRunLog();
        final online = await ref
            .read(backupConnectivityServiceProvider)
            .isOnline();
        if (!ref.mounted) return;
        // A killed process may have left partial archives behind (F6).
        for (final job in jobs) {
          final destination = job.destinationFolder;
          if (destination != null) {
            unawaited(_repository.cleanupStalePartials(destination));
          }
        }
        state = state.copyWith(
          status: BackupScreenStatus.ready,
          jobs: jobs,
          runLog: runLog,
          isOffline: !online,
          clearError: true,
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

  /// Unique id for a job created from the editor dialog.
  String newJobId() => 'job-${DateTime.now().microsecondsSinceEpoch}';

  /// Create or update a job from the editor dialog.
  Future<Result<void>> saveJob(BackupJob job) async {
    final result = await _repository.saveJob(job);
    if (!ref.mounted) return result;
    await result.when(
      success: (_) async {
        final jobs = await _repository.loadJobs();
        if (!ref.mounted) return;
        jobs.when(
          success: (list) => state = state.copyWith(jobs: list),
          failure: (_) {},
        );
      },
      failure: (_) async {},
    );
    return result;
  }

  Future<void> deleteJob(String jobId) async {
    final result = await _repository.deleteJob(jobId);
    if (!ref.mounted) return;
    result.when(
      success: (_) {
        state = state.copyWith(
          jobs: state.jobs.where((job) => job.id != jobId).toList(),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> setJobEnabled(BackupJob job, bool enabled) async {
    await saveJob(job.copyWith(enabled: enabled));
  }

  Future<void> runNow(BackupJob job) => _runBackup(job, BackupTrigger.manual);

  /// OS folder picker for the editor dialog; `Success(null)` on cancel
  /// (SPEC §11 — hint dismisses after 3 s).
  Future<String?> pickFolder({required bool isSource}) async {
    final result = await _repository.pickFolder(
      dialogTitle: isSource
          ? 'Select source folder'
          : 'Select destination folder',
    );
    if (!ref.mounted) return null;
    return result.when(
      success: (path) {
        if (path == null) {
          _showNotice(BackupNotice.pickerCancelled, autoDismiss: true);
        }
        return path;
      },
      failure: (_) => null,
    );
  }

  Future<void> _runBackup(BackupJob job, BackupTrigger trigger) async {
    if (state.isRunning) {
      return;
    }
    _noticeTimer?.cancel();
    state = state.copyWith(
      isRunning: true,
      runningJobId: job.id,
      clearProgress: true,
      clearNotice: true,
    );
    final result = await _repository.runBackup(
      job: job,
      trigger: trigger,
      onProgress: (progress) {
        if (ref.mounted) {
          state = state.copyWith(progress: progress);
        }
      },
    );
    if (!ref.mounted) return;
    final runLog = await _repository.readRunLog();
    if (!ref.mounted) return;
    result.when(
      success: (_) {
        state = state.copyWith(
          isRunning: false,
          clearRunningJob: true,
          runLog: runLog,
          notice: BackupNotice.complete,
        );
      },
      failure: (_) {
        // Failure detail surfaces through the run log entry (SPEC §9).
        state = state.copyWith(
          isRunning: false,
          clearRunningJob: true,
          runLog: runLog,
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
