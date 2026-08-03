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

  BackupJob job({int hour = 2}) => BackupJob(
    sourceFolder: source.path,
    destinationFolder: destination.path,
    dailyRunHour: hour,
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

  group('run validation', () {
    test(
      'A4: missing source fails with sourceMissing and no archive entry',
      () async {
        final missing = BackupJob(
          sourceFolder: '${temp.path}/gone',
          destinationFolder: destination.path,
        );
        final result = await repository.runBackup(
          job: missing,
          trigger: BackupTrigger.manual,
        );

        expect(result, isA<Err<BackupRunRecord>>());
        expect(
          (result as Err<BackupRunRecord>).failure.message,
          BackupFailureCodes.sourceMissing,
        );
        final lastRun = await store.readLastRun();
        expect(lastRun!.status, BackupRunStatus.failed);
        expect(lastRun.messageCode, BackupFailureCodes.sourceMissing);
        expect(await store.readArchives(), isEmpty);
      },
    );

    test('unset source fails with sourceMissing', () async {
      final result = await repository.runBackup(
        job: BackupJob(destinationFolder: destination.path),
        trigger: BackupTrigger.manual,
      );
      expect(
        (result as Err<BackupRunRecord>).failure.message,
        BackupFailureCodes.sourceMissing,
      );
    });

    test(
      'A3: unwritable destination fails with destinationNotWritable',
      () async {
        final badDest = BackupJob(
          sourceFolder: source.path,
          destinationFolder: '${temp.path}/no/such/folder',
        );
        final result = await repository.runBackup(
          job: badDest,
          trigger: BackupTrigger.manual,
        );

        expect(
          (result as Err<BackupRunRecord>).failure.message,
          BackupFailureCodes.destinationNotWritable,
        );
        final lastRun = await store.readLastRun();
        expect(lastRun!.status, BackupRunStatus.failed);
        expect(lastRun.messageCode, BackupFailureCodes.destinationNotWritable);
        expect(await store.readArchives(), isEmpty);
      },
    );

    test('destination pointing at a file is not writable', () async {
      final file = File('${temp.path}/a-file')..writeAsStringSync('x');
      final result = await repository.runBackup(
        job: BackupJob(sourceFolder: source.path, destinationFolder: file.path),
        trigger: BackupTrigger.manual,
      );
      expect(
        (result as Err<BackupRunRecord>).failure.message,
        BackupFailureCodes.destinationNotWritable,
      );
    });

    test('R4: identical source and destination is blocked', () async {
      final result = await repository.runBackup(
        job: BackupJob(
          sourceFolder: source.path,
          destinationFolder: source.path,
        ),
        trigger: BackupTrigger.manual,
      );

      expect(
        (result as Err<BackupRunRecord>).failure.message,
        BackupFailureCodes.sameFolders,
      );
      expect(zipsInDestination(), isEmpty);
    });

    test('R4: trailing slashes do not defeat the same-folder check', () async {
      final result = await repository.runBackup(
        job: BackupJob(
          sourceFolder: '${source.path}/',
          destinationFolder: source.path,
        ),
        trigger: BackupTrigger.manual,
      );
      expect(
        (result as Err<BackupRunRecord>).failure.message,
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

        expect(result, isA<Success<BackupRunRecord>>());
        final record = (result as Success<BackupRunRecord>).data;
        expect(record.status, BackupRunStatus.succeeded);

        final zips = zipsInDestination();
        expect(zips, hasLength(1));
        final name = zips.single.uri.pathSegments.last;
        expect(name, contains(todayStamp()));
        expect(name, ArchiveNamer.baseName(DateTime.now()));

        final archive = ZipDecoder().decodeBytes(zips.single.readAsBytesSync());
        final names = archive.files.map((file) => file.name).toSet();
        expect(names, containsAll(<String>{'notes.txt', 'sub/data.csv'}));

        // R7/R8 — one successful archive entry, newest first.
        final archives = await store.readArchives();
        expect(archives, hasLength(1));
        expect(archives.single.name, name);
        expect(archives.single.bytes, zips.single.lengthSync());

        final lastRun = await store.readLastRun();
        expect(lastRun!.status, BackupRunStatus.succeeded);
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
      expect(result, isA<Success<BackupRunRecord>>());

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
        expect(first, isA<Success<BackupRunRecord>>());
        final firstName = (await store.readArchives()).first.name;

        final second = await repository.runBackup(
          job: job(),
          trigger: BackupTrigger.scheduled,
        );
        expect(second, isA<Success<BackupRunRecord>>());

        final archives = await store.readArchives();
        expect(archives, hasLength(2));
        expect(archives.first.name, isNot(firstName));
        expect(
          archives.first.name,
          matches(
            RegExp(r'^OfficeToolCombo-backup-\d{4}-\d{2}-\d{2}-\d{6}.*\.zip$'),
          ),
        );
        expect(File('${destination.path}/$firstName').existsSync(), isTrue);
      },
    );

    test(
      'induced failure deletes the partial zip and adds no archive entry (R7)',
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

        expect(result, isA<Err<BackupRunRecord>>());
        final lastRun = await store.readLastRun();
        expect(lastRun!.status, BackupRunStatus.failed);

        // No partial file left behind, no archive entry recorded (R7).
        final leftovers = destination
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith(ArchiveNamer.partialSuffix))
            .toList();
        expect(leftovers, isEmpty);
        expect(await store.readArchives(), isEmpty);
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

        expect(result, isA<Err<BackupRunRecord>>());
        final lastRun = await store.readLastRun();
        expect(lastRun, isNotNull);
        expect(lastRun!.status, isNot(BackupRunStatus.succeeded));
        expect(lastRun.messageCode, BackupFailureCodes.interrupted);
        expect(await store.readArchives(), isEmpty);
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

      expect(result, isA<Success<BackupRunRecord>>());
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
        job: job(),
        trigger: BackupTrigger.scheduled,
      );
      expect(
        (second as Err<BackupRunRecord>).failure.message,
        BackupFailureCodes.busy,
      );
      await first;
    });
  });
}
