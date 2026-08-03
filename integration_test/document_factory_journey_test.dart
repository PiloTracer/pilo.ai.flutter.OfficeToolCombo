// F3-T6 — offline document-factory journey: generate personalized PDFs from
// an Excel data sheet and keep the placeholder mapping across app restarts
// (SPEC A3).
//
// Written with the plain widgets binding so it runs under
// `flutter test integration_test/` (same pattern as locale_persist_test.dart).
// The three file/folder pickers are platform channels, so they are faked by
// subclassing the production repository; everything else — template parsing,
// xlsx decoding, PDF rendering in the batch isolate, and the
// SharedPreferences-backed mapping store — is production code. All file IO
// stays in temp dirs.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/document_factory/data/repositories/document_factory_repository_impl.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_providers.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_view.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/consolidator_test_fixtures.dart';

/// Production repository with only the FilePicker platform channels faked
/// out; template inspection, batch generation and the mapping store stay
/// real.
class _FakePickDocumentFactoryRepository extends DocumentFactoryRepositoryImpl {
  _FakePickDocumentFactoryRepository({
    required this.templatePath,
    required this.dataSheetPath,
    required this.outputDirPath,
  });

  final String templatePath;
  final String dataSheetPath;
  final String outputDirPath;

  @override
  Future<Result<String?>> pickTemplateFile() async {
    return Success<String?>(templatePath);
  }

  @override
  Future<Result<String?>> pickDataSheetFile() async {
    return Success<String?>(dataSheetPath);
  }

  @override
  Future<Result<String?>> pickOutputFolder() async {
    return Success<String?>(outputDirPath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline batch generates PDFs; mapping survives a restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final workDir = await Directory.systemTemp.createTemp(
      'document_factory_journey_',
    );
    addTearDown(() async {
      if (workDir.existsSync()) {
        await workDir.delete(recursive: true);
      }
    });
    final outputDir = await Directory(
      '${workDir.path}${Platform.pathSeparator}pdfs',
    ).create();

    final templateFile = File(
      '${workDir.path}${Platform.pathSeparator}letter.html',
    );
    await templateFile.writeAsString(
      '<h1>Invoice</h1><p>Prepared for {{Name}}</p>',
    );

    await ConsolidatorTestFixtures.writeWorkbook(
      directory: workDir,
      fileName: 'recipients.xlsx',
      rows: [
        ['Name'],
        ['Alice'],
        ['Bob'],
        ['Carol'],
      ],
    );

    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DocumentFactoryRepositoryImpl buildRepository() {
      return _FakePickDocumentFactoryRepository(
        templatePath: templateFile.path,
        dataSheetPath:
            '${workDir.path}${Platform.pathSeparator}recipients.xlsx',
        outputDirPath: outputDir.path,
      );
    }

    Future<void> bootFreshApp() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentFactoryRepositoryProvider.overrideWithValue(
              buildRepository(),
            ),
          ],
          child: OfficeToolComboApp(logger: AppLogger()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<ProviderContainer> navigateToDocumentFactory() async {
      await tester.tap(find.text('Document factory'));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(DocumentFactoryView)),
      );
    }

    // First boot: home → document factory → pick inputs (faked pickers),
    // map the placeholder, save the mapping and run the batch.
    await bootFreshApp();
    expect(find.text('Choose a tool'), findsOneWidget);
    final container = await navigateToDocumentFactory();

    final viewModel = container.read(documentFactoryViewModelProvider.notifier);
    await viewModel.pickTemplate();
    await viewModel.pickDataSheet();
    await viewModel.pickOutputFolder();
    await tester.pumpAndSettle();

    viewModel.updateMapping('Name', 'Name');
    await tester.pumpAndSettle();
    expect(await viewModel.saveMapping(), isTrue);

    await viewModel.generate();
    await tester.pumpAndSettle();

    // Success state rendered.
    expect(find.text('PDFs generated'), findsOneWidget);
    expect(
      find.text(
        '3 PDFs saved to ${outputDir.path.split(Platform.pathSeparator).last}',
      ),
      findsOneWidget,
    );

    // One PDF per data row on disk.
    for (final name in ['1.pdf', '2.pdf', '3.pdf']) {
      expect(
        File('${outputDir.path}${Platform.pathSeparator}$name').existsSync(),
        isTrue,
        reason: '$name should exist',
      );
    }

    // Full restart: fresh ProviderScope; the SharedPreferences mock backend
    // persists the saved mapping.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await bootFreshApp();

    final restartedContainer = await navigateToDocumentFactory();
    final restartedViewModel = restartedContainer.read(
      documentFactoryViewModelProvider.notifier,
    );

    // SPEC A3: selecting the same template restores the saved mapping.
    await restartedViewModel.pickTemplate();
    await tester.pumpAndSettle();

    final restoredState = restartedContainer.read(
      documentFactoryViewModelProvider,
    );
    expect(restoredState.templatePath, templateFile.path);
    expect(restoredState.mapping, {'Name': 'Name'});
    expect(restoredState.mappingDirty, isFalse);
  });
}
