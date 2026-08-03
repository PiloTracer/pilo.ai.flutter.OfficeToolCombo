import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/shared_preferences_backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/failures/backup_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const jobs = <BackupJob>[
    BackupJob(
      id: 'job-1',
      label: 'Default backup',
      sourceFolder: '/home/user/docs',
      destinationFolder: '/mnt/backups',
      schedule: BackupSchedule.daily(hour: 14),
      enabled: false,
    ),
    BackupJob(
      id: 'job-2',
      label: 'Media archive',
      sourceFolder: '/home/user/media',
      destinationFolder: '/mnt/media-backups',
      schedule: BackupSchedule.weekly(weekday: DateTime.friday, hour: 20),
    ),
  ];
  final runLog = <BackupRunLogEntry>[
    BackupRunLogEntry(
      jobId: 'job-2',
      jobLabel: 'Media archive',
      finishedAt: DateTime.utc(2026, 8, 2, 14, 3),
      status: BackupRunStatus.failed,
      messageCode: BackupFailureCodes.sourceMissing,
    ),
    BackupRunLogEntry(
      jobId: 'job-1',
      jobLabel: 'Default backup',
      finishedAt: DateTime.utc(2026, 8, 2, 2, 0),
      status: BackupRunStatus.succeeded,
      archiveName: 'OfficeToolCombo-backup-2026-08-02.zip',
      archiveBytes: 2048,
      archivePath: '/mnt/backups/OfficeToolCombo-backup-2026-08-02.zip',
    ),
  ];

  void expectJobs(List<BackupJob> actual) {
    expect(actual, hasLength(jobs.length));
    for (var i = 0; i < jobs.length; i++) {
      expect(actual[i].id, jobs[i].id);
      expect(actual[i].label, jobs[i].label);
      expect(actual[i].sourceFolder, jobs[i].sourceFolder);
      expect(actual[i].destinationFolder, jobs[i].destinationFolder);
      expect(actual[i].schedule.kind, jobs[i].schedule.kind);
      expect(actual[i].schedule.hour, jobs[i].schedule.hour);
      expect(actual[i].schedule.weekday, jobs[i].schedule.weekday);
      expect(actual[i].enabled, jobs[i].enabled);
    }
  }

  void expectRunLog(List<BackupRunLogEntry> actual) {
    expect(actual, hasLength(runLog.length));
    for (var i = 0; i < runLog.length; i++) {
      expect(actual[i].jobId, runLog[i].jobId);
      expect(actual[i].jobLabel, runLog[i].jobLabel);
      expect(actual[i].status, runLog[i].status);
      expect(actual[i].finishedAt, runLog[i].finishedAt);
      expect(actual[i].messageCode, runLog[i].messageCode);
      expect(actual[i].archiveName, runLog[i].archiveName);
      expect(actual[i].archiveBytes, runLog[i].archiveBytes);
      expect(actual[i].archivePath, runLog[i].archivePath);
    }
  }

  group('InMemoryBackupStore', () {
    test('round-trips jobs and run log', () async {
      final store = InMemoryBackupStore();
      expect(await store.readJobs(), isEmpty);
      expect(await store.readRunLog(), isEmpty);

      await store.writeJobs(jobs);
      await store.writeRunLog(runLog);

      expectJobs(await store.readJobs());
      expectRunLog(await store.readRunLog());
    });
  });

  group('SharedPreferencesBackupStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('round-trips jobs and run log across instances', () async {
      final store = SharedPreferencesBackupStore();
      expect(await store.readJobs(), isEmpty);
      expect(await store.readRunLog(), isEmpty);

      await store.writeJobs(jobs);
      await store.writeRunLog(runLog);

      // A fresh instance proves values survive "relaunch".
      final reloaded = SharedPreferencesBackupStore();
      expectJobs(await reloaded.readJobs());
      expectRunLog(await reloaded.readRunLog());
    });

    test('invalid schedule values fall back to defaults on read', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'scheduled_backup_jobs':
            '[{"id":"j","label":"L","schedule":{"kind":"daily","hour":42}}]',
      });
      final store = SharedPreferencesBackupStore();
      final loaded = await store.readJobs();
      expect(loaded.single.schedule.hour, BackupSchedule.defaultDailyRunHour);
    });

    group('v1 → v2 migration', () {
      test(
        'old single config migrates into job #1 labeled "Default backup"',
        () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'scheduled_backup_job':
                '{"sourceFolder":"/src","destinationFolder":"/dst",'
                '"dailyRunHour":14,"scheduleEnabled":false}',
          });
          final store = SharedPreferencesBackupStore();
          final migrated = await store.readJobs();

          expect(migrated, hasLength(1));
          final job = migrated.single;
          expect(job.id, SharedPreferencesBackupStore.migratedJobId);
          expect(job.label, 'Default backup');
          expect(job.sourceFolder, '/src');
          expect(job.destinationFolder, '/dst');
          expect(job.schedule.kind, BackupScheduleKind.daily);
          expect(job.schedule.hour, 14);
          expect(job.enabled, isFalse);

          // Legacy keys are cleaned after migration.
          final preferences = await SharedPreferences.getInstance();
          expect(preferences.getString('scheduled_backup_job'), isNull);
          // A fresh instance reads the new model.
          expect(await SharedPreferencesBackupStore().readJobs(), hasLength(1));
        },
      );

      test('old archives and failed last-run fold into the run log', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'scheduled_backup_job':
              '{"sourceFolder":"/src","destinationFolder":"/dst",'
              '"dailyRunHour":2,"scheduleEnabled":true}',
          'scheduled_backup_last_run':
              '{"status":"failed","messageCode":"backup.source_missing",'
              '"timestamp":"2026-08-02T14:03:00.000Z"}',
          'scheduled_backup_archives':
              '[{"name":"OfficeToolCombo-backup-2026-08-01.zip",'
              '"path":"/dst/OfficeToolCombo-backup-2026-08-01.zip",'
              '"bytes":1024,"finishedAt":"2026-08-01T02:00:00.000Z"}]',
        });
        final store = SharedPreferencesBackupStore();
        await store.readJobs();
        final log = await store.readRunLog();

        expect(log, hasLength(2));
        // Newest first: the failed last-run record leads.
        expect(log.first.status, BackupRunStatus.failed);
        expect(log.first.messageCode, BackupFailureCodes.sourceMissing);
        expect(log.first.jobLabel, 'Default backup');
        expect(log.first.archiveName, isNull);
        expect(log.last.status, BackupRunStatus.succeeded);
        expect(log.last.archiveName, 'OfficeToolCombo-backup-2026-08-01.zip');
        expect(log.last.archiveBytes, 1024);
      });

      test('no legacy keys means no migration and an empty store', () async {
        final store = SharedPreferencesBackupStore();
        expect(await store.readJobs(), isEmpty);
        expect(await store.readRunLog(), isEmpty);
      });
    });
  });
}
