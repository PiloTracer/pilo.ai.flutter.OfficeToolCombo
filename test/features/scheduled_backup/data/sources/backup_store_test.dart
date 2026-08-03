import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/shared_preferences_backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/failures/backup_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const job = BackupJob(
    sourceFolder: '/home/user/docs',
    destinationFolder: '/mnt/backups',
    dailyRunHour: 14,
    scheduleEnabled: false,
  );
  final record = BackupRunRecord(
    status: BackupRunStatus.failed,
    messageCode: BackupFailureCodes.sourceMissing,
    timestamp: DateTime.utc(2026, 8, 2, 14, 3),
  );
  final archives = <BackupArchiveEntry>[
    BackupArchiveEntry(
      name: 'OfficeToolCombo-backup-2026-08-02.zip',
      path: '/mnt/backups/OfficeToolCombo-backup-2026-08-02.zip',
      bytes: 2048,
      finishedAt: DateTime.utc(2026, 8, 2, 2, 0),
    ),
    BackupArchiveEntry(
      name: 'OfficeToolCombo-backup-2026-08-01.zip',
      path: '/mnt/backups/OfficeToolCombo-backup-2026-08-01.zip',
      bytes: 1024,
      finishedAt: DateTime.utc(2026, 8, 1, 2, 0),
    ),
  ];

  void expectJob(BackupJob actual) {
    expect(actual.sourceFolder, job.sourceFolder);
    expect(actual.destinationFolder, job.destinationFolder);
    expect(actual.dailyRunHour, job.dailyRunHour);
    expect(actual.scheduleEnabled, job.scheduleEnabled);
  }

  void expectRecord(BackupRunRecord actual) {
    expect(actual.status, record.status);
    expect(actual.messageCode, record.messageCode);
    expect(actual.timestamp, record.timestamp);
  }

  void expectArchives(List<BackupArchiveEntry> actual) {
    expect(actual, hasLength(archives.length));
    for (var i = 0; i < archives.length; i++) {
      expect(actual[i].name, archives[i].name);
      expect(actual[i].path, archives[i].path);
      expect(actual[i].bytes, archives[i].bytes);
      expect(actual[i].finishedAt, archives[i].finishedAt);
    }
  }

  group('InMemoryBackupStore', () {
    test('round-trips job, last run and archives', () async {
      final store = InMemoryBackupStore();
      expect(await store.readJob(), isNull);
      expect(await store.readLastRun(), isNull);
      expect(await store.readArchives(), isEmpty);

      await store.writeJob(job);
      await store.writeLastRun(record);
      await store.writeArchives(archives);

      expectJob((await store.readJob())!);
      expectRecord((await store.readLastRun())!);
      expectArchives(await store.readArchives());
    });
  });

  group('SharedPreferencesBackupStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('round-trips job, last run and archives', () async {
      final store = SharedPreferencesBackupStore();
      expect(await store.readJob(), isNull);
      expect(await store.readLastRun(), isNull);
      expect(await store.readArchives(), isEmpty);

      await store.writeJob(job);
      await store.writeLastRun(record);
      await store.writeArchives(archives);

      // A fresh instance proves values survive "relaunch".
      final reloaded = SharedPreferencesBackupStore();
      expectJob((await reloaded.readJob())!);
      expectRecord((await reloaded.readLastRun())!);
      expectArchives(await reloaded.readArchives());
    });

    test('invalid hour falls back to the default on read', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'scheduled_backup_job': '{"dailyRunHour": 42, "scheduleEnabled": true}',
      });
      final store = SharedPreferencesBackupStore();
      final loaded = await store.readJob();
      expect(loaded!.dailyRunHour, BackupJob.defaultDailyRunHour);
    });
  });
}
