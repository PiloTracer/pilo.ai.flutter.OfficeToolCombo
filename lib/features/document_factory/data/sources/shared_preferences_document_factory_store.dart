import 'dart:convert';

import 'package:office_tool_combo/features/document_factory/data/sources/document_factory_preferences_store.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads [SharedPreferences] on first read/write so the repository provider
/// stays synchronous.
class SharedPreferencesDocumentFactoryStore
    implements DocumentFactoryPreferencesStore {
  SharedPreferencesDocumentFactoryStore();

  static const mappingsKey = 'document_factory_mappings';
  static const lastJobKey = 'document_factory_last_job';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<Map<String, String>?> readMapping(String templatePath) async {
    final mappings = await _readAllMappings();
    final mapping = mappings[templatePath];
    return mapping == null ? null : Map<String, String>.from(mapping);
  }

  @override
  Future<void> writeMapping(
    String templatePath,
    Map<String, String> mapping,
  ) async {
    final preferences = await _instance();
    final mappings = await _readAllMappings();
    mappings[templatePath] = Map<String, String>.from(mapping);
    final encoded = jsonEncode(
      mappings.map((path, value) => MapEntry<String, dynamic>(path, value)),
    );
    await preferences.setString(mappingsKey, encoded);
  }

  @override
  Future<DocumentJob?> readLastJob() async {
    final preferences = await _instance();
    final raw = preferences.getString(lastJobKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final job = DocumentJob.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // SPEC §7 — completed job metadata pruned after 30 days. A `running`
      // record is kept regardless so interruption is detected on relaunch.
      final age = DateTime.now().toUtc().difference(job.startedAt);
      if (job.status != DocumentJobStatus.running &&
          age > DocumentFactoryPreferencesStore.jobRetention) {
        await preferences.remove(lastJobKey);
        return null;
      }
      return job;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeLastJob(DocumentJob job) async {
    final preferences = await _instance();
    await preferences.setString(lastJobKey, jsonEncode(job.toJson()));
  }

  Future<Map<String, Map<String, String>>> _readAllMappings() async {
    final preferences = await _instance();
    final raw = preferences.getString(mappingsKey);
    if (raw == null || raw.isEmpty) {
      return <String, Map<String, String>>{};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (path, value) => MapEntry(
          path,
          (value as Map<String, dynamic>).map(
            (key, column) => MapEntry(key, column as String),
          ),
        ),
      );
    } on Object {
      return <String, Map<String, String>>{};
    }
  }
}
