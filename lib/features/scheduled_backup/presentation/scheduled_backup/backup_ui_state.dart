import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';

enum BackupScreenStatus { loading, ready, error }

/// Transient inline notice on the backup screen (SPEC §4 F2, §11).
enum BackupNotice { complete, pickerCancelled }

/// UI state for the scheduled backup screen (v2: multiple labeled jobs +
/// unified run log).
class BackupUiState {
  const BackupUiState({
    this.status = BackupScreenStatus.loading,
    this.jobs = const <BackupJob>[],
    this.runLog = const <BackupRunLogEntry>[],
    this.isOffline = false,
    this.isRunning = false,
    this.runningJobId,
    this.progress,
    this.notice,
    this.errorCode,
  });

  final BackupScreenStatus status;
  final List<BackupJob> jobs;

  /// Unified run log across all jobs, newest first, capped at 50.
  final List<BackupRunLogEntry> runLog;

  /// SPEC §10 — neutral offline note; all controls stay enabled.
  final bool isOffline;

  /// In-progress run overlay (SPEC §6): run actions disabled, label
  /// switches to the running copy.
  final bool isRunning;

  /// Job whose run is in flight, when [isRunning].
  final String? runningJobId;
  final BackupRunProgress? progress;
  final BackupNotice? notice;

  /// Stable BackupFailureCodes value for the screen-level error state.
  final String? errorCode;

  BackupUiState copyWith({
    BackupScreenStatus? status,
    List<BackupJob>? jobs,
    List<BackupRunLogEntry>? runLog,
    bool? isOffline,
    bool? isRunning,
    String? runningJobId,
    BackupRunProgress? progress,
    BackupNotice? notice,
    String? errorCode,
    bool clearRunningJob = false,
    bool clearProgress = false,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return BackupUiState(
      status: status ?? this.status,
      jobs: jobs ?? this.jobs,
      runLog: runLog ?? this.runLog,
      isOffline: isOffline ?? this.isOffline,
      isRunning: isRunning ?? this.isRunning,
      runningJobId: clearRunningJob
          ? null
          : (runningJobId ?? this.runningJobId),
      progress: clearProgress ? null : (progress ?? this.progress),
      notice: clearNotice ? null : (notice ?? this.notice),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}
