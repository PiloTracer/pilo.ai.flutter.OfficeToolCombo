import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/report_consolidator/data/repositories/consolidator_repository_impl.dart';
import 'package:office_tool_combo/features/report_consolidator/data/sources/consolidator_preferences_store.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';

import '../../../../helpers/consolidator_test_fixtures.dart';

void main() {
  late Directory tempDir;
  late Directory outputDir;
  late InMemoryConsolidatorPreferencesStore preferencesStore;
  late ConsolidatorRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('consolidator_test_');
    outputDir = await Directory.systemTemp.createTemp('consolidator_out_');
    preferencesStore = InMemoryConsolidatorPreferencesStore();
    repository = ConsolidatorRepositoryImpl(preferencesStore: preferencesStore);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    if (outputDir.existsSync()) {
      await outputDir.delete(recursive: true);
    }
  });

  group('ConsolidatorRepositoryImpl', () {
    test('empty folder returns emptyFolder failure', () async {
      final result = await repository.consolidateFolder(
        folderPath: tempDir.path,
      );

      expect(result, isA<Err<WorkbookBatch>>());
      final failure = (result as Err<WorkbookBatch>).failure;
      expect(failure.message, EmptyFolderFailure.emptyFolderMessage);
    });

    test('one good file produces consolidated output', () async {
      await ConsolidatorTestFixtures.writeWorkbook(
        directory: tempDir,
        fileName: 'report_a.xlsx',
        rows: [
          ['Name', 'Amount'],
          ['Alpha', '10'],
        ],
      );

      final result = await repository.consolidateFolder(
        folderPath: tempDir.path,
      );

      expect(result, isA<Success<WorkbookBatch>>());
      final batch = (result as Success<WorkbookBatch>).data;
      expect(batch.status, WorkbookBatchStatus.succeeded);
      expect(batch.outputPath, isNotNull);
      expect(File(batch.outputPath!).existsSync(), isTrue);
      expect(
        batch.outputPath!.startsWith(
          '${tempDir.path}${Platform.pathSeparator}',
        ),
        isTrue,
      );
      expect(batch.files.single.parseStatus, SpreadsheetParseStatus.success);
    });

    test(
      'saved output folder writes consolidated file outside source folder',
      () async {
        await preferencesStore.writeOutputFolderPath(outputDir.path);
        await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'report_a.xlsx',
          rows: [
            ['Name', 'Amount'],
            ['Alpha', '10'],
          ],
        );

        final result = await repository.consolidateFolder(
          folderPath: tempDir.path,
        );

        expect(result, isA<Success<WorkbookBatch>>());
        final batch = (result as Success<WorkbookBatch>).data;
        expect(batch.outputPath, isNotNull);
        expect(
          batch.outputPath!.startsWith(
            '${outputDir.path}${Platform.pathSeparator}',
          ),
          isTrue,
        );
        expect(File(batch.outputPath!).existsSync(), isTrue);
        expect(
          Directory(tempDir.path).listSync().whereType<File>().where(
            (f) => f.path.contains('consolidated_'),
          ),
          isEmpty,
        );
      },
    );

    test(
      'explicit output folder overrides saved preference for one run',
      () async {
        final otherOutputDir = await Directory.systemTemp.createTemp(
          'consolidator_other_out_',
        );
        addTearDown(() async {
          if (otherOutputDir.existsSync()) {
            await otherOutputDir.delete(recursive: true);
          }
        });

        await preferencesStore.writeOutputFolderPath(outputDir.path);
        await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'report_a.xlsx',
          rows: [
            ['Name', 'Amount'],
            ['Alpha', '10'],
          ],
        );

        final result = await repository.consolidateFolder(
          folderPath: tempDir.path,
          outputFolderPath: otherOutputDir.path,
        );

        expect(result, isA<Success<WorkbookBatch>>());
        final batch = (result as Success<WorkbookBatch>).data;
        expect(
          batch.outputPath!.startsWith(
            '${otherOutputDir.path}${Platform.pathSeparator}',
          ),
          isTrue,
        );
      },
    );

    test('mixed good and broken files returns partial batch', () async {
      await ConsolidatorTestFixtures.writeWorkbook(
        directory: tempDir,
        fileName: 'good.xlsx',
        rows: [
          ['Name', 'Amount'],
          ['Alpha', '10'],
        ],
      );
      await ConsolidatorTestFixtures.writeBrokenFile(
        directory: tempDir,
        fileName: 'broken.xlsx',
      );

      final result = await repository.consolidateFolder(
        folderPath: tempDir.path,
      );

      expect(result, isA<Success<WorkbookBatch>>());
      final batch = (result as Success<WorkbookBatch>).data;
      expect(batch.status, WorkbookBatchStatus.partial);
      expect(batch.outputPath, isNotNull);
      expect(
        batch.files.where(
          (f) => f.parseStatus == SpreadsheetParseStatus.failed,
        ),
        isNotEmpty,
      );
      expect(
        batch.files.where(
          (f) => f.parseStatus == SpreadsheetParseStatus.success,
        ),
        isNotEmpty,
      );
    });

    test('successful merge records entry in merge history', () async {
      await ConsolidatorTestFixtures.writeWorkbook(
        directory: tempDir,
        fileName: 'report_a.xlsx',
        rows: [
          ['Name', 'Amount'],
          ['Alpha', '10'],
        ],
      );

      final result = await repository.consolidateFolder(
        folderPath: tempDir.path,
      );

      expect(result, isA<Success<WorkbookBatch>>());
      final history = await repository.readMergeHistory();
      expect(history, hasLength(1));
      expect(history.first.sourceFolderPath, tempDir.path);
      expect(File(history.first.outputPath).existsSync(), isTrue);
    });
  });
}
