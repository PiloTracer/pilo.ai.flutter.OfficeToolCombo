import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/storage/app_database.dart';
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/inventory_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Pumps the harness and opens the dialog. Returns a reader for the
  /// dialog's eventual result (still null until the dialog is dismissed).
  Future<bool? Function()> pumpAndOpenDialog(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    bool? result;
    await tester.pumpWithL10n(
      locale: locale,
      Builder(
        builder: (context) {
          return Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ImportConfirmationDialog(),
                );
              },
              child: const Text('Open import'),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('Open import'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('import confirmation dialog: confirm returns true', (
    tester,
  ) async {
    final readResult = await pumpAndOpenDialog(tester);
    expect(find.text('Replace current inventory?'), findsOneWidget);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(readResult(), isTrue);
  });

  testWidgets('import confirmation dialog: cancel returns false', (
    tester,
  ) async {
    final readResult = await pumpAndOpenDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(readResult(), isFalse);
    expect(find.text('Replace current inventory?'), findsNothing);
  });

  testWidgets('import confirmation dialog localizes to Spanish', (
    tester,
  ) async {
    final readResult = await pumpAndOpenDialog(tester, locale: const Locale('es'));
    expect(find.text('¿Reemplazar el inventario actual?'), findsOneWidget);

    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();

    expect(readResult(), isTrue);
  });

  testWidgets('InventoryView import menu asks for confirmation; cancel aborts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: buildL10nTestApp(
          theme: AppTheme.dark(),
          home: const InventoryView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Open the overflow menu and choose Import CSV.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Replace current inventory?'), findsOneWidget);

    // Cancel: dialog closes, nothing imported, no error surfaces.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Replace current inventory?'), findsNothing);
    expect(find.text('Could not load inventory'), findsNothing);
  });
}
