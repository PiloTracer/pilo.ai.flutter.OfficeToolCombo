import 'dart:convert';

import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads [SharedPreferences] on first read/write so the repository provider
/// stays synchronous.
class SharedPreferencesBackupStore implements BackupStore {
  SharedPreferencesBackupStore();

  static const jobKey = 'scheduled_backup_job';
  static const lastRunKey = 'scheduled_backup_last_run';
  static const archivesKey = 'scheduled_backup_archives';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<BackupJob?> readJob() async {
    final preferences = await _instance();
    final raw = preferences.getString(jobKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return BackupJob.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeJob(BackupJob job) async {
    final preferences = await _instance();
    await preferences.setString(jobKey, jsonEncode(job.toJson()));
  }

  @override
  Future<BackupRunRecord?> readLastRun() async {
    final preferences = await _instance();
    final raw = preferences.getString(lastRunKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return BackupRunRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeLastRun(BackupRunRecord record) async {
    final preferences = await _instance();
    await preferences.setString(lastRunKey, jsonEncode(record.toJson()));
  }

  @override
  Future<List<BackupArchiveEntry>> readArchives() async {
    final preferences = await _instance();
    final raw = preferences.getString(archivesKey);
    if (raw == null || raw.isEmpty) {
      return <BackupArchiveEntry>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) =>
                BackupArchiveEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on Object {
      return <BackupArchiveEntry>[];
    }
  }

  @override
  Future<void> writeArchives(List<BackupArchiveEntry> archives) async {
    final preferences = await _instance();
    final encoded = jsonEncode(
      archives.map((entry) => entry.toJson()).toList(growable: false),
    );
    await preferences.setString(archivesKey, encoded);
  }
}
