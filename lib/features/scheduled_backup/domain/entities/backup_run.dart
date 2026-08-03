/// What triggered a backup run (SPEC §14 — observability property).
enum BackupTrigger { manual, scheduled }

/// Terminal state of a backup run (SPEC §7).
enum BackupRunStatus { succeeded, failed, cancelled }

/// One entry of the unified run log across all jobs (max 50, newest first).
///
/// [messageCode] is a stable BackupFailureCodes value for failed/cancelled
/// runs and empty for successful ones; the presentation layer maps it to a
/// localized message. [archivePath] is stored internally and never shown
/// verbatim to the user (NFR8); the UI displays [archiveName] only.
/// Timestamps are stored UTC and displayed local.
class BackupRunLogEntry {
  const BackupRunLogEntry({
    required this.jobId,
    required this.jobLabel,
    required this.finishedAt,
    required this.status,
    this.archiveName,
    this.archiveBytes,
    this.archivePath,
    this.messageCode = '',
  });

  final String jobId;
  final String jobLabel;
  final DateTime finishedAt;
  final BackupRunStatus status;

  /// Archive basename, byte size and full path — set on success only.
  final String? archiveName;
  final int? archiveBytes;
  final String? archivePath;

  final String messageCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'jobId': jobId,
    'jobLabel': jobLabel,
    'finishedAt': finishedAt.toIso8601String(),
    'status': status.name,
    'archiveName': archiveName,
    'archiveBytes': archiveBytes,
    'archivePath': archivePath,
    'messageCode': messageCode,
  };

  static BackupRunLogEntry fromJson(Map<String, dynamic> json) {
    return BackupRunLogEntry(
      jobId: json['jobId'] as String? ?? '',
      jobLabel: json['jobLabel'] as String? ?? '',
      finishedAt:
          DateTime.tryParse(json['finishedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status:
          BackupRunStatus.values.asNameMap()[json['status']] ??
          BackupRunStatus.failed,
      archiveName: json['archiveName'] as String?,
      archiveBytes: json['archiveBytes'] as int?,
      archivePath: json['archivePath'] as String?,
      messageCode: json['messageCode'] as String? ?? '',
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
