import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/widgets/merge_history_list.dart';

import '../../../../../helpers/l10n_test_harness.dart';

void main() {
  MergeHistoryEntry entry({
    String outputPath = '/tmp/out/report.xlsx',
    String fileName = 'report.xlsx',
    String status = 'succeeded',
    DateTime? mergedAt,
  }) {
    return MergeHistoryEntry(
      outputPath: outputPath,
      fileName: fileName,
      sourceFolderPath: '/tmp/source',
      mergedAt: mergedAt ?? DateTime(2026, 8, 1, 12, 30),
      status: status,
    );
  }

  Future<void> pumpList(
    WidgetTester tester, {
    required List<MergeHistoryEntry> entries,
    ValueChanged<String>? onOpen,
  }) async {
    await tester.pumpWithL10n(
      Scaffold(
        body: SizedBox(
          height: 400,
          child: MergeHistoryList(entries: entries, onOpen: onOpen ?? (_) {}),
        ),
      ),
      theme: AppTheme.dark(),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty history shows the placeholder message', (tester) async {
    await pumpList(tester, entries: const []);

    expect(find.text('Recent merges'), findsOneWidget);
    expect(
      find.text('Completed merges appear here. Up to 20 are kept.'),
      findsOneWidget,
    );
  });

  testWidgets('rows render the file name and formatted merge time', (
    tester,
  ) async {
    final first = entry(
      fileName: 'july.xlsx',
      mergedAt: DateTime(2026, 7, 15, 9, 5),
    );
    final second = entry(
      fileName: 'august.xlsx',
      mergedAt: DateTime(2026, 8, 1, 18, 45),
    );
    await pumpList(tester, entries: [first, second]);

    final format = DateFormat.yMMMd('en').add_jm();
    expect(find.text('july.xlsx'), findsOneWidget);
    expect(find.text(format.format(first.mergedAt)), findsOneWidget);
    expect(find.text('august.xlsx'), findsOneWidget);
    expect(find.text(format.format(second.mergedAt)), findsOneWidget);
  });

  testWidgets(
    'open button carries the tooltip and fires onOpen with the path',
    (tester) async {
      final opened = <String>[];
      await pumpList(
        tester,
        entries: [entry(outputPath: '/tmp/out/july.xlsx')],
        onOpen: opened.add,
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Open file location');

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pumpAndSettle();

      expect(opened, ['/tmp/out/july.xlsx']);
    },
  );

  testWidgets('partial entries use the warning icon variant', (tester) async {
    await pumpList(
      tester,
      entries: [
        entry(fileName: 'partial.xlsx', status: 'partial'),
        entry(fileName: 'full.xlsx', status: 'succeeded'),
      ],
    );

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
  });
}
