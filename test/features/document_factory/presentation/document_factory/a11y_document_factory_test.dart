import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_template.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_providers.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class FakeDocumentFactoryRepository implements DocumentFactoryRepository {
  DocumentJob? lastJob;

  @override
  Future<Result<String?>> pickTemplateFile() async =>
      const Success<String?>('/tmp/letter.html');

  @override
  Future<Result<String?>> pickDataSheetFile() async =>
      const Success<String?>('/tmp/data.xlsx');

  @override
  Future<Result<String?>> pickOutputFolder() async =>
      const Success<String?>('/tmp/out');

  @override
  Future<Result<TemplateInspection>> inspectTemplate(String path) async {
    return const Success<TemplateInspection>(
      TemplateInspection(
        template: DocumentTemplate(
          filePath: '/tmp/letter.html',
          placeholders: ['Name'],
        ),
        restoredMapping: null,
      ),
    );
  }

  @override
  Future<Result<SheetInspection>> inspectDataSheet(String path) async {
    return const Success<SheetInspection>(
      SheetInspection(headers: ['Name'], dataRowCount: 3),
    );
  }

  @override
  Future<Result<void>> saveMapping(
    String templatePath,
    Map<String, String> mapping,
  ) async => const Success<void>(null);

  @override
  Future<Result<DocumentJob>> runBatch({
    required String templatePath,
    required String dataSheetPath,
    required String outputDirPath,
    required Map<String, String> mapping,
    void Function(DocumentBatchProgress progress)? onProgress,
  }) async => const Err<DocumentJob>(IoFailure('unused'));

  @override
  Future<DocumentJob?> readLastJob() async => lastJob;

  @override
  Future<void> markLastJobInterrupted() async {
    final job = lastJob;
    if (job != null && job.status == DocumentJobStatus.running) {
      lastJob = job.copyWith(status: DocumentJobStatus.failed);
    }
  }

  @override
  Future<Result<void>> revealOutputFolder(String path) async =>
      const Success<void>(null);
}

void main() {
  late FakeDocumentFactoryRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeDocumentFactoryRepository();
  });

  Future<void> pumpView(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        documentFactoryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: UncontrolledProviderScope(
          container: container,
          child: buildL10nTestApp(
            theme: AppTheme.dark(),
            home: const DocumentFactoryView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('document factory renders without overflow at 200% text scale', (
    tester,
  ) async {
    await pumpView(tester, textScale: 2);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Choose template'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Choose data sheet'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Map fields'), findsOneWidget);
  });

  testWidgets('interrupted-job notice is exposed as a live region', (
    tester,
  ) async {
    repository.lastJob = DocumentJob(
      id: 'job-1',
      templatePath: '/tmp/letter.html',
      dataSheetPath: '/tmp/data.xlsx',
      outputDirPath: '/tmp/out',
      status: DocumentJobStatus.running,
      totalRows: 3,
      startedAt: DateTime.now().toUtc(),
    );
    await pumpView(tester);

    final notice = find.text(
      'The last job did not finish. You can start a new batch.',
    );
    expect(notice, findsOneWidget);
    expect(
      find.ancestor(
        of: notice,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
      findsWidgets,
    );
  });
}
