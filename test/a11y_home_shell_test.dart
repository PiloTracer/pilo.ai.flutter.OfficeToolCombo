import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/settings/application/locale_controller.dart';
import 'package:office_tool_combo/features/settings/data/settings_store.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';

import 'helpers/l10n_test_harness.dart';

void main() {
  void useSmallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('home renders without overflow at 200% text scale', (
    tester,
  ) async {
    useSmallSurface(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
          ],
          child: OfficeToolComboApp(logger: AppLogger()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('OfficeToolCombo'), findsOneWidget);
  });

  testWidgets('tool cards expose title and subtitle as one semantic stop', (
    tester,
  ) async {
    useSmallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
        ],
        child: OfficeToolComboApp(logger: AppLogger()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label ==
                'Report consolidator, Merge a folder of Excel files into one '
                    'clean workbook',
      ),
      findsOneWidget,
    );
  });

  testWidgets('language menu button has a localized tooltip', (tester) async {
    useSmallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
        ],
        child: OfficeToolComboApp(logger: AppLogger()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuButton<String> && widget.tooltip == 'Language',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tool shell back button has a localized tooltip', (tester) async {
    useSmallSurface(tester);
    await tester.pumpWithL10n(
      const ToolShellScaffold(title: 'Tool', body: SizedBox.shrink()),
      theme: AppTheme.dark(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Back to home',
      ),
      findsOneWidget,
    );
  });
}
