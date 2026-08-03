import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_providers.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view.dart';

import '../../../../helpers/l10n_test_harness.dart';
import '../../fakes/fake_consolidator_repository.dart';

void main() {
  late FakeConsolidatorRepository repository;

  setUp(() {
    repository = FakeConsolidatorRepository();
  });

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consolidatorRepositoryProvider.overrideWithValue(repository),
        ],
        child: buildL10nTestApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const ConsolidatorView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapMergeCta(
    WidgetTester tester, {
    String label = 'Choose folder and merge',
  }) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('initial state shows headline, default output and enabled CTA', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('Merge Excel reports'), findsOneWidget);
    expect(find.text('Same as the source folder (default)'), findsOneWidget);
    expect(find.text('Recent merges'), findsOneWidget);
    expect(
      find.text('Completed merges appear here. Up to 20 are kept.'),
      findsOneWidget,
    );

    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Choose folder and merge'),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('saved output folder shows path and can be changed or cleared', (
    tester,
  ) async {
    repository.savedOutputFolderPath = '/tmp/saved-out';
    await pumpView(tester);

    expect(find.text('/tmp/saved-out'), findsOneWidget);
    expect(find.text('Use source folder'), findsOneWidget);

    repository.pickOutputFolderResult = const Success<String?>('/tmp/new-out');
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Choose output folder'),
    );
    await tester.pumpAndSettle();
    expect(find.text('/tmp/new-out'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Use source folder'));
    await tester.pumpAndSettle();
    expect(find.text('Same as the source folder (default)'), findsOneWidget);
  });

  testWidgets('loading state shows progress and disables the CTA', (
    tester,
  ) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.progressToEmit = const [0.5];
    repository.consolidateCompleter = Completer<Result<WorkbookBatch>>();
    await pumpView(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Choose folder and merge'),
    );
    await tester.pump();
    await tester.pump();

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.5);
    expect(find.text('Merging spreadsheets… 50%'), findsOneWidget);
    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Choose folder and merge'),
    );
    expect(cta.onPressed, isNull);

    repository.consolidateCompleter!.complete(
      Success<WorkbookBatch>(buildBatch()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Merge complete'), findsOneWidget);
  });

  testWidgets('empty folder shows the no-spreadsheets panel', (tester) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = const Err<WorkbookBatch>(
      IoFailure(EmptyFolderFailure.emptyFolderMessage),
    );
    await pumpView(tester);

    await tapMergeCta(tester);

    expect(find.text('No spreadsheets found'), findsOneWidget);
    expect(
      find.text(
        'That folder did not contain any .xlsx files. '
        'Try a different folder with Excel reports inside.',
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Choose another folder'),
      findsOneWidget,
    );
  });

  testWidgets('success shows Merge complete, saved file and history entry', (
    tester,
  ) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = Success<WorkbookBatch>(buildBatch());
    repository.mergeHistory = [buildHistoryEntry(fileName: 'merged_july.xlsx')];
    await pumpView(tester);

    await tapMergeCta(tester);

    expect(find.text('Merge complete'), findsOneWidget);
    expect(find.text('Saved as consolidated_2026-08-01.xlsx'), findsOneWidget);
    expect(find.text('merged_july.xlsx'), findsOneWidget);
  });

  testWidgets('partial shows warning copy and the failure list', (
    tester,
  ) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = Success<WorkbookBatch>(
      buildBatch(
        status: WorkbookBatchStatus.partial,
        files: const [
          SpreadsheetFileResult(
            fileName: 'good.xlsx',
            parseStatus: SpreadsheetParseStatus.success,
          ),
          SpreadsheetFileResult(
            fileName: 'broken.xlsx',
            parseStatus: SpreadsheetParseStatus.failed,
            errorMessage: 'Could not parse workbook',
          ),
        ],
      ),
    );
    await pumpView(tester);

    await tapMergeCta(tester);

    expect(find.text('Merged with some failures'), findsOneWidget);
    expect(find.text('Files that need attention'), findsOneWidget);
    expect(find.text('broken.xlsx'), findsOneWidget);
    expect(find.text('Could not parse workbook'), findsOneWidget);
  });

  testWidgets('error shows the failure message and Try again retries', (
    tester,
  ) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = const Err<WorkbookBatch>(
      IoFailure('disk full'),
    );
    await pumpView(tester);

    await tapMergeCta(tester);

    expect(find.text('Merge could not finish'), findsOneWidget);
    expect(find.text('disk full'), findsOneWidget);

    repository.consolidateResult = Success<WorkbookBatch>(buildBatch());
    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Merge complete'), findsOneWidget);
    expect(repository.consolidateCalls, 2);
  });

  testWidgets('failed batch shows the batch error message', (tester) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = Success<WorkbookBatch>(
      buildBatch(
        status: WorkbookBatchStatus.failed,
        outputPath: null,
        errorMessage: 'Every file failed to parse',
        files: const [
          SpreadsheetFileResult(
            fileName: 'broken.xlsx',
            parseStatus: SpreadsheetParseStatus.failed,
          ),
        ],
      ),
    );
    await pumpView(tester);

    await tapMergeCta(tester);

    expect(find.text('Merge could not finish'), findsOneWidget);
    expect(find.text('Every file failed to parse'), findsOneWidget);
  });

  testWidgets('(es) idle and success states render in Spanish', (tester) async {
    repository.pickSourceFolderResult = const Success<String?>('/tmp/source');
    repository.consolidateResult = Success<WorkbookBatch>(buildBatch());
    await pumpView(tester, locale: const Locale('es'));

    expect(find.text('Combina informes de Excel'), findsOneWidget);
    expect(
      find.text('Igual que la carpeta de origen (predeterminado)'),
      findsOneWidget,
    );

    await tapMergeCta(tester, label: 'Elegir carpeta y combinar');

    expect(find.text('Combinación completada'), findsOneWidget);
    expect(
      find.text('Guardado como consolidated_2026-08-01.xlsx'),
      findsOneWidget,
    );
  });
}
