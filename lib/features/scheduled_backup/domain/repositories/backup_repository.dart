import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';

abstract class BackupRepository {
  /// Loads all configured backup jobs; empty when none were stored yet.
  Future<Result<List<BackupJob>>> loadJobs();

  /// Creates or updates a job (upsert by [BackupJob.id]).
  Future<Result<void>> saveJob(BackupJob job);

  /// Removes a job; archives on disk are never deleted.
  Future<Result<void>> deleteJob(String jobId);

  /// Unified run log across all jobs, newest first, capped at 50 entries.
  Future<List<BackupRunLogEntry>> readRunLog();

  /// Latest run timestamp for [jobId] (any status) — scheduler due-ness.
  Future<DateTime?> lastRunAt(String jobId);

  /// OS folder picker; `Success(null)` when the user cancels (SPEC §11 —
  /// stored path unchanged).
  Future<Result<String?>> pickFolder({required String dialogTitle});

  bool get isRunInProgress;

  /// Validates, then zips the whole source tree into the destination in an
  /// isolate (R1). Every run — success, failure, or cancellation — appends
  /// one entry to the unified run log; only successes carry an archive name
  /// (R7); the partial zip is removed on failure (SPEC §9).
  Future<Result<BackupRunLogEntry>> runBackup({
    required BackupJob job,
    required BackupTrigger trigger,
    void Function(BackupRunProgress progress)? onProgress,
  });

  /// F6 — app close during a run: signals the worker to stop, removes the
  /// partial archive, and records the run as failed/interrupted.
  Future<void> cancelActiveRun();

  /// Deletes stale `.partial` archives left by a killed process.
  Future<void> cleanupStalePartials(String destinationPath);

  Future<Result<void>> revealArchive(String path);
}
