import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';

/// Persists consolidator UI preferences across app restarts.
abstract class ConsolidatorPreferencesStore {
  static const maxMergeHistoryEntries = 20;

  Future<String?> readOutputFolderPath();

  Future<void> writeOutputFolderPath(String? path);

  Future<List<MergeHistoryEntry>> readMergeHistory();

  Future<void> prependMergeHistory(MergeHistoryEntry entry);
}

class InMemoryConsolidatorPreferencesStore
    implements ConsolidatorPreferencesStore {
  InMemoryConsolidatorPreferencesStore({
    this.outputFolderPath,
    List<MergeHistoryEntry>? mergeHistory,
  }) : _mergeHistory = mergeHistory ?? [];

  String? outputFolderPath;
  final List<MergeHistoryEntry> _mergeHistory;

  @override
  Future<String?> readOutputFolderPath() async => outputFolderPath;

  @override
  Future<void> writeOutputFolderPath(String? path) async {
    outputFolderPath = path;
  }

  @override
  Future<List<MergeHistoryEntry>> readMergeHistory() async {
    return List<MergeHistoryEntry>.from(_mergeHistory);
  }

  @override
  Future<void> prependMergeHistory(MergeHistoryEntry entry) async {
    _mergeHistory.insert(0, entry);
    if (_mergeHistory.length >
        ConsolidatorPreferencesStore.maxMergeHistoryEntries) {
      _mergeHistory.removeRange(
        ConsolidatorPreferencesStore.maxMergeHistoryEntries,
        _mergeHistory.length,
      );
    }
  }
}
