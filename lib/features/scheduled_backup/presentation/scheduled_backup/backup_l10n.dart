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
}
