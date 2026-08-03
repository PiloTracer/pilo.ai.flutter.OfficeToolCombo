import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/features/settings/application/locale_controller.dart';
import 'package:office_tool_combo/features/settings/data/settings_store.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, SettingsStore store) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
        child: OfficeToolComboApp(logger: AppLogger()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LanguageMenuButton', () {
    testWidgets('home renders Spanish when es is stored', (tester) async {
      await pumpApp(tester, InMemorySettingsStore(localeCode: 'es'));

      expect(find.text('Elige una herramienta'), findsOneWidget);
      expect(find.text('Consolidador de informes'), findsOneWidget);
    });

    testWidgets('home renders English by default', (tester) async {
      await pumpApp(tester, InMemorySettingsStore());

      expect(find.text('Choose a tool'), findsOneWidget);
      expect(find.text('Report consolidator'), findsOneWidget);
    });

    testWidgets('picking Español switches the UI and persists the choice', (
      tester,
    ) async {
      final store = InMemorySettingsStore();
      await pumpApp(tester, store);

      expect(find.text('Choose a tool'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(find.text('Elige una herramienta'), findsOneWidget);
      expect(store.localeCode, 'es');

      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predeterminado del sistema'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a tool'), findsOneWidget);
      expect(store.localeCode, isNull);
    });
  });
}
