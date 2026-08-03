import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';

abstract class BackupRepository {
  /// Loads the single job configuration; defaults (hour 2, schedule on,
  /// folders unset) when none was stored yet.
  Future<Result<BackupJob>> loadJob();

  /// Per-field save (F1 — no Save button; called on each change).
  Future<Result<void>> saveJob(BackupJob job);

  Future<BackupRunRecord?> readLastRun();

  /// Up to 10 recent successful archives, newest first (R8).
  Future<List<BackupArchiveEntry>> readArchives();

  /// OS folder picker; `Success(null)` when the user cancels (SPEC §11 —
  /// stored path unchanged).
  Future<Result<String?>> pickFolder({required String dialogTitle});

  bool get isRunInProgress;

  /// Validates, then zips the whole source tree into the destination in an
  /// isolate (R1). Failed runs update the last-run record but never add an
  /// archive entry (R7); the partial zip is removed (SPEC §9).
  Future<Result<BackupRunRecord>> runBackup({
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
