import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/repositories/backup_repository_impl.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/failures/backup_failure.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/services/archive_namer.dart';

void main() {
  late Directory temp;
  late Directory source;
  late Directory destination;
  late InMemoryBackupStore store;
  late BackupRepositoryImpl repository;

  BackupJob job({String id = 'job-a', String label = 'Job A'}) => BackupJob(
    id: id,
    label: label,
    sourceFolder: source.path,
    destinationFolder: destination.path,
  );

  String todayStamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  List<File> zipsInDestination() {
    return destination
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.zip'))
        .toList();
  }

  setUp(() {
    temp = Directory.systemTemp.createTempSync('backup_repo_test');
    source = Directory('${temp.path}/source')..createSync();
    destination = Directory('${temp.path}/destination')..createSync();
    store = InMemoryBackupStore();
    repository = BackupRepositoryImpl(store: store);
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('job CRUD', () {
    test('saveJob creates then updates; deleteJob removes', () async {
      final created = job();
      await repository.saveJob(created);
      await repository.saveJob(
        job(id: 'job-b', label: 'Job B').copyWith(enabled: false),
      );
      var jobs = (await repository.loadJobs() as Success<List<BackupJob>>).data;
      expect(jobs, hasLength(2));

      await repository.saveJob(created.copyWith(label: 'Renamed'));
      jobs = (await repository.loadJobs() as Success<List<BackupJob>>).data;
      expect(jobs, hasLength(2));
      expect(jobs.firstWhere((j) => j.id == 'job-a').label, 'Renamed');
      expect(jobs.firstWhere((j) => j.id == 'job-b').enabled, isFalse);

      await repository.deleteJob('job-a');
      jobs = (await repository.loadJobs() as Success<List<BackupJob>>).data;
      expect(jobs.single.id, 'job-b');
    });

    test('label validation: required and capped at 120 chars', () {
      expect(BackupJob.isValidLabel(''), isFalse);
      expect(BackupJob.isValidLabel('   '), isFalse);
      expect(BackupJob.isValidLabel('x' * 120), isTrue);
      expect(BackupJob.isValidLabel('x' * 121), isFalse);
    });
  });

  group('run validation', () {
    test(
      'A4: missing source fails with sourceMissing and a log entry',
      () async {
        final missing = BackupJob(
          id: 'job-a',
          label: 'Job A',
          sourceFolder: '${temp.path}/gone',
          destinationFolder: destination.path,
        );
        final result = await repository.runBackup(
          job: missing,
          trigger: BackupTrigger.manual,
        );

        expect(result, isA<Err<BackupRunLogEntry>>());
        expect(
          (result as Err<BackupRunLogEntry>).failure.message,
          BackupFailureCodes.sourceMissing,
        );
        final log = await store.readRunLog();
        expect(log, hasLength(1));
        expect(log.single.status, BackupRunStatus.failed);
        expect(log.single.messageCode, BackupFailureCodes.sourceMissing);
        expect(log.single.archiveName, isNull);
      },
    );

    test('unset source fails with sourceMissing', () async {
      final result = await repository.runBackup(
        job: BackupJob(
          id: 'job-a',
          label: 'Job A',
          destinationFolder: destination.path,
        ),
        trigger: BackupTrigger.manual,
      );
      expect(
        (result as Err<BackupRunLogEntry>).failure.message,
        BackupFailureCodes.sourceMissing,
      );
    });

    test(
      'A3: unwritable destination fails with destinationNotWritable',
      () async {
        final badDest = BackupJob(
          id: 'job-a',
          label: 'Job A',
          sourceFolder: source.path,
          destinationFolder: '${temp.path}/no/such/folder',
        );
        final result = await repository.runBackup(
          job: badDest,
          trigger: BackupTrigger.manual,
        );

        expect(
          (result as Err<BackupRunLogEntry>).failure.message,
          BackupFailureCodes.destinationNotWritable,
        );
        final log = await store.readRunLog();
        expect(log.single.status, BackupRunStatus.failed);
        expect(
          log.single.messageCode,
          BackupFailureCodes.destinationNotWritable,
        );
      },
    );

    test('destination pointing at a file is not writable', () async {
      final file = File('${temp.path}/a-file')..writeAsStringSync('x');
      final result = await repository.runBackup(
        job: BackupJob(
          id: 'job-a',
          label: 'Job A',
          sourceFolder: source.path,
          destinationFolder: file.path,
        ),
        trigger: BackupTrigger.manual,
      );
      expect(
        (result as Err<BackupRunLogEntry>).failure.message,
        BackupFailureCodes.destinationNotWritable,
      );
    });

    test('R4: identical source and destination is blocked', () async {
      final result = await repository.runBackup(
        job: BackupJob(
          id: 'job-a',
          label: 'Job A',
          sourceFolder: source.path,
          destinationFolder: source.path,
        ),
        trigger: BackupTrigger.manual,
      );

      expect(
        (result as Err<BackupRunLogEntry>).failure.message,
        BackupFailureCodes.sameFolders,
      );
      expect(zipsInDestination(), isEmpty);
    });

    test('R4: trailing slashes do not defeat the same-folder check', () async {
      final result = await repository.runBackup(
        job: BackupJob(
          id: 'job-a',
          label: 'Job A',
          sourceFolder: '${source.path}/',
          destinationFolder: source.path,
        ),
        trigger: BackupTrigger.manual,
      );
      expect(
        (result as Err<BackupRunLogEntry>).failure.message,
        BackupFailureCodes.sameFolders,
      );
    });
  });

  group('runs with temp directories', () {
    setUp(() {
      File('${source.path}/notes.txt').writeAsStringSync('hello backup');
      Directory('${source.path}/sub').createSync();
      File('${source.path}/sub/data.csv').writeAsStringSync('a,b\n1,2\n');
    });

    test(
      'A1: manual run creates a dated zip containing the source tree',
      () async {
        final result = await repository.runBackup(
          job: job(),
          trigger: BackupTrigger.manual,
        );

        expect(result, isA<Success<BackupRunLogEntry>>());
        final entry = (result as Success<BackupRunLogEntry>).data;
        expect(entry.status, BackupRunStatus.succeeded);
        expect(entry.jobLabel, 'Job A');

        final zips = zipsInDestination();
        expect(zips, hasLength(1));
        final name = zips.single.uri.pathSegments.last;
        expect(name, contains(todayStamp()));
        expect(name, ArchiveNamer.baseName(DateTime.now()));
        // The job label never leaks into the archive filename.
        expect(name, isNot(contains('Job A')));

        final archive = ZipDecoder().decodeBytes(zips.single.readAsBytesSync());
        final names = archive.files.map((file) => file.name).toSet();
        expect(names, containsAll(<String>{'notes.txt', 'sub/data.csv'}));

        // Unified run log: one successful entry with archive details.
        final log = await store.readRunLog();
        expect(log, hasLength(1));
        expect(log.single.archiveName, name);
        expect(log.single.archiveBytes, zips.single.lengthSync());
        expect(log.single.archivePath, isNotNull);
      },
    );

    test('A2: a yesterday-dated zip is untouched by today\'s run', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final priorName = ArchiveNamer.baseName(yesterday);
      final prior = File('${destination.path}/$priorName')
        ..writeAsBytesSync(const <int>[1, 2, 3, 4]);
      final priorBytes = prior.readAsBytesSync();
      final priorModified = prior.lastModifiedSync();

      final result = await repository.runBackup(
        job: job(),
        trigger: BackupTrigger.manual,
      );
      expect(result, isA<Success<BackupRunLogEntry>>());

      expect(prior.readAsBytesSync(), priorBytes);
      expect(prior.lastModifiedSync(), priorModified);
      // Today's run produced a distinct, today-dated file.
      final zips = zipsInDestination();
      expect(zips, hasLength(2));
      expect(
        zips.map((file) => file.uri.pathSegments.last),
        containsAll(<String>[priorName, ArchiveNamer.baseName(DateTime.now())]),
      );
    });

    test(
      'same-day re-run gets the -HHmmss suffix; first zip untouched',
      () async {
        final first = await repository.runBackup(
          job: job(),
          trigger: BackupTrigger.manual,
        );
        expect(first, isA<Success<BackupRunLogEntry>>());
        final firstName = (await store.readRunLog()).first.archiveName;

        final second = await repository.runBackup(
          job: job(),
          trigger: BackupTrigger.scheduled,
        );
        expect(second, isA<Success<BackupRunLogEntry>>());

        final log = await store.readRunLog();
        expect(log, hasLength(2));
        expect(log.first.archiveName, isNot(firstName));
        expect(
          log.first.archiveName,
          matches(
            RegExp(r'^OfficeToolCombo-backup-\d{4}-\d{2}-\d{2}-\d{6}.*\.zip$'),
          ),
        );
        expect(File('${destination.path}/$firstName').existsSync(), isTrue);
      },
    );

    test(
      'two jobs: manual run of job B logs an entry with job B\'s label',
      () async {
        await repository.runBackup(job: job(), trigger: BackupTrigger.manual);
        final jobB = job(id: 'job-b', label: 'Job B');
        final result = await repository.runBackup(
          job: jobB,
          trigger: BackupTrigger.manual,
        );
        expect(result, isA<Success<BackupRunLogEntry>>());

        final log = await store.readRunLog();
        expect(log, hasLength(2));
        // Newest first — job B's run leads and carries its label.
        expect(log.first.jobId, 'job-b');
        expect(log.first.jobLabel, 'Job B');
        expect(log.last.jobId, 'job-a');
        expect(log.last.jobLabel, 'Job A');
      },
    );

    test('run log is capped at 50 entries, newest kept', () async {
      final entries = List.generate(
        55,
        (i) => BackupRunLogEntry(
          jobId: 'job-a',
          jobLabel: 'Job A',
          finishedAt: DateTime.utc(2026, 8, 1).add(Duration(minutes: i)),
          status: BackupRunStatus.succeeded,
          archiveName: 'a$i.zip',
        ),
      );
      // Stored newest-first, as the repository maintains it.
      await store.writeRunLog(entries.reversed.toList());

      final result = await repository.runBackup(
        job: job(),
        trigger: BackupTrigger.manual,
      );
      expect(result, isA<Success<BackupRunLogEntry>>());

      final log = await repository.readRunLog();
      expect(log, hasLength(50));
      // The fresh entry leads; the oldest seeded entry dropped off.
      expect(log.first.archiveName, isNot('a0.zip'));
      expect(log.any((entry) => entry.archiveName == 'a0.zip'), isFalse);
      expect(log.any((entry) => entry.archiveName == 'a54.zip'), isTrue);
    });

    test(
      'lastRunAt reads the newest entry per job for scheduler due-ness',
      () async {
        final earlier = DateTime.utc(2026, 8, 1, 2);
        final later = DateTime.utc(2026, 8, 2, 2);
        await store.writeRunLog(<BackupRunLogEntry>[
          BackupRunLogEntry(
            jobId: 'job-b',
            jobLabel: 'Job B',
            finishedAt: later,
            status: BackupRunStatus.succeeded,
            archiveName: 'b.zip',
          ),
          BackupRunLogEntry(
            jobId: 'job-a',
            jobLabel: 'Job A',
            finishedAt: earlier,
            status: BackupRunStatus.failed,
            messageCode: BackupFailureCodes.run,
          ),
        ]);

        expect(await repository.lastRunAt('job-a'), earlier);
        expect(await repository.lastRunAt('job-b'), later);
        expect(await repository.lastRunAt('job-c'), isNull);
      },
    );

    test(
      'induced failure deletes the partial zip and logs without archive (R7)',
      () async {
        // A directory occupying today's archive name makes the final rename
        // fail after the zip content was written to the partial file.
        Directory(
          '${destination.path}/${ArchiveNamer.baseName(DateTime.now())}',
        ).createSync();

        final result = await repository.runBackup(
          job: job(),
          trigger: BackupTrigger.manual,
        );

        expect(result, isA<Err<BackupRunLogEntry>>());
        final log = await store.readRunLog();
        expect(log.single.status, BackupRunStatus.failed);
        expect(log.single.archiveName, isNull);

        // No partial file left behind (SPEC §9).
        final leftovers = destination
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith(ArchiveNamer.partialSuffix))
            .toList();
        expect(leftovers, isEmpty);
      },
    );

    test(
      'cancelActiveRun interrupts the run and records it as failed (F6)',
      () async {
        // Enough files that the run is still in flight after the first one.
        for (var i = 0; i < 100; i++) {
          File('${source.path}/file_$i.txt').writeAsStringSync('x' * 16384);
        }

        var cancelled = false;
        final result = await repository.runBackup(
          job: job(),
          trigger: BackupTrigger.manual,
          onProgress: (_) {
            // Cancel deterministically once the run is mid-flight.
            if (!cancelled) {
              cancelled = true;
              unawaited(repository.cancelActiveRun());
            }
          },
        );

        expect(result, isA<Err<BackupRunLogEntry>>());
        final log = await store.readRunLog();
        expect(log, isNotEmpty);
        expect(log.first.status, isNot(BackupRunStatus.succeeded));
        expect(log.first.messageCode, BackupFailureCodes.interrupted);
        expect(log.first.archiveName, isNull);
        expect(
          destination.listSync().whereType<File>().where(
            (f) => f.path.endsWith(ArchiveNamer.partialSuffix),
          ),
          isEmpty,
        );
      },
    );

    test('progress events report files processed out of total', () async {
      final events = <BackupRunProgress>[];
      final result = await repository.runBackup(
        job: job(),
        trigger: BackupTrigger.manual,
        onProgress: events.add,
      );

      expect(result, isA<Success<BackupRunLogEntry>>());
      expect(events, isNotEmpty);
      expect(events.last.processedFiles, events.last.totalFiles);
      expect(events.last.totalFiles, 2);
    });

    test('R5: a second trigger while running is rejected', () async {
      for (var i = 0; i < 50; i++) {
        File('${source.path}/big_$i.txt').writeAsStringSync('y' * 8192);
      }
      final first = repository.runBackup(
        job: job(),
        trigger: BackupTrigger.manual,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (!repository.isRunInProgress) {
        // Run finished faster than the check — nothing meaningful to assert.
        await first;
        return;
      }
      final second = await repository.runBackup(
        job: job(id: 'job-b', label: 'Job B'),
        trigger: BackupTrigger.scheduled,
      );
      expect(
        (second as Err<BackupRunLogEntry>).failure.message,
        BackupFailureCodes.busy,
      );
      await first;
    });
  });
}
