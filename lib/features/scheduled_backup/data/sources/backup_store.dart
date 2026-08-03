import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';

/// Persists the backup job list and the unified run log across app restarts
/// (SharedPreferences-backed store for F5, v2: multiple labeled jobs).
abstract class BackupStore {
  Future<List<BackupJob>> readJobs();

  Future<void> writeJobs(List<BackupJob> jobs);

  /// Unified run log across all jobs, newest first.
  Future<List<BackupRunLogEntry>> readRunLog();

  Future<void> writeRunLog(List<BackupRunLogEntry> entries);
}

class InMemoryBackupStore implements BackupStore {
  List<BackupJob> jobs = <BackupJob>[];
  List<BackupRunLogEntry> runLog = <BackupRunLogEntry>[];

  @override
  Future<List<BackupJob>> readJobs() async => List<BackupJob>.from(jobs);

  @override
  Future<void> writeJobs(List<BackupJob> jobs) async {
    this.jobs = List<BackupJob>.from(jobs);
  }

  @override
  Future<List<BackupRunLogEntry>> readRunLog() async =>
      List<BackupRunLogEntry>.from(runLog);

  @override
  Future<void> writeRunLog(List<BackupRunLogEntry> entries) async {
    runLog = List<BackupRunLogEntry>.from(entries);
  }
}
