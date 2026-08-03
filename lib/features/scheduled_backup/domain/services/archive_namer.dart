/// Archive basename rules (SPEC §7, R2/R3).
///
/// Basename pattern: `OfficeToolCombo-backup-YYYY-MM-DD.zip` using the local
/// calendar date at run start. A same-day re-run appends `-HHmmss`; further
/// collisions append `-2`, `-3`, … Because the date component is always
/// today's date, a run can never overwrite an archive from an earlier
/// calendar day (R3).
abstract final class ArchiveNamer {
  static const prefix = 'OfficeToolCombo-backup-';
  static const extension = '.zip';

  /// Suffix of the in-flight file; renamed to the final name on success and
  /// deleted on failure or interruption (SPEC §9).
  static const partialSuffix = '.partial';

  /// Base (first-run-of-the-day) archive name for [localStart].
  static String baseName(DateTime localStart) {
    return '$prefix${_date(localStart)}$extension';
  }

  /// Picks a non-colliding archive name for [localStart]. [exists] reports
  /// whether a candidate basename is already taken in the destination.
  static String resolveName(
    DateTime localStart,
    bool Function(String candidate) exists,
  ) {
    final base = baseName(localStart);
    if (!exists(base)) {
      return base;
    }
    final stem = '$prefix${_date(localStart)}-${_time(localStart)}';
    var candidate = '$stem$extension';
    var counter = 2;
    while (exists(candidate)) {
      candidate = '$stem-$counter$extension';
      counter += 1;
    }
    return candidate;
  }

  /// Extracts the embedded `YYYY-MM-DD` from an archive basename, or null
  /// when the name does not follow the backup naming pattern.
  static String? embeddedDate(String name) {
    if (!name.startsWith(prefix) || !name.endsWith(extension)) {
      return null;
    }
    final rest = name.substring(prefix.length);
    return rest.length >= 10 ? rest.substring(0, 10) : null;
  }

  static String _date(DateTime local) {
    return '${local.year.toString().padLeft(4, '0')}-'
        '${_pad(local.month)}-${_pad(local.day)}';
  }

  static String _time(DateTime local) {
    return '${_pad(local.hour)}${_pad(local.minute)}${_pad(local.second)}';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
