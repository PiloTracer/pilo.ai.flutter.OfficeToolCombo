import 'dart:async';

import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';

/// Fires the daily scheduled run while the app process is running (R5/R6,
/// SPEC §4 F3).
///
/// A periodic check (default every 30 s, so drift stays ≤ 1 minute — A5)
/// asks whether local time has passed the configured hour today and no run
/// happened today yet. Clock, interval, and all side effects are injected so
/// tests control time and observe runs directly.
class BackupScheduler {
  BackupScheduler({
    this.checkInterval = const Duration(seconds: 30),
    DateTime Function()? now,
    required this.readJob,
    required this.readLastRunAt,
    required this.isRunInProgress,
    required this.startRun,
    this.log,
  }) : _now = now ?? DateTime.now;

  final Duration checkInterval;
  final DateTime Function() _now;
  final Future<BackupJob> Function() readJob;
  final Future<DateTime?> Function() readLastRunAt;
  final bool Function() isRunInProgress;
  final Future<void> Function() startRun;
  final void Function(String message)? log;

  Timer? _timer;
  bool _ticking = false;

  /// Starts the periodic check and performs one immediate check, so an app
  /// launched after the configured hour still runs today's backup (R6).
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
    final job = await readJob();
    if (!job.scheduleEnabled || !job.isConfigured) {
      return;
    }
    final lastRunAt = await readLastRunAt();
    if (!isDue(
      now: _now(),
      dailyRunHour: job.dailyRunHour,
      lastRunAt: lastRunAt,
    )) {
      return;
    }
    // R5 — a run is already in progress: skip the scheduled run and log it
    // (SPEC §4 F3).
    if (isRunInProgress()) {
      log?.call('backup.scheduled_skipped reason=run_in_progress');
      return;
    }
    await startRun();
  }

  /// Pure due check: local [now] has reached [dailyRunHour] today and no run
  /// was recorded today yet. Missed days (app not running) are not
  /// backfilled beyond the same calendar day (R6).
  static bool isDue({
    required DateTime now,
    required int dailyRunHour,
    required DateTime? lastRunAt,
  }) {
    if (now.hour < dailyRunHour) {
      return false;
    }
    if (lastRunAt == null) {
      return true;
    }
    final last = lastRunAt.toLocal();
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }
}
