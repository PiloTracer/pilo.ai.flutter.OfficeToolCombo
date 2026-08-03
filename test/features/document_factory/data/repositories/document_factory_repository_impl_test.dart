import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/document_factory/data/repositories/document_factory_repository_impl.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/document_factory_preferences_store.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/shared_preferences_document_factory_store.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/consolidator_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory outputDir;
  late InMemoryDocumentFactoryPreferencesStore store;
  late DocumentFactoryRepositoryImpl repository;

  Future<File> writeTemplate(String html) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}template.html');
    await file.writeAsString(html);
    return file;
  }

  List<String> pdfNames() {
    return outputDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.pdf'))
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toList()
      ..sort();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('docfactory_test_');
    outputDir = await Directory.systemTemp.createTemp('docfactory_out_');
    store = InMemoryDocumentFactoryPreferencesStore();
    repository = DocumentFactoryRepositoryImpl(preferencesStore: store);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    if (outputDir.existsSync()) {
      await outputDir.delete(recursive: true);
    }
  });

  group('DocumentFactoryRepositoryImpl.runBatch', () {
    test(
      'A1: template with {{Name}} and 3 rows produces exactly 3 PDFs',
      () async {
        final template = await writeTemplate('<h1>Hello {{Name}}</h1>');
        final sheet = await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'data.xlsx',
          rows: [
            ['Name'],
            ['Ada'],
            ['Grace'],
            ['Linus'],
          ],
        );

        final progressTicks = <DocumentBatchProgress>[];
        final result = await repository.runBatch(
          templatePath: template.path,
          dataSheetPath: sheet.path,
          outputDirPath: outputDir.path,
          mapping: const {'Name': 'Name'},
          onProgress: progressTicks.add,
        );

        expect(result, isA<Success<DocumentJob>>());
        final job = (result as Success<DocumentJob>).data;
        expect(job.status, DocumentJobStatus.succeeded);
        expect(job.doneCount, 3);
        expect(job.failedCount, 0);
        expect(pdfNames(), ['1.pdf', '2.pdf', '3.pdf']);
        // Per-row progress reached the full row count.
        expect(progressTicks.last.done, 3);
        expect(progressTicks.last.total, 3);
        // Job record is no longer `running` after completion.
        final lastJob = await repository.readLastJob();
        expect(lastJob, isNotNull);
        expect(lastJob!.status, DocumentJobStatus.succeeded);
      },
    );

    test(
      'A2: empty mapped cell in row 2 fails that row, batch continues',
      () async {
        final template = await writeTemplate(
          '<h1>{{Name}}</h1><p>{{City}}</p>',
        );
        final sheet = await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'data.xlsx',
          rows: [
            ['Name', 'City'],
            ['Ada', 'Lima'],
            ['', 'Bogota'],
            ['Linus', 'Helsinki'],
          ],
        );

        final result = await repository.runBatch(
          templatePath: template.path,
          dataSheetPath: sheet.path,
          outputDirPath: outputDir.path,
          mapping: const {'Name': 'Name', 'City': 'City'},
        );

        expect(result, isA<Success<DocumentJob>>());
        final job = (result as Success<DocumentJob>).data;
        expect(job.status, DocumentJobStatus.partial);
        expect(job.doneCount, 2);
        expect(job.failedCount, 1);
        expect(job.failures.single.rowNumber, 2);
        expect(
          job.failures.single.code,
          DocumentFactoryFailureCodes.rowMissingValue,
        );
        expect(pdfNames(), ['1.pdf', '3.pdf']);
      },
    );

    test(
      'R3: fully blank row is skipped, not counted as success or failure',
      () async {
        final template = await writeTemplate('<h1>{{Name}}</h1>');
        final sheet = await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'data.xlsx',
          rows: [
            ['Name', 'City'],
            ['Ada', 'Lima'],
            ['', ''],
          ],
        );

        final result = await repository.runBatch(
          templatePath: template.path,
          dataSheetPath: sheet.path,
          outputDirPath: outputDir.path,
          mapping: const {'Name': 'Name'},
        );

        final job = (result as Success<DocumentJob>).data;
        expect(job.status, DocumentJobStatus.succeeded);
        expect(job.doneCount, 1);
        expect(job.failedCount, 0);
        expect(job.skippedCount, 1);
        expect(job.failures, isEmpty);
        expect(pdfNames(), ['1.pdf']);
      },
    );

    test(
      'R4: non-writable output folder blocks the job before start',
      () async {
        final template = await writeTemplate('<h1>{{Name}}</h1>');
        final sheet = await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'data.xlsx',
          rows: [
            ['Name'],
            ['Ada'],
          ],
        );

        final result = await repository.runBatch(
          templatePath: template.path,
          dataSheetPath: sheet.path,
          outputDirPath:
              '${tempDir.path}${Platform.pathSeparator}does_not_exist',
          mapping: const {'Name': 'Name'},
        );

        expect(result, isA<Err<DocumentJob>>());
        expect(
          (result as Err<DocumentJob>).failure.message,
          DocumentFactoryFailureCodes.outputNotWritable,
        );
        // No job record was started.
        expect(await repository.readLastJob(), isNull);
      },
    );

    test('batch-level failure (missing sheet) returns stable code', () async {
      final template = await writeTemplate('<h1>{{Name}}</h1>');

      final result = await repository.runBatch(
        templatePath: template.path,
        dataSheetPath: '${tempDir.path}${Platform.pathSeparator}gone.xlsx',
        outputDirPath: outputDir.path,
        mapping: const {'Name': 'Name'},
      );

      expect(result, isA<Err<DocumentJob>>());
      expect(
        (result as Err<DocumentJob>).failure.message,
        DocumentFactoryFailureCodes.sheetRead,
      );
      final lastJob = await repository.readLastJob();
      expect(lastJob!.status, DocumentJobStatus.failed);
    });

    test('markLastJobInterrupted flags a stale running record', () async {
      await store.writeLastJob(
        DocumentJob(
          id: 'job-x',
          templatePath: '/tmp/template.html',
          dataSheetPath: '/tmp/data.xlsx',
          outputDirPath: '/tmp/out',
          status: DocumentJobStatus.running,
          totalRows: 10,
          startedAt: DateTime.now().toUtc(),
        ),
      );

      await repository.markLastJobInterrupted();

      final lastJob = await repository.readLastJob();
      expect(lastJob!.status, DocumentJobStatus.failed);
      expect(lastJob.finishedAt, isNotNull);
    });
  });

  group('DocumentFactoryRepositoryImpl.inspectDataSheet', () {
    test(
      'duplicate header names return the duplicateHeaders code (SPEC §9)',
      () async {
        final sheet = await ConsolidatorTestFixtures.writeWorkbook(
          directory: tempDir,
          fileName: 'dupes.xlsx',
          rows: [
            ['Name', 'Name'],
            ['Ada', 'Grace'],
          ],
        );

        final result = await repository.inspectDataSheet(sheet.path);

        expect(result, isA<Err<SheetInspection>>());
        expect(
          (result as Err<SheetInspection>).failure.message,
          DocumentFactoryFailureCodes.duplicateHeaders,
        );
      },
    );

    test('corrupt sheet returns the sheetRead code', () async {
      final broken = await ConsolidatorTestFixtures.writeBrokenFile(
        directory: tempDir,
        fileName: 'broken.xlsx',
      );

      final result = await repository.inspectDataSheet(broken.path);

      expect(result, isA<Err<SheetInspection>>());
      expect(
        (result as Err<SheetInspection>).failure.message,
        DocumentFactoryFailureCodes.sheetRead,
      );
    });

    test('missing template returns the templateRead code', () async {
      final result = await repository.inspectTemplate(
        '${tempDir.path}${Platform.pathSeparator}missing.html',
      );

      expect(result, isA<Err<TemplateInspection>>());
      expect(
        (result as Err<TemplateInspection>).failure.message,
        DocumentFactoryFailureCodes.templateRead,
      );
    });
  });

  group('DocumentFactoryRepositoryImpl mapping persistence (A3)', () {
    test('saved mapping is restored by a new repository instance', () async {
      SharedPreferences.setMockInitialValues({});
      final template = await writeTemplate('<h1>{{Name}}</h1>');

      final first = DocumentFactoryRepositoryImpl(
        preferencesStore: SharedPreferencesDocumentFactoryStore(),
      );
      final saved = await first.saveMapping(template.path, {'Name': 'Name'});
      expect(saved, isA<Success<void>>());

      final second = DocumentFactoryRepositoryImpl(
        preferencesStore: SharedPreferencesDocumentFactoryStore(),
      );
      final inspection = await second.inspectTemplate(template.path);

      expect(inspection, isA<Success<TemplateInspection>>());
      final data = (inspection as Success<TemplateInspection>).data;
      expect(data.template.placeholders, ['Name']);
      expect(data.restoredMapping, {'Name': 'Name'});
    });
  });
}
