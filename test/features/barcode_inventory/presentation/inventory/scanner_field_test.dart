import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/scanner_field.dart';

void main() {
  testWidgets('scanner starts focused when captureFocus is true', (
    tester,
  ) async {
    final scanFocus = FocusNode();
    final scanController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScannerField(
            controller: scanController,
            focusNode: scanFocus,
            enabled: true,
            captureFocus: true,
            onSubmitted: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(scanFocus.hasFocus, isTrue);
  });

  testWidgets('scanner does not steal focus from search field', (tester) async {
    final scanFocus = FocusNode();
    final searchFocus = FocusNode();
    final scanController = TextEditingController();
    final searchController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScannerField(
                controller: scanController,
                focusNode: scanFocus,
                enabled: true,
                captureFocus: true,
                onSubmitted: (_) async {},
              ),
              TextField(
                controller: searchController,
                focusNode: searchFocus,
                decoration: const InputDecoration(labelText: 'Search stock'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scanFocus.hasFocus, isTrue);

    await tester.tap(find.text('Search stock'));
    await tester.pumpAndSettle();

    expect(searchFocus.hasFocus, isTrue);
    expect(scanFocus.hasFocus, isFalse);

    await tester.enterText(find.byType(TextField).last, 'bolt');
    await tester.pumpAndSettle();

    expect(searchController.text, 'bolt');
    expect(searchFocus.hasFocus, isTrue);
  });

  testWidgets(
    'scanner refocuses after scan when no other text field is active',
    (tester) async {
      final scanFocus = FocusNode();
      final scanController = TextEditingController();
      var submitted = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannerField(
              controller: scanController,
              focusNode: scanFocus,
              enabled: true,
              captureFocus: true,
              onSubmitted: (value) async {
                submitted = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ABC-123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submitted, 'ABC-123');
      expect(scanFocus.hasFocus, isTrue);
    },
  );

  testWidgets('captureFocus false leaves other fields alone', (tester) async {
    final scanFocus = FocusNode();
    final otherFocus = FocusNode();
    final scanController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScannerField(
                controller: scanController,
                focusNode: scanFocus,
                enabled: true,
                captureFocus: false,
                onSubmitted: (_) async {},
              ),
              TextField(
                focusNode: otherFocus,
                decoration: const InputDecoration(labelText: 'Other'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    expect(otherFocus.hasFocus, isTrue);
    expect(scanFocus.hasFocus, isFalse);
  });
}
