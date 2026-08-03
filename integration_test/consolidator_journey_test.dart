// F1-T6 — offline consolidator journey: merge a folder of Excel reports and
// keep the merge history across app restarts.
//
// Written with the plain widgets binding so it runs under
// `flutter test integration_test/` (same pattern as locale_persist_test.dart).
// The app boots for real; only the folder picker — a platform channel — is
// faked by overriding `consolidatorRepositoryProvider`'s pick methods. The
// merge itself, the xlsx parsing and the SharedPreferences-backed history
// store are all production code. All file IO stays in temp dirs.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/report_consolidator/data/repositories/consolidator_repository_impl.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_providers.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/consolidator_test_fixtures.dart';

/// Production repository with only the FilePicker platform channel faked out;
/// the merge pipeline and the SharedPreferences history store stay real.
class _FakePickConsolidatorRepository extends ConsolidatorRepositoryImpl {
  _FakePickConsolidatorRepository({required this.sourceFolderPath});

  final String sourceFolderPath;

  @override
  Future<Result<String?>> pickSourceFolder() async {
    return Success<String?>(sourceFolderPath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('merge a source folder; history survives a full restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final sourceDir = await Directory.systemTemp.createTemp(
      'consolidator_journey_src_',
    );
    addTearDown(() async {
      if (sourceDir.existsSync()) {
        await sourceDir.delete(recursive: true);
      }
    });

    await ConsolidatorTestFixtures.writeWorkbook(
      directory: sourceDir,
      fileName: 'report_alpha.xlsx',
      rows: [
        ['Name', 'Amount'],
        ['Alpha', '10'],
      ],
    );
    await ConsolidatorTestFixtures.writeWorkbook(
      directory: sourceDir,
      fileName: 'report_beta.xlsx',
      rows: [
        ['Name', 'Amount'],
        ['Beta', '20'],
      ],
    );

    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> bootFreshApp() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consolidatorRepositoryProvider.overrideWithValue(
              _FakePickConsolidatorRepository(sourceFolderPath: sourceDir.path),
            ),
          ],
          child: OfficeToolComboApp(logger: AppLogger()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<ProviderContainer> navigateToConsolidator() async {
      await tester.tap(find.text('Report consolidator'));
      await tester.pumpAndSettle();
      expect(find.text('Merge Excel reports'), findsOneWidget);
      return ProviderScope.containerOf(
        tester.element(find.byType(ConsolidatorView)),
      );
    }

    // First boot: home → consolidator → merge.
    await bootFreshApp();
    expect(find.text('Choose a tool'), findsOneWidget);
    final container = await navigateToConsolidator();

    await container
        .read(consolidatorViewModelProvider.notifier)
        .pickFolderAndMerge();
    await tester.pumpAndSettle();

    // Success state rendered.
    expect(find.text('Merge complete'), findsOneWidget);

    // The consolidated workbook landed in the output folder (default: the
    // source folder).
    final outputs = sourceDir
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.startsWith('consolidated_'))
        .toList();
    expect(outputs, hasLength(1));
    final outputFileName = outputs.single;

    // Full restart: tear the tree down, boot a brand-new app instance with a
    // fresh ProviderScope (the SharedPreferences mock backend persists).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await bootFreshApp();

    await navigateToConsolidator();

    // The merge-history entry written by the first session is visible again.
    expect(find.text('Recent merges'), findsOneWidget);
    expect(find.text(outputFileName), findsOneWidget);
  });
}
