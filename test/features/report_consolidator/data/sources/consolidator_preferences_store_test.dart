import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_preferences_store.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';

void main() {
  group('ConsolidatorPreferencesStore merge history', () {
    test('prepends entries newest-first and keeps at most 20', () async {
      final store = InMemoryConsolidatorPreferencesStore();

      for (var index = 0; index < 22; index++) {
        await store.prependMergeHistory(
          MergeHistoryEntry(
            outputPath: '/tmp/out/file_$index.xlsx',
            fileName: 'file_$index.xlsx',
            sourceFolderPath: '/tmp/source',
            mergedAt: DateTime(2026, 7, 1, 12, index),
            status: 'succeeded',
          ),
        );
      }

      final history = await store.readMergeHistory();
      expect(history, hasLength(20));
      expect(history.first.fileName, 'file_21.xlsx');
      expect(history.last.fileName, 'file_2.xlsx');
    });

    test('read returns copies in stored order', () async {
      final store = InMemoryConsolidatorPreferencesStore();
      await store.prependMergeHistory(
        MergeHistoryEntry(
          outputPath: '/tmp/out/new.xlsx',
          fileName: 'new.xlsx',
          sourceFolderPath: '/tmp/source',
          mergedAt: DateTime(2026, 7, 2),
          status: 'partial',
        ),
      );
      await store.prependMergeHistory(
        MergeHistoryEntry(
          outputPath: '/tmp/out/old.xlsx',
          fileName: 'old.xlsx',
          sourceFolderPath: '/tmp/source',
          mergedAt: DateTime(2026, 7, 1),
          status: 'succeeded',
        ),
      );

      final history = await store.readMergeHistory();
      expect(history.map((entry) => entry.fileName), ['old.xlsx', 'new.xlsx']);
    });
  });
}
