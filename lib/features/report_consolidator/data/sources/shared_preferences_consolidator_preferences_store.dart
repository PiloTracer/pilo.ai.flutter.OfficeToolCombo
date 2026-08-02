import 'dart:convert';

import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_preferences_store.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads [SharedPreferences] on first read/write so the repository provider
/// stays synchronous.
class SharedPreferencesConsolidatorPreferencesStore
    implements ConsolidatorPreferencesStore {
  SharedPreferencesConsolidatorPreferencesStore();

  static const outputFolderPathKey = 'consolidator_output_folder_path';
  static const mergeHistoryKey = 'consolidator_merge_history';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> readOutputFolderPath() async {
    final preferences = await _instance();
    return preferences.getString(outputFolderPathKey);
  }

  @override
  Future<void> writeOutputFolderPath(String? path) async {
    final preferences = await _instance();
    if (path == null || path.isEmpty) {
      await preferences.remove(outputFolderPathKey);
      return;
    }
    await preferences.setString(outputFolderPathKey, path);
  }

  @override
  Future<List<MergeHistoryEntry>> readMergeHistory() async {
    final preferences = await _instance();
    final raw = preferences.getString(mergeHistoryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => MergeHistoryEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> prependMergeHistory(MergeHistoryEntry entry) async {
    final preferences = await _instance();
    final current = await readMergeHistory();
    final updated = <MergeHistoryEntry>[entry, ...current];
    final trimmed =
        updated.length > ConsolidatorPreferencesStore.maxMergeHistoryEntries
        ? updated.sublist(
            0,
            ConsolidatorPreferencesStore.maxMergeHistoryEntries,
          )
        : updated;

    final encoded = jsonEncode(trimmed.map((item) => item.toJson()).toList());
    await preferences.setString(mergeHistoryKey, encoded);
  }
}
