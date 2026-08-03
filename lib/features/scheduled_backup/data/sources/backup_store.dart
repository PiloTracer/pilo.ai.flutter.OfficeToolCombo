import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';

/// Persists the backup job config, last-run record, and recent archives
/// across app restarts (SPEC §7 — SharedPreferences-backed store for F5).
abstract class BackupStore {
  Future<BackupJob?> readJob();

  Future<void> writeJob(BackupJob job);

  Future<BackupRunRecord?> readLastRun();

  Future<void> writeLastRun(BackupRunRecord record);

  Future<List<BackupArchiveEntry>> readArchives();

  Future<void> writeArchives(List<BackupArchiveEntry> archives);
}

class InMemoryBackupStore implements BackupStore {
  BackupJob? job;
  BackupRunRecord? lastRun;
  List<BackupArchiveEntry> archives = <BackupArchiveEntry>[];

  @override
  Future<BackupJob?> readJob() async => job;

  @override
  Future<void> writeJob(BackupJob job) async {
    this.job = job;
  }

  @override
  Future<BackupRunRecord?> readLastRun() async => lastRun;

  @override
  Future<void> writeLastRun(BackupRunRecord record) async {
    lastRun = record;
  }

  @override
  Future<List<BackupArchiveEntry>> readArchives() async =>
      List<BackupArchiveEntry>.from(archives);

  @override
  Future<void> writeArchives(List<BackupArchiveEntry> archives) async {
    this.archives = List<BackupArchiveEntry>.from(archives);
  }
}
