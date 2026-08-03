import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';

enum BackupScreenStatus { loading, ready, error }

/// Transient inline notice on the backup screen (SPEC §4 F2, §11).
enum BackupNotice { complete, pickerCancelled }

/// UI state for the scheduled backup screen.
class BackupUiState {
  const BackupUiState({
    this.status = BackupScreenStatus.loading,
    this.job = const BackupJob(),
    this.lastRun,
    this.archives = const <BackupArchiveEntry>[],
    this.isOffline = false,
    this.isRunning = false,
    this.progress,
    this.notice,
    this.errorCode,
  });

  final BackupScreenStatus status;
  final BackupJob job;
  final BackupRunRecord? lastRun;

  /// Up to 10 recent successful archives, newest first (R8).
  final List<BackupArchiveEntry> archives;

  /// SPEC §10 — neutral offline note; all controls stay enabled.
  final bool isOffline;

  /// In-progress run overlay (SPEC §6): primary action disabled, label
  /// switches to the running copy.
  final bool isRunning;
  final BackupRunProgress? progress;
  final BackupNotice? notice;

  /// Stable BackupFailureCodes value for the screen-level error state.
  final String? errorCode;

  BackupUiState copyWith({
    BackupScreenStatus? status,
    BackupJob? job,
    BackupRunRecord? lastRun,
    List<BackupArchiveEntry>? archives,
    bool? isOffline,
    bool? isRunning,
    BackupRunProgress? progress,
    BackupNotice? notice,
    String? errorCode,
    bool clearLastRun = false,
    bool clearProgress = false,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return BackupUiState(
      status: status ?? this.status,
      job: job ?? this.job,
      lastRun: clearLastRun ? null : (lastRun ?? this.lastRun),
      archives: archives ?? this.archives,
      isOffline: isOffline ?? this.isOffline,
      isRunning: isRunning ?? this.isRunning,
      progress: clearProgress ? null : (progress ?? this.progress),
      notice: clearNotice ? null : (notice ?? this.notice),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}
