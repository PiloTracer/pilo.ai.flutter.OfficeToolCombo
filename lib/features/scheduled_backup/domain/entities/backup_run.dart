/// What triggered a backup run (SPEC §14 — observability property).
enum BackupTrigger { manual, scheduled }

/// Terminal state of a backup run (SPEC §7).
enum BackupRunStatus { succeeded, failed, cancelled }

/// Last-run bookkeeping (R7/R8): one record, overwritten by each run.
///
/// [messageCode] is a stable BackupFailureCodes value for failed runs and
/// empty for successful ones; the presentation layer maps it to a localized
/// message. Timestamps are stored UTC and displayed local.
class BackupRunRecord {
  const BackupRunRecord({
    required this.status,
    required this.messageCode,
    required this.timestamp,
  });

  final BackupRunStatus status;
  final String messageCode;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status.name,
    'messageCode': messageCode,
    'timestamp': timestamp.toIso8601String(),
  };

  static BackupRunRecord fromJson(Map<String, dynamic> json) {
    return BackupRunRecord(
      status:
          BackupRunStatus.values.asNameMap()[json['status']] ??
          BackupRunStatus.failed,
      messageCode: json['messageCode'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// One entry of the recent archives list (R8 — max 10, newest first).
///
/// [path] is stored internally and never shown verbatim to the user (NFR8);
/// the UI displays [name] only.
class BackupArchiveEntry {
  const BackupArchiveEntry({
    required this.name,
    required this.path,
    required this.bytes,
    required this.finishedAt,
  });

  final String name;
  final String path;
  final int bytes;
  final DateTime finishedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'path': path,
    'bytes': bytes,
    'finishedAt': finishedAt.toIso8601String(),
  };

  static BackupArchiveEntry fromJson(Map<String, dynamic> json) {
    return BackupArchiveEntry(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      bytes: json['bytes'] as int? ?? 0,
      finishedAt:
          DateTime.tryParse(json['finishedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// Progress of an in-flight run: files processed out of the total count.
class BackupRunProgress {
  const BackupRunProgress({
    required this.processedFiles,
    required this.totalFiles,
  });

  final int processedFiles;
  final int totalFiles;

  double? get fraction => totalFiles > 0 ? processedFiles / totalFiles : null;
}
