import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/failures/backup_failure.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Maps stable [BackupFailureCodes] to localized messages (SPEC §9).
///
/// Failures travel across the data/presentation boundary as a [Failure]
/// whose `message` is the failure code (same pattern as price monitor);
/// anything that is not a known code falls back to the generic message.
extension BackupFailureL10n on AppLocalizations {
  String backupFailureMessage(String code) {
    return switch (code) {
      BackupFailureCodes.sourceMissing => backupErrorSourceMissing,
      BackupFailureCodes.destinationNotWritable =>
        backupErrorDestinationNotWritable,
      BackupFailureCodes.sourceNotReadable => backupErrorSourceNotReadable,
      BackupFailureCodes.diskFull => backupErrorDiskFull,
      BackupFailureCodes.sameFolders => backupErrorSameFolders,
      BackupFailureCodes.interrupted => backupErrorInterrupted,
      BackupFailureCodes.pathTooLong => backupErrorPathTooLong,
      _ => backupErrorGeneric,
    };
  }

  /// Localized weekday name; [weekday] follows [DateTime.weekday]
  /// (1 = Monday … 7 = Sunday).
  String backupWeekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => backupWeekdayMon,
      DateTime.tuesday => backupWeekdayTue,
      DateTime.wednesday => backupWeekdayWed,
      DateTime.thursday => backupWeekdayThu,
      DateTime.friday => backupWeekdayFri,
      DateTime.saturday => backupWeekdaySat,
      DateTime.sunday => backupWeekdaySun,
      _ => backupWeekdayMon,
    };
  }

  /// One-line schedule summary for a job row, e.g. "Every 4 hours" or
  /// "Weekly on Monday at 02:00".
  String backupScheduleSummary(BackupSchedule schedule) {
    final time = _hourMinute(schedule.hour);
    return switch (schedule.kind) {
      BackupScheduleKind.hourly => backupScheduleEveryHours(
        schedule.everyHours,
      ),
      BackupScheduleKind.daily => backupScheduleDailyAt(time),
      BackupScheduleKind.weekly => backupScheduleWeeklyAt(
        backupWeekdayName(schedule.weekday),
        time,
      ),
      BackupScheduleKind.monthly => backupScheduleMonthlyAt(
        schedule.dayOfMonth,
        time,
      ),
    };
  }

  static String _hourMinute(int hour) =>
      '${hour.toString().padLeft(2, '0')}:00';
}
