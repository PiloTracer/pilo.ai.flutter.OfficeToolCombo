import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_template.dart';
import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_providers.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_view.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class FakeDocumentFactoryRepository implements DocumentFactoryRepository {
  String templatePath = '/tmp/letter.html';
  String dataSheetPath = '/tmp/data.xlsx';
  String outputDirPath = '/tmp/out';
  List<String> placeholders = const ['Name'];
  List<String> headers = const ['Name'];
  int dataRowCount = 3;
  Map<String, String>? restoredMapping;
  String? inspectTemplateErrorCode;
  String? inspectSheetErrorCode;
  String? runBatchErrorCode;
  DocumentJob? lastJob;
  DocumentJob? batchJob;
  final Map<String, Map<String, String>> savedMappings = {};

  @override
  Future<Result<String?>> pickTemplateFile() async =>
      Success<String?>(templatePath);

  @override
  Future<Result<String?>> pickDataSheetFile() async =>
      Success<String?>(dataSheetPath);

  @override
  Future<Result<String?>> pickOutputFolder() async =>
      Success<String?>(outputDirPath);

  @override
  Future<Result<TemplateInspection>> inspectTemplate(String path) async {
    final code = inspectTemplateErrorCode;
    if (code != null) {
      return Err<TemplateInspection>(IoFailure(code));
    }
    return Success<TemplateInspection>(
      TemplateInspection(
        template: DocumentTemplate(filePath: path, placeholders: placeholders),
        restoredMapping: restoredMapping,
      ),
    );
  }

  @override
  Future<Result<SheetInspection>> inspectDataSheet(String path) async {
    final code = inspectSheetErrorCode;
    if (code != null) {
      return Err<SheetInspection>(IoFailure(code));
    }
    return Success<SheetInspection>(
      SheetInspection(headers: headers, dataRowCount: dataRowCount),
    );
  }

  @override
  Future<Result<void>> saveMapping(
    String templatePath,
    Map<String, String> mapping,
  ) async {
    savedMappings[templatePath] = Map<String, String>.from(mapping);
    return const Success<void>(null);
  }

  @override
  Future<Result<DocumentJob>> runBatch({
    required String templatePath,
    required String dataSheetPath,
    required String outputDirPath,
    required Map<String, String> mapping,
    void Function(DocumentBatchProgress progress)? onProgress,
  }) async {
    final code = runBatchErrorCode;
    if (code != null) {
      return Err<DocumentJob>(IoFailure(code));
    }
    final job =
        batchJob ??
        DocumentJob(
          id: 'job-1',
          templatePath: templatePath,
          dataSheetPath: dataSheetPath,
          outputDirPath: outputDirPath,
          status: DocumentJobStatus.succeeded,
          totalRows: dataRowCount,
          startedAt: DateTime.now().toUtc(),
          doneCount: dataRowCount,
          finishedAt: DateTime.now().toUtc(),
        );
    lastJob = job;
    return Success<DocumentJob>(job);
  }

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

  Future<ProviderContainer> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1400, 2200);
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
      UncontrolledProviderScope(
        container: container,
        child: buildL10nTestApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const DocumentFactoryView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  DocumentFactoryViewModel viewModel(ProviderContainer container) {
    return container.read(documentFactoryViewModelProvider.notifier);
  }

  Future<void> selectTemplateAndSheet(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await viewModel(container).pickTemplate();
    await viewModel(container).pickDataSheet();
    await tester.pumpAndSettle();
  }

  testWidgets('A4: unmapped placeholders disable Generate and show hint', (
    tester,
  ) async {
    final container = await pumpView(tester);
    await selectTemplateAndSheet(tester, container);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Generate PDFs'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Map all placeholders before generating'), findsOneWidget);
  });

  testWidgets('A4 (es): hint is localized', (tester) async {
    final container = await pumpView(tester, locale: const Locale('es'));
    await selectTemplateAndSheet(tester, container);

    expect(
      find.text('Mapee todos los marcadores antes de generar'),
      findsOneWidget,
    );
  });

  testWidgets(
    'mapping all placeholders enables Generate; batch shows success',
    (tester) async {
      final container = await pumpView(tester);
      await selectTemplateAndSheet(tester, container);
      await viewModel(container).pickOutputFolder();

      viewModel(container).updateMapping('Name', 'Name');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Generate PDFs'),
      );
      expect(button.onPressed, isNotNull);

      await viewModel(container).generate();
      await tester.pumpAndSettle();

      expect(find.text('PDFs generated'), findsOneWidget);
      expect(find.text('3 PDFs saved to out'), findsOneWidget);
      expect(find.text('Open output folder'), findsOneWidget);
    },
  );

  testWidgets('saving the mapping shows the confirmation snackbar', (
    tester,
  ) async {
    final container = await pumpView(tester);
    await selectTemplateAndSheet(tester, container);
    viewModel(container).updateMapping('Name', 'Name');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save mapping'));
    await tester.pumpAndSettle();

    expect(find.text('Mapping saved'), findsOneWidget);
    expect(repository.savedMappings['/tmp/letter.html'], {'Name': 'Name'});
  });

  testWidgets('unreadable template shows the specific error and Try again', (
    tester,
  ) async {
    repository.inspectTemplateErrorCode =
        DocumentFactoryFailureCodes.templateRead;
    final container = await pumpView(tester);

    await viewModel(container).pickTemplate();
    await tester.pumpAndSettle();

    expect(find.text('Batch failed'), findsOneWidget);
    expect(
      find.text('Could not read the template file. Choose a different file.'),
      findsOneWidget,
    );

    // Try again re-enables the flow without clearing selections.
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Batch failed'), findsNothing);
  });

  testWidgets('unreadable data sheet shows the specific error', (tester) async {
    repository.inspectSheetErrorCode = DocumentFactoryFailureCodes.sheetRead;
    final container = await pumpView(tester);

    await viewModel(container).pickDataSheet();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not read the data sheet. Choose a different .xlsx file.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('duplicate headers surface their specific message', (
    tester,
  ) async {
    repository.inspectSheetErrorCode =
        DocumentFactoryFailureCodes.duplicateHeaders;
    final container = await pumpView(tester);

    await viewModel(container).pickDataSheet();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The data sheet has duplicate column headers. Fix the sheet and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('A7: non-writable output folder blocks the batch with error', (
    tester,
  ) async {
    repository.runBatchErrorCode =
        DocumentFactoryFailureCodes.outputNotWritable;
    final container = await pumpView(tester);
    await selectTemplateAndSheet(tester, container);
    viewModel(container).updateMapping('Name', 'Name');
    await viewModel(container).pickOutputFolder();
    await tester.pumpAndSettle();

    await viewModel(container).generate();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Cannot write to the output folder. Choose a folder where you have permission to save files.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('zero placeholders show a warning instead of the editor', (
    tester,
  ) async {
    repository.placeholders = const [];
    final container = await pumpView(tester);
    await selectTemplateAndSheet(tester, container);

    expect(
      find.text(
        'No placeholders found in this template. Use a template with {{FieldName}} tokens.',
      ),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Generate PDFs'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('interrupted running job shows the relaunch notice', (
    tester,
  ) async {
    repository.lastJob = DocumentJob(
      id: 'job-run',
      templatePath: '/tmp/letter.html',
      dataSheetPath: '/tmp/data.xlsx',
      outputDirPath: '/tmp/out',
      status: DocumentJobStatus.running,
      totalRows: 10,
      startedAt: DateTime.now().toUtc(),
    );
    await pumpView(tester);

    expect(
      find.text('The last job did not finish. You can start a new batch.'),
      findsOneWidget,
    );
    // The stale record was flagged as interrupted.
    expect(repository.lastJob!.status, DocumentJobStatus.failed);
  });

  testWidgets('empty state shows unselected selectors and hidden editor hint', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('No template selected'), findsOneWidget);
    expect(find.text('No data sheet selected'), findsOneWidget);
    expect(
      find.text('Select a template and data sheet to map fields'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Generate PDFs'),
    );
    expect(button.onPressed, isNull);
  });
}
