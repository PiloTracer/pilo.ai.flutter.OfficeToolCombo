import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/workbook_batch.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_providers.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view.dart';

import '../../../../helpers/l10n_test_harness.dart';
import '../../fakes/fake_consolidator_repository.dart';

void main() {
  late FakeConsolidatorRepository repository;

  setUp(() {
    repository = FakeConsolidatorRepository();
  });

  Future<void> pumpView(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ProviderScope(
          overrides: [
            consolidatorRepositoryProvider.overrideWithValue(repository),
          ],
          child: buildL10nTestApp(
            theme: AppTheme.dark(),
            home: const ConsolidatorView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('consolidator renders without overflow at 200% text scale', (
    tester,
  ) async {
    await pumpView(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Merge Excel reports'), findsOneWidget);
  });

  testWidgets('merge progress is a live region announcing the percent', (
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

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label == 'Merge progress 50 percent',
      ),
      findsOneWidget,
    );

    repository.consolidateCompleter!.complete(
      Success<WorkbookBatch>(buildBatch()),
    );
    await tester.pumpAndSettle();
  });
}
