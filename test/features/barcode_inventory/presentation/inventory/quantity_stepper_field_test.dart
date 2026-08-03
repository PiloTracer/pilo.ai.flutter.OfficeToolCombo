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

  testWidgets('external focus node handlers are chained, not clobbered', (
    tester,
  ) async {
    final controller = TextEditingController(text: '5');
    final focusNode = FocusNode();
    var previousHandlerCalls = 0;
    focusNode.onKeyEvent = (node, event) {
      // Count only key-downs: the stepper consumes downs it handles and
      // lets everything else (including key-ups) fall through.
      if (event is KeyDownEvent) {
        previousHandlerCalls++;
      }
      return KeyEventResult.handled;
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuantityStepperField(
            controller: controller,
            focusNode: focusNode,
            label: 'Qty',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // A key the stepper consumes must not reach the previous handler…
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controller.text, '6');
    expect(previousHandlerCalls, 0);

    // …but keys the stepper ignores fall through to it.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();
    expect(previousHandlerCalls, 1);

    // Removing the widget restores the external node's original handler.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(focusNode.onKeyEvent, isNotNull);
    focusNode.dispose();
  });

  testWidgets('switching focusNode re-attaches key handling to the new node', (
    tester,
  ) async {
    final controller = TextEditingController(text: '5');
    final firstNode = FocusNode();
    final secondNode = FocusNode();

    Widget buildWith(FocusNode node) => MaterialApp(
      home: Scaffold(
        body: QuantityStepperField(
          controller: controller,
          focusNode: node,
          label: 'Qty',
        ),
      ),
    );

    await tester.pumpWidget(buildWith(firstNode));
    await tester.pumpWidget(buildWith(secondNode));

    // Old node is fully detached, new node drives the stepper.
    expect(firstNode.onKeyEvent, isNull);
    expect(secondNode.onKeyEvent, isNotNull);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controller.text, '6');

    firstNode.dispose();
    secondNode.dispose();
  });
}
