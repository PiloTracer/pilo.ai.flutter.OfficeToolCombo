import 'dart:convert';

import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads [SharedPreferences] on first read/write so the repository provider
/// stays synchronous.
///
/// Migration (v1 → v2): the first [readJobs] call on an install that only
/// has the v1 single-job keys converts the stored config into job #1 with
/// the label "Default backup" (daily schedule from the old run hour) and
/// folds the v1 last-run record and archive list into the unified run log.
/// The legacy keys are removed afterwards — the new model is the source of
/// truth from then on.
class SharedPreferencesBackupStore implements BackupStore {
  SharedPreferencesBackupStore();

  static const jobsKey = 'scheduled_backup_jobs';
  static const runLogKey = 'scheduled_backup_run_log';

  static const legacyJobKey = 'scheduled_backup_job';
  static const legacyLastRunKey = 'scheduled_backup_last_run';
  static const legacyArchivesKey = 'scheduled_backup_archives';

  /// Id and label assigned to the migrated v1 configuration.
  static const migratedJobId = 'job-1';
  static const migratedJobLabel = 'Default backup';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<BackupJob>> readJobs() async {
    final preferences = await _instance();
    final raw = preferences.getString(jobsKey);
    if (raw == null || raw.isEmpty) {
      return _migrateLegacy(preferences);
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((job) => BackupJob.fromJson(job as Map<String, dynamic>))
          .toList(growable: false);
    } on Object {
      return <BackupJob>[];
    }
  }

  @override
  Future<void> writeJobs(List<BackupJob> jobs) async {
    final preferences = await _instance();
    final encoded = jsonEncode(
      jobs.map((job) => job.toJson()).toList(growable: false),
    );
    await preferences.setString(jobsKey, encoded);
  }

  @override
  Future<List<BackupRunLogEntry>> readRunLog() async {
    final preferences = await _instance();
    final raw = preferences.getString(runLogKey);
    if (raw == null || raw.isEmpty) {
      return <BackupRunLogEntry>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) =>
                BackupRunLogEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on Object {
      return <BackupRunLogEntry>[];
    }
  }

  @override
  Future<void> writeRunLog(List<BackupRunLogEntry> entries) async {
    final preferences = await _instance();
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    await preferences.setString(runLogKey, encoded);
  }

  /// Converts the v1 single-job model, if present, and clears its keys.
  Future<List<BackupJob>> _migrateLegacy(SharedPreferences preferences) async {
    final rawJob = preferences.getString(legacyJobKey);
    if (rawJob == null || rawJob.isEmpty) {
      return <BackupJob>[];
    }
    Map<String, dynamic> legacyJob;
    try {
      legacyJob = jsonDecode(rawJob) as Map<String, dynamic>;
    } on Object {
      return <BackupJob>[];
    }

    final hour = legacyJob['dailyRunHour'];
    final job = BackupJob(
      id: migratedJobId,
      label: migratedJobLabel,
      sourceFolder: legacyJob['sourceFolder'] as String?,
      destinationFolder: legacyJob['destinationFolder'] as String?,
      schedule: BackupSchedule.daily(
        hour: hour is int && hour >= 0 && hour <= 23
            ? hour
            : BackupSchedule.defaultDailyRunHour,
      ),
      enabled: legacyJob['scheduleEnabled'] as bool? ?? true,
    );
    await writeJobs(<BackupJob>[job]);

    // Fold v1 history into the unified run log: stored archives become
    // succeeded entries; a failed/cancelled last-run record becomes one
    // more entry (successful last runs are already covered by archives).
    final entries = <BackupRunLogEntry>[];
    final rawArchives = preferences.getString(legacyArchivesKey);
    if (rawArchives != null && rawArchives.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawArchives) as List<dynamic>;
        for (final item in decoded.cast<Map<String, dynamic>>()) {
          entries.add(
            BackupRunLogEntry(
              jobId: migratedJobId,
              jobLabel: migratedJobLabel,
              finishedAt:
                  DateTime.tryParse(
                    item['finishedAt'] as String? ?? '',
                  )?.toUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              status: BackupRunStatus.succeeded,
              archiveName: item['name'] as String?,
              archiveBytes: item['bytes'] as int?,
              archivePath: item['path'] as String?,
            ),
          );
        }
      } on Object {
        // Corrupt legacy history is dropped, not fatal.
      }
    }
    final rawLastRun = preferences.getString(legacyLastRunKey);
    if (rawLastRun != null && rawLastRun.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLastRun) as Map<String, dynamic>;
        final status =
            BackupRunStatus.values.asNameMap()[decoded['status']] ??
            BackupRunStatus.failed;
        if (status != BackupRunStatus.succeeded) {
          entries.insert(
            0,
            BackupRunLogEntry(
              jobId: migratedJobId,
              jobLabel: migratedJobLabel,
              finishedAt:
                  DateTime.tryParse(
                    decoded['timestamp'] as String? ?? '',
                  )?.toUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              status: status,
              messageCode: decoded['messageCode'] as String? ?? '',
            ),
          );
        }
      } on Object {
        // Corrupt legacy record is dropped, not fatal.
      }
    }
    if (entries.isNotEmpty) {
      await writeRunLog(entries);
    }

    await preferences.remove(legacyJobKey);
    await preferences.remove(legacyLastRunKey);
    await preferences.remove(legacyArchivesKey);
    return <BackupJob>[job];
  }
}
