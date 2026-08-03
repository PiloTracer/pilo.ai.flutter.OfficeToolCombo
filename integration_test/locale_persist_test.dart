// FL10N-T3 — locale persistence across app restarts.
//
// Written with the plain widgets binding so it runs under
// `flutter test integration_test/` on any host; the on-device
// `integration_test` binding + CI target lands with the release pipeline.
// The restart is real: the first app instance writes through the production
// SharedPreferencesSettingsStore, the tree is torn down, and a brand-new
// app instance re-reads the persisted value.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chosen locale survives a full app restart', (tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> bootFreshApp() async {
      await tester.pumpWidget(
        ProviderScope(child: OfficeToolComboApp(logger: AppLogger())),
      );
      await tester.pumpAndSettle();
    }

    // First boot: system default (English in the test environment).
    await bootFreshApp();
    expect(find.text('Choose a tool'), findsOneWidget);

    // User picks Español; the choice is written to SharedPreferences.
    await tester.tap(find.byIcon(Icons.language_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Elige una herramienta'), findsOneWidget);

    // Full restart: tear the tree down and boot a brand-new app instance
    // with a fresh ProviderScope (no provider state carried over).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await bootFreshApp();

    expect(find.text('Elige una herramienta'), findsOneWidget);
    expect(find.text('Consolidador de informes'), findsOneWidget);

    // Switching back to system default must also persist.
    await tester.tap(find.byIcon(Icons.language_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predeterminado del sistema'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await bootFreshApp();

    expect(find.text('Choose a tool'), findsOneWidget);
  });
}
