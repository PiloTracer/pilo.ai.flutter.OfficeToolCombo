import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/storage/app_database.dart';
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('InventoryView leaves loading state with in-memory db', (
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

    expect(find.text('Loading inventory…'), findsNothing);
    expect(find.text('No items yet'), findsWidgets);
  });
}
