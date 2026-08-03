import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/inventory_dialogs.dart';

import '../../../../helpers/l10n_test_harness.dart';

void main() {
  /// Pumps a host button that opens [dialogBuilder] via [showDialog] and
  /// captures its result. Returns a reader for the captured result.
  Future<T? Function()> pumpAndOpenDialog<T>(
    WidgetTester tester,
    WidgetBuilder dialogBuilder, {
    Locale locale = const Locale('en'),
  }) async {
    T? result;
    await tester.pumpWithL10n(
      locale: locale,
      theme: AppTheme.dark(),
      Builder(
        builder: (context) {
          return Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<T>(
                  context: context,
                  builder: dialogBuilder,
                );
              },
              child: const Text('Open dialog'),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    return () => result;
  }

  Finder textFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
  }

  group('CreateItemDialog', () {
    Future<CreateItemResult? Function()> openCreateDialog(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      String? errorMessage,
    }) {
      return pumpAndOpenDialog<CreateItemResult>(
        tester,
        (context) =>
            CreateItemDialog(barcode: 'ABC-123', errorMessage: errorMessage),
        locale: locale,
      );
    }

    testWidgets('renders barcode, fields and actions (en)', (tester) async {
      await openCreateDialog(tester);

      expect(find.text('New item'), findsOneWidget);
      expect(find.text('ABC-123'), findsOneWidget);
      expect(textFieldByLabel('Barcode / identifier'), findsOneWidget);
      expect(textFieldByLabel('Item name'), findsOneWidget);
      expect(textFieldByLabel('Starting quantity'), findsOneWidget);
      expect(textFieldByLabel('Description'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add item'), findsOneWidget);
      // Starting quantity defaults to 1.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('cancel returns null', (tester) async {
      final readResult = await openCreateDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(readResult(), isNull);
      expect(find.text('New item'), findsNothing);
    });

    testWidgets('filled form returns the entered values', (tester) async {
      final readResult = await openCreateDialog(tester);

      await tester.enterText(textFieldByLabel('Item name'), 'Hex bolt');
      await tester.enterText(textFieldByLabel('Starting quantity'), '12');
      await tester.enterText(textFieldByLabel('Description'), 'M8, box of 50');
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      final result = readResult();
      expect(result, isNotNull);
      expect(result!.name, 'Hex bolt');
      expect(result.quantity, 12);
      expect(result.description, 'M8, box of 50');
    });

    testWidgets('empty name shows validation error (en)', (tester) async {
      final readResult = await openCreateDialog(tester);

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an item name'), findsOneWidget);
      expect(readResult(), isNull);
    });

    testWidgets('empty quantity shows validation error (en)', (tester) async {
      final readResult = await openCreateDialog(tester);

      await tester.enterText(textFieldByLabel('Item name'), 'Hex bolt');
      await tester.enterText(textFieldByLabel('Starting quantity'), '');
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid quantity'), findsOneWidget);
      expect(readResult(), isNull);
    });

    testWidgets('empty name shows validation error (es)', (tester) async {
      final readResult = await openCreateDialog(
        tester,
        locale: const Locale('es'),
      );

      expect(find.text('Nuevo artículo'), findsOneWidget);
      await tester.tap(find.text('Añadir artículo'));
      await tester.pumpAndSettle();

      expect(find.text('Introduce un nombre de artículo'), findsOneWidget);
      expect(readResult(), isNull);
    });

    testWidgets('external error message is displayed', (tester) async {
      await openCreateDialog(tester, errorMessage: 'Duplicate barcode');

      expect(find.text('Duplicate barcode'), findsOneWidget);
    });
  });

  group('CountQuantityDialog', () {
    Future<int? Function()> openCountDialog(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) {
      return pumpAndOpenDialog<int>(
        tester,
        (context) =>
            const CountQuantityDialog(barcode: 'XYZ-9', currentQuantity: 5),
        locale: locale,
      );
    }

    testWidgets('renders identifier and current quantity (en)', (tester) async {
      await openCountDialog(tester);

      expect(find.text('Set counted quantity'), findsOneWidget);
      expect(find.text('Identifier: XYZ-9'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Set quantity'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirm returns the entered quantity', (tester) async {
      final readResult = await openCountDialog(tester);

      await tester.enterText(textFieldByLabel('Quantity on hand'), '17');
      await tester.tap(find.text('Set quantity'));
      await tester.pumpAndSettle();

      expect(readResult(), 17);
    });

    testWidgets('cancel returns null', (tester) async {
      final readResult = await openCountDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(readResult(), isNull);
    });

    testWidgets('invalid quantity shows validation error (en)', (tester) async {
      final readResult = await openCountDialog(tester);

      await tester.enterText(textFieldByLabel('Quantity on hand'), '');
      await tester.tap(find.text('Set quantity'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid quantity'), findsOneWidget);
      expect(readResult(), isNull);
    });

    testWidgets('invalid quantity shows validation error (es)', (tester) async {
      final readResult = await openCountDialog(
        tester,
        locale: const Locale('es'),
      );

      expect(find.text('Establecer cantidad contada'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Establecer cantidad'));
      await tester.pumpAndSettle();

      expect(find.text('Introduce una cantidad válida'), findsOneWidget);
      expect(readResult(), isNull);
    });
  });

  group('EditItemDialog', () {
    Future<({String name, String description, int quantity})? Function()>
    openEditDialog(WidgetTester tester) {
      return pumpAndOpenDialog<
        ({String name, String description, int quantity})
      >(
        tester,
        (context) => const EditItemDialog(
          name: 'Hex bolt',
          description: 'M8, box of 50',
          quantity: 4,
        ),
      );
    }

    testWidgets('renders prefilled fields (en)', (tester) async {
      await openEditDialog(tester);

      expect(find.text('Edit item'), findsOneWidget);
      expect(find.text('Hex bolt'), findsOneWidget);
      expect(find.text('M8, box of 50'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('save returns the edited values', (tester) async {
      final readResult = await openEditDialog(tester);

      await tester.enterText(textFieldByLabel('Item name'), 'Hex bolt M10');
      await tester.enterText(textFieldByLabel('Description'), 'Shelf B2');
      await tester.enterText(textFieldByLabel('Quantity on hand'), '9');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final result = readResult();
      expect(result, isNotNull);
      expect(result!.name, 'Hex bolt M10');
      expect(result.description, 'Shelf B2');
      expect(result.quantity, 9);
    });

    testWidgets('cancel returns null', (tester) async {
      final readResult = await openEditDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(readResult(), isNull);
    });

    testWidgets('empty name keeps the dialog open', (tester) async {
      final readResult = await openEditDialog(tester);

      await tester.enterText(textFieldByLabel('Item name'), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Edit item'), findsOneWidget);
      expect(readResult(), isNull);
    });
  });
}
