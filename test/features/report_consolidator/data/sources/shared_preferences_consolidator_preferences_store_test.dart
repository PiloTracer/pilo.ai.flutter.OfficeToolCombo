import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/shared_preferences_consolidator_preferences_store.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MergeHistoryEntry entry(int index) {
    return MergeHistoryEntry(
      outputPath: '/tmp/out/file_$index.xlsx',
      fileName: 'file_$index.xlsx',
      sourceFolderPath: '/tmp/source',
      mergedAt: DateTime(2026, 7, 1, 12, index),
      status: index.isEven ? 'succeeded' : 'partial',
    );
  }

  group('SharedPreferencesConsolidatorPreferencesStore', () {
    test('output folder path writes and reads back', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesConsolidatorPreferencesStore();

      expect(await store.readOutputFolderPath(), isNull);

      await store.writeOutputFolderPath('/tmp/out');
      expect(await store.readOutputFolderPath(), '/tmp/out');
    });

    test('writing null or empty clears the saved output folder path', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesConsolidatorPreferencesStore.outputFolderPathKey:
            '/tmp/out',
      });
      final store = SharedPreferencesConsolidatorPreferencesStore();

      await store.writeOutputFolderPath(null);
      expect(await store.readOutputFolderPath(), isNull);

      await store.writeOutputFolderPath('/tmp/other');
      await store.writeOutputFolderPath('');
      expect(await store.readOutputFolderPath(), isNull);
    });

    test('merge history prepends newest-first and caps at 20', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesConsolidatorPreferencesStore();

      for (var index = 0; index < 22; index++) {
        await store.prependMergeHistory(entry(index));
      }

      final history = await store.readMergeHistory();
      expect(history, hasLength(20));
      expect(history.first.fileName, 'file_21.xlsx');
      expect(history.last.fileName, 'file_2.xlsx');
    });

    test('merge history round-trips entry fields', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesConsolidatorPreferencesStore();

      await store.prependMergeHistory(entry(3));

      final history = await store.readMergeHistory();
      expect(history, [entry(3)]);
    });

    test('corrupt JSON returns an empty list', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesConsolidatorPreferencesStore.mergeHistoryKey:
            'not-json',
      });
      final store = SharedPreferencesConsolidatorPreferencesStore();

      expect(await store.readMergeHistory(), isEmpty);
    });

    test('wrong-shape JSON returns an empty list', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesConsolidatorPreferencesStore.mergeHistoryKey: '{}',
      });
      final store = SharedPreferencesConsolidatorPreferencesStore();

      expect(await store.readMergeHistory(), isEmpty);
    });

    test('entries with missing fields return an empty list', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesConsolidatorPreferencesStore.mergeHistoryKey:
            '[{"outputPath": 42}]',
      });
      final store = SharedPreferencesConsolidatorPreferencesStore();

      expect(await store.readMergeHistory(), isEmpty);
    });

    test('values persist across fresh store instances', () async {
      SharedPreferences.setMockInitialValues({});
      final first = SharedPreferencesConsolidatorPreferencesStore();
      await first.writeOutputFolderPath('/tmp/persisted');
      await first.prependMergeHistory(entry(1));

      final second = SharedPreferencesConsolidatorPreferencesStore();
      expect(await second.readOutputFolderPath(), '/tmp/persisted');
      expect(await second.readMergeHistory(), [entry(1)]);
    });
  });
}
