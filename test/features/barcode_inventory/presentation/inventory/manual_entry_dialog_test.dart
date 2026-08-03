import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/inventory_dialogs.dart';

import '../../../../helpers/l10n_test_harness.dart';

void main() {
  testWidgets('ManualEntryDialog accepts typed identifier and submits', (
    tester,
  ) async {
    String? result;

    await tester.pumpWithL10n(
      Builder(
        builder: (context) {
          return Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (context) => const ManualEntryDialog(),
                );
              },
              child: const Text('Open manual entry'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Open manual entry'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'MANUAL-123');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(result, 'MANUAL-123');
  });

  testWidgets('ManualEntryDialog keeps focus for typing', (tester) async {
    await tester.pumpWithL10n(
      Builder(
        builder: (context) {
          return Scaffold(
            body: FilledButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const ManualEntryDialog(),
                );
              },
              child: const Text('Open manual entry'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Open manual entry'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);

    await tester.enterText(find.byType(TextField), '8054041617576');
    expect(find.text('8054041617576'), findsOneWidget);
  });

  testWidgets('ManualEntryDialog shows validation when empty', (tester) async {
    await tester.pumpWithL10n(
      Builder(
        builder: (context) {
          return Scaffold(
            body: FilledButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const ManualEntryDialog(),
                );
              },
              child: const Text('Open manual entry'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Open manual entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a barcode or identifier'), findsOneWidget);
  });
}
