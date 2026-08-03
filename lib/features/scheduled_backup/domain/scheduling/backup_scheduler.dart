import 'dart:async';

import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';

/// Fires scheduled runs for all configured jobs while the app process is
/// running (R5/R6, SPEC §4 F3).
///
/// A periodic check (default every 30 s, so drift stays ≤ 1 minute — A5)
/// evaluates due-ness per job from its schedule kind and its last run
/// timestamp. Clock, interval, and all side effects are injected so tests
/// control time and observe runs directly. At most one run executes at a
/// time globally (R5); due jobs found in one tick fire sequentially.
class BackupScheduler {
  BackupScheduler({
    this.checkInterval = const Duration(seconds: 30),
    DateTime Function()? now,
    required this.readJobs,
    required this.readLastRunAt,
    required this.isRunInProgress,
    required this.startRun,
    this.log,
  }) : _now = now ?? DateTime.now;

  final Duration checkInterval;
  final DateTime Function() _now;
  final Future<List<BackupJob>> Function() readJobs;
  final Future<DateTime?> Function(String jobId) readLastRunAt;
  final bool Function() isRunInProgress;
  final Future<void> Function(BackupJob job) startRun;
  final void Function(String message)? log;

  Timer? _timer;
  bool _ticking = false;

  /// Starts the periodic check and performs one immediate check, so an app
  /// launched after a due time still runs the missed job today (R6).
  void start() {
    stop();
    _timer = Timer.periodic(checkInterval, (_) => _handleTimer());
    _handleTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleTimer() {
    if (_ticking) {
      return;
    }
    _ticking = true;
    unawaited(Future<void>.sync(_tick).whenComplete(() => _ticking = false));
  }

  Future<void> _tick() async {
    final jobs = await readJobs();
    final now = _now();
    for (final job in jobs) {
      // Disabled or unconfigured jobs never fire.
      if (!job.enabled || !job.isConfigured) {
        continue;
      }
      final lastRunAt = await readLastRunAt(job.id);
      if (!isDueFor(job.schedule, lastRunAt: lastRunAt, now: now)) {
        continue;
      }
      // R5 — a run is already in progress: skip the scheduled run and log
      // it (SPEC §4 F3).
      if (isRunInProgress()) {
        log?.call(
          'backup.scheduled_skipped jobId=${job.id} reason=run_in_progress',
        );
        continue;
      }
      await startRun(job);
    }
  }

  /// Dispatches to the due check for [schedule]'s kind. [lastRunAt] is the
  /// job's latest run timestamp (any status); null means it never ran.
  static bool isDueFor(
    BackupSchedule schedule, {
    required DateTime? lastRunAt,
    required DateTime now,
  }) {
    return switch (schedule.kind) {
      BackupScheduleKind.hourly => isDueHourly(
        lastRunAt: lastRunAt,
        now: now,
        everyHours: schedule.everyHours,
      ),
      BackupScheduleKind.daily => isDueDaily(
        lastRunAt: lastRunAt,
        now: now,
        hour: schedule.hour,
      ),
      BackupScheduleKind.weekly => isDueWeekly(
        lastRunAt: lastRunAt,
        now: now,
        weekday: schedule.weekday,
        hour: schedule.hour,
      ),
      BackupScheduleKind.monthly => isDueMonthly(
        lastRunAt: lastRunAt,
        now: now,
        dayOfMonth: schedule.dayOfMonth,
        hour: schedule.hour,
      ),
    };
  }

  /// Hourly: due when the job never ran, or at least [everyHours] elapsed
  /// since the last run.
  static bool isDueHourly({
    required DateTime? lastRunAt,
    required DateTime now,
    required int everyHours,
  }) {
    if (lastRunAt == null) {
      return true;
    }
    return now.difference(lastRunAt) >= Duration(hours: everyHours);
  }

  /// Daily: local [now] has reached [hour] today and no run was recorded
  /// today yet. Missed days (app not running) are not backfilled beyond the
  /// same calendar day (R6).
  static bool isDueDaily({
    required DateTime? lastRunAt,
    required DateTime now,
    required int hour,
  }) {
    if (now.hour < hour) {
      return false;
    }
    return !_ranOnSameLocalDay(lastRunAt, now);
  }

  /// Weekly: due on [weekday] (1 = Monday … 7 = Sunday) once local [now]
  /// has reached [hour], at most once per day.
  static bool isDueWeekly({
    required DateTime? lastRunAt,
    required DateTime now,
    required int weekday,
    required int hour,
  }) {
    if (now.weekday != weekday || now.hour < hour) {
      return false;
    }
    return !_ranOnSameLocalDay(lastRunAt, now);
  }

  /// Monthly: due on [dayOfMonth] — clamped to the last day of short months
  /// (day 31 fires on Feb 28) — once local [now] has reached [hour], at
  /// most once per day.
  static bool isDueMonthly({
    required DateTime? lastRunAt,
    required DateTime now,
    required int dayOfMonth,
    required int hour,
  }) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final effectiveDay = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
    if (now.day != effectiveDay || now.hour < hour) {
      return false;
    }
    return !_ranOnSameLocalDay(lastRunAt, now);
  }

  static bool _ranOnSameLocalDay(DateTime? lastRunAt, DateTime now) {
    if (lastRunAt == null) {
      return false;
    }
    final last = lastRunAt.toLocal();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }
}
