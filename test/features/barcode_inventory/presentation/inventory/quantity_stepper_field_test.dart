import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/quantity_stepper_field.dart';

void main() {
  testWidgets('arrow and plus/minus keys adjust quantity', (tester) async {
    final controller = TextEditingController(text: '5');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuantityStepperField(controller: controller, label: 'Qty'),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controller.text, '6');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.text, '5');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(controller.text, '6');

    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pumpAndSettle();
    expect(controller.text, '5');
  });

  testWidgets('Enter moves focus forward and Shift+Enter moves back', (
    tester,
  ) async {
    final qtyController = TextEditingController(text: '1');
    final qtyFocusNode = FocusNode();
    final nextFocus = FocusNode();
    final previousFocus = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Focus(
                focusNode: previousFocus,
                child: const TextField(
                  decoration: InputDecoration(labelText: 'Previous'),
                ),
              ),
              QuantityStepperField(
                controller: qtyController,
                focusNode: qtyFocusNode,
                label: 'Qty',
              ),
              Focus(
                focusNode: nextFocus,
                child: const TextField(
                  decoration: InputDecoration(labelText: 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).at(1));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(nextFocus.hasFocus, isTrue);

    await tester.tap(find.byType(TextField).at(1));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(previousFocus.hasFocus, isTrue);
  });
}
