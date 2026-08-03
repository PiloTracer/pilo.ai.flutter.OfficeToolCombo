import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/document_factory/data/sources/shared_preferences_document_factory_store.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:shared_preferences/shared_preferences.dart';

DocumentJob _job({
  DocumentJobStatus status = DocumentJobStatus.succeeded,
  DateTime? startedAt,
}) {
  return DocumentJob(
    id: 'job-1',
    templatePath: '/tmp/template.html',
    dataSheetPath: '/tmp/data.xlsx',
    outputDirPath: '/tmp/out',
    status: status,
    totalRows: 3,
    startedAt: startedAt ?? DateTime.now().toUtc(),
    doneCount: 3,
    finishedAt: DateTime.now().toUtc(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesDocumentFactoryStore', () {
    test('mapping round-trips through a fresh store instance', () async {
      final first = SharedPreferencesDocumentFactoryStore();
      await first.writeMapping('/tmp/template.html', {'Name': 'Name'});

      final second = SharedPreferencesDocumentFactoryStore();
      final restored = await second.readMapping('/tmp/template.html');
      expect(restored, {'Name': 'Name'});
    });

    test('readMapping returns null for unknown template path (R6)', () async {
      final store = SharedPreferencesDocumentFactoryStore();
      await store.writeMapping('/tmp/a.html', {'Name': 'Name'});

      expect(await store.readMapping('/tmp/b.html'), isNull);
    });

    test('mappings for different template paths stay separate', () async {
      final store = SharedPreferencesDocumentFactoryStore();
      await store.writeMapping('/tmp/a.html', {'Name': 'Name'});
      await store.writeMapping('/tmp/b.html', {'Name': 'FullName'});

      expect(await store.readMapping('/tmp/a.html'), {'Name': 'Name'});
      expect(await store.readMapping('/tmp/b.html'), {'Name': 'FullName'});
    });

    test('last job round-trips including failures', () async {
      final first = SharedPreferencesDocumentFactoryStore();
      final job = DocumentJob(
        id: 'job-9',
        templatePath: '/tmp/template.html',
        dataSheetPath: '/tmp/data.xlsx',
        outputDirPath: '/tmp/out',
        status: DocumentJobStatus.partial,
        totalRows: 3,
        startedAt: DateTime.now().toUtc(),
        doneCount: 2,
        failedCount: 1,
        finishedAt: DateTime.now().toUtc(),
        failures: const [
          RowFailure(
            rowNumber: 2,
            code: 'document_factory.rowRender',
            message: 'boom',
          ),
        ],
      );
      await first.writeLastJob(job);

      final second = SharedPreferencesDocumentFactoryStore();
      final restored = await second.readLastJob();
      expect(restored, isNotNull);
      expect(restored!.id, 'job-9');
      expect(restored.status, DocumentJobStatus.partial);
      expect(restored.failures.single.rowNumber, 2);
      expect(restored.failures.single.code, 'document_factory.rowRender');
    });

    test(
      'completed jobs older than 30 days are pruned; running kept',
      () async {
        final store = SharedPreferencesDocumentFactoryStore();
        final old = _job(
          startedAt: DateTime.now().toUtc().subtract(const Duration(days: 40)),
        );
        await store.writeLastJob(old);
        expect(await store.readLastJob(), isNull);

        final runningOld = _job(
          status: DocumentJobStatus.running,
          startedAt: DateTime.now().toUtc().subtract(const Duration(days: 40)),
        );
        await store.writeLastJob(runningOld);
        final restored = await store.readLastJob();
        expect(restored, isNotNull);
        expect(restored!.status, DocumentJobStatus.running);
      },
    );

    test('readLastJob returns null when nothing stored', () async {
      final store = SharedPreferencesDocumentFactoryStore();
      expect(await store.readLastJob(), isNull);
    });
  });
}
