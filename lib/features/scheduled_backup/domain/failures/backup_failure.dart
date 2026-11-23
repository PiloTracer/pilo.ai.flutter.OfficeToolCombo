/// Domain failures for scheduled backup. Mapped to [Failure] at boundaries.
///
/// Each failure carries a stable machine-readable [code] (see
/// [BackupFailureCodes]) so the presentation layer can map it to a localized
/// message. [message] stays an English technical description for logs and
/// debugging — domain and data layers remain locale-free.
sealed class BackupFailure {
  const BackupFailure({required this.code, required this.message});

  final String code;
  final String message;
}

/// Stable failure codes consumed by the presentation layer for localization
/// (SPEC §9 — one code per user-facing message).
abstract final class BackupFailureCodes {
  static const load = 'backup.load';
  static const save = 'backup.save';
  static const sourceMissing = 'backup.source_missing';
  static const destinationNotWritable = 'backup.destination_not_writable';
  static const sourceNotReadable = 'backup.source_not_readable';
  static const diskFull = 'backup.disk_full';
  static const sameFolders = 'backup.same_folders';
  static const interrupted = 'backup.interrupted';
  static const pathTooLong = 'backup.path_too_long';
  static const run = 'backup.run';
  static const reveal = 'backup.reveal';
  static const busy = 'backup.busy';
}

final class BackupConfigLoadFailure extends BackupFailure {
  const BackupConfigLoadFailure([
    String message = 'Could not load backup settings',
  ]) : super(code: BackupFailureCodes.load, message: message);
}

final class BackupConfigSaveFailure extends BackupFailure {
  const BackupConfigSaveFailure([
    String message = 'Could not save backup settings',
  ]) : super(code: BackupFailureCodes.save, message: message);
}

/// Run failure; [code] is one of the run-related BackupFailureCodes values.
final class BackupRunFailure extends BackupFailure {
  const BackupRunFailure({required super.code, required super.message});
}
