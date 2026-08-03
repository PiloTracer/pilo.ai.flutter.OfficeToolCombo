import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/scheduling/backup_scheduler.dart';

void main() {
  const job = BackupJob(
    sourceFolder: '/src',
    destinationFolder: '/dst',
    dailyRunHour: 2,
  );

  /// Advances [current] while the scheduler ticks every 5 ms against the
  /// fake clock.
  Future<void> wait([int millis = 60]) =>
      Future<void>.delayed(Duration(milliseconds: millis));

  test(
    'A5: advancing the fake clock to the hour triggers exactly one run',
    () async {
      var now = DateTime(2026, 8, 2, 1, 59, 50);
      DateTime? lastRunAt;
      var runs = 0;
      final scheduler = BackupScheduler(
        checkInterval: const Duration(milliseconds: 5),
        now: () => now,
        readJob: () async => job,
        readLastRunAt: () async => lastRunAt,
        isRunInProgress: () => false,
        startRun: () async {
          runs += 1;
          lastRunAt = now;
        },
      )..start();
      addTearDown(scheduler.stop);

      await wait();
      expect(runs, 0, reason: 'before 02:00 no run is due');

      now = DateTime(2026, 8, 2, 2, 0, 1);
      await wait();
      expect(runs, 1, reason: 'the hour triggers one run');

      await wait();
      expect(runs, 1, reason: 'no double-fire on the same day');
    },
  );

  test('no run when the schedule is disabled', () async {
    final now = DateTime(2026, 8, 2, 3, 0);
    var runs = 0;
    final scheduler = BackupScheduler(
      checkInterval: const Duration(milliseconds: 5),
      now: () => now,
      readJob: () async => job.copyWith(scheduleEnabled: false),
      readLastRunAt: () async => null,
      isRunInProgress: () => false,
      startRun: () async => runs += 1,
    )..start();
    addTearDown(scheduler.stop);

    await wait();
    expect(runs, 0);
  });

  test('no run when folders are not configured yet', () async {
    final now = DateTime(2026, 8, 2, 3, 0);
    var runs = 0;
    final scheduler = BackupScheduler(
      checkInterval: const Duration(milliseconds: 5),
      now: () => now,
      readJob: () async => const BackupJob(),
      readLastRunAt: () async => null,
      isRunInProgress: () => false,
      startRun: () async => runs += 1,
    )..start();
    addTearDown(scheduler.stop);

    await wait();
    expect(runs, 0);
  });

  test(
    'no run when a run already happened today; fires again next day',
    () async {
      var now = DateTime(2026, 8, 2, 14, 0);
      var lastRunAt = DateTime(2026, 8, 2, 2, 0).toUtc();
      var runs = 0;
      final scheduler = BackupScheduler(
        checkInterval: const Duration(milliseconds: 5),
        now: () => now,
        readJob: () async => job,
        readLastRunAt: () async => lastRunAt,
        isRunInProgress: () => false,
        startRun: () async {
          runs += 1;
          lastRunAt = now.toUtc();
        },
      )..start();
      addTearDown(scheduler.stop);

      await wait();
      expect(runs, 0);

      now = DateTime(2026, 8, 3, 2, 30);
      await wait();
      expect(runs, 1);
    },
  );

  test(
    'F3/R5: due run is skipped and logged while a run is in progress',
    () async {
      final now = DateTime(2026, 8, 2, 2, 30);
      final logs = <String>[];
      var runs = 0;
      final scheduler = BackupScheduler(
        checkInterval: const Duration(milliseconds: 5),
        now: () => now,
        readJob: () async => job,
        readLastRunAt: () async => null,
        isRunInProgress: () => true,
        startRun: () async => runs += 1,
        log: logs.add,
      )..start();
      addTearDown(scheduler.stop);

      await wait();
      expect(runs, 0);
      expect(logs.any((entry) => entry.contains('run_in_progress')), isTrue);
    },
  );

  test(
    'app launched after the hour runs today\'s backup immediately',
    () async {
      final now = DateTime(2026, 8, 2, 9, 15);
      var runs = 0;
      final scheduler = BackupScheduler(
        checkInterval: const Duration(minutes: 1),
        now: () => now,
        readJob: () async => job,
        readLastRunAt: () async => null,
        isRunInProgress: () => false,
        startRun: () async => runs += 1,
      )..start();
      addTearDown(scheduler.stop);

      await wait(30);
      expect(runs, 1);
    },
  );

  group('isDue', () {
    test('before the hour is not due', () {
      expect(
        BackupScheduler.isDue(
          now: DateTime(2026, 8, 2, 1, 59),
          dailyRunHour: 2,
          lastRunAt: null,
        ),
        isFalse,
      );
    });

    test('at the hour with no prior run is due', () {
      expect(
        BackupScheduler.isDue(
          now: DateTime(2026, 8, 2, 2, 0),
          dailyRunHour: 2,
          lastRunAt: null,
        ),
        isTrue,
      );
    });

    test('same-day prior run is not due', () {
      expect(
        BackupScheduler.isDue(
          now: DateTime(2026, 8, 2, 23, 0),
          dailyRunHour: 2,
          lastRunAt: DateTime(2026, 8, 2, 2, 5).toUtc(),
        ),
        isFalse,
      );
    });
  });
}
