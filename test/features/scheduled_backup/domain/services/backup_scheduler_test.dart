import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/scheduling/backup_scheduler.dart';

void main() {
  const dailyJob = BackupJob(
    id: 'job-a',
    label: 'Daily docs',
    sourceFolder: '/src',
    destinationFolder: '/dst',
    schedule: BackupSchedule.daily(hour: 2),
  );

  /// Advances [current] while the scheduler ticks every 5 ms against the
  /// fake clock.
  Future<void> wait([int millis = 60]) =>
      Future<void>.delayed(Duration(milliseconds: millis));

  test(
    'A5: advancing the fake clock to the hour triggers exactly one run',
    () async {
      var now = DateTime(2026, 8, 2, 1, 59, 50);
      final lastRuns = <String, DateTime?>{};
      var runs = 0;
      final scheduler = BackupScheduler(
        checkInterval: const Duration(milliseconds: 5),
        now: () => now,
        readJobs: () async => const [dailyJob],
        readLastRunAt: (jobId) async => lastRuns[jobId],
        isRunInProgress: () => false,
        startRun: (job) async {
          runs += 1;
          lastRuns[job.id] = now;
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

  test('no run when the job is disabled', () async {
    final now = DateTime(2026, 8, 2, 3, 0);
    var runs = 0;
    final scheduler = BackupScheduler(
      checkInterval: const Duration(milliseconds: 5),
      now: () => now,
      readJobs: () async => [dailyJob.copyWith(enabled: false)],
      readLastRunAt: (jobId) async => null,
      isRunInProgress: () => false,
      startRun: (job) async => runs += 1,
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
      readJobs: () async => const [BackupJob(id: 'j', label: 'Empty')],
      readLastRunAt: (jobId) async => null,
      isRunInProgress: () => false,
      startRun: (job) async => runs += 1,
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
        readJobs: () async => const [dailyJob],
        readLastRunAt: (jobId) async => lastRunAt,
        isRunInProgress: () => false,
        startRun: (job) async {
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
        readJobs: () async => const [dailyJob],
        readLastRunAt: (jobId) async => null,
        isRunInProgress: () => true,
        startRun: (job) async => runs += 1,
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
        readJobs: () async => const [dailyJob],
        readLastRunAt: (jobId) async => null,
        isRunInProgress: () => false,
        startRun: (job) async => runs += 1,
      )..start();
      addTearDown(scheduler.stop);

      await wait(30);
      expect(runs, 1);
    },
  );

  test('with two due jobs, both fire sequentially, one at a time', () async {
    final now = DateTime(2026, 8, 3, 9, 15); // a Monday
    const other = BackupJob(
      id: 'job-b',
      label: 'Weekly media',
      sourceFolder: '/src2',
      destinationFolder: '/dst2',
      schedule: BackupSchedule.weekly(weekday: DateTime.monday, hour: 9),
    );
    final started = <String>[];
    var concurrent = 0;
    var maxConcurrent = 0;
    final scheduler = BackupScheduler(
      checkInterval: const Duration(milliseconds: 5),
      now: () => now,
      readJobs: () async => const [dailyJob, other],
      readLastRunAt: (jobId) async => null,
      isRunInProgress: () => concurrent > 0,
      startRun: (job) async {
        concurrent += 1;
        maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
        started.add(job.id);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        concurrent -= 1;
      },
    )..start();
    addTearDown(scheduler.stop);

    await wait();
    expect(started, containsAll(<String>['job-a', 'job-b']));
    expect(maxConcurrent, 1, reason: 'R5 — at most one run at a time');
  });

  group('isDueHourly', () {
    test('first run (no prior run) is due immediately', () {
      expect(
        BackupScheduler.isDueHourly(
          lastRunAt: null,
          now: DateTime(2026, 8, 2, 10, 0),
          everyHours: 4,
        ),
        isTrue,
      );
    });

    test('not due before the interval elapses', () {
      expect(
        BackupScheduler.isDueHourly(
          lastRunAt: DateTime(2026, 8, 2, 7, 0),
          now: DateTime(2026, 8, 2, 10, 59),
          everyHours: 4,
        ),
        isFalse,
      );
    });

    test('due exactly at the interval boundary', () {
      expect(
        BackupScheduler.isDueHourly(
          lastRunAt: DateTime(2026, 8, 2, 6, 0),
          now: DateTime(2026, 8, 2, 10, 0),
          everyHours: 4,
        ),
        isTrue,
      );
    });
  });

  group('isDueDaily', () {
    test('before the hour is not due', () {
      expect(
        BackupScheduler.isDueDaily(
          now: DateTime(2026, 8, 2, 1, 59),
          hour: 2,
          lastRunAt: null,
        ),
        isFalse,
      );
    });

    test('at the hour with no prior run is due', () {
      expect(
        BackupScheduler.isDueDaily(
          now: DateTime(2026, 8, 2, 2, 0),
          hour: 2,
          lastRunAt: null,
        ),
        isTrue,
      );
    });

    test('same-day prior run is not due', () {
      expect(
        BackupScheduler.isDueDaily(
          now: DateTime(2026, 8, 2, 23, 0),
          hour: 2,
          lastRunAt: DateTime(2026, 8, 2, 2, 5).toUtc(),
        ),
        isFalse,
      );
    });
  });

  group('isDueWeekly', () {
    // 2026-08-03 is a Monday.
    test('due on the matching weekday at the hour', () {
      expect(
        BackupScheduler.isDueWeekly(
          now: DateTime(2026, 8, 3, 2, 0),
          weekday: DateTime.monday,
          hour: 2,
          lastRunAt: null,
        ),
        isTrue,
      );
    });

    test('not due on a different weekday', () {
      expect(
        BackupScheduler.isDueWeekly(
          now: DateTime(2026, 8, 4, 9, 0),
          weekday: DateTime.monday,
          hour: 2,
          lastRunAt: null,
        ),
        isFalse,
      );
    });

    test('not due before the hour on the matching weekday', () {
      expect(
        BackupScheduler.isDueWeekly(
          now: DateTime(2026, 8, 3, 1, 59),
          weekday: DateTime.monday,
          hour: 2,
          lastRunAt: null,
        ),
        isFalse,
      );
    });

    test('not due twice on the same day', () {
      expect(
        BackupScheduler.isDueWeekly(
          now: DateTime(2026, 8, 3, 20, 0),
          weekday: DateTime.monday,
          hour: 2,
          lastRunAt: DateTime(2026, 8, 3, 2, 5).toUtc(),
        ),
        isFalse,
      );
    });
  });

  group('isDueMonthly', () {
    test('due on the matching day of month at the hour', () {
      expect(
        BackupScheduler.isDueMonthly(
          now: DateTime(2026, 8, 15, 3, 0),
          dayOfMonth: 15,
          hour: 2,
          lastRunAt: null,
        ),
        isTrue,
      );
    });

    test('not due on a different day of month', () {
      expect(
        BackupScheduler.isDueMonthly(
          now: DateTime(2026, 8, 16, 3, 0),
          dayOfMonth: 15,
          hour: 2,
          lastRunAt: null,
        ),
        isFalse,
      );
    });

    test('day 31 clamps to Feb 28 in a short month', () {
      expect(
        BackupScheduler.isDueMonthly(
          now: DateTime(2026, 2, 28, 2, 0),
          dayOfMonth: 31,
          hour: 2,
          lastRunAt: null,
        ),
        isTrue,
      );
      expect(
        BackupScheduler.isDueMonthly(
          now: DateTime(2026, 2, 27, 23, 0),
          dayOfMonth: 31,
          hour: 2,
          lastRunAt: null,
        ),
        isFalse,
        reason: 'Feb 27 must not fire for day 31',
      );
    });

    test('day 31 fires on the 31st in long months', () {
      expect(
        BackupScheduler.isDueMonthly(
          now: DateTime(2026, 3, 31, 2, 0),
          dayOfMonth: 31,
          hour: 2,
          lastRunAt: DateTime(2026, 2, 28, 2, 5).toUtc(),
        ),
        isTrue,
      );
    });

    test('not due before the hour on the clamped day', () {
      expect(
        BackupScheduler.isDueMonthly(
          now: DateTime(2026, 2, 28, 1, 0),
          dayOfMonth: 31,
          hour: 2,
          lastRunAt: null,
        ),
        isFalse,
      );
    });
  });
}
