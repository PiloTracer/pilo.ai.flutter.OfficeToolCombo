import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';

void main() {
  group('OfficeToolComboApp', () {
    testWidgets('home lists five office tools', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(child: OfficeToolComboApp(logger: AppLogger())),
      );
      await tester.pumpAndSettle();

      expect(find.text('OfficeToolCombo'), findsOneWidget);
      expect(find.text('Report consolidator'), findsOneWidget);
      expect(find.text('Barcode inventory'), findsOneWidget);
      expect(find.text('Document factory'), findsOneWidget);
      expect(find.text('Price monitor'), findsOneWidget);
      expect(find.text('Scheduled backup'), findsOneWidget);
      expect(find.text('Choose a tool'), findsOneWidget);
    });

    testWidgets('home renders without overflow at 200% text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ProviderScope(child: OfficeToolComboApp(logger: AppLogger())),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('OfficeToolCombo'), findsOneWidget);
    });
  });

  group('AppTheme', () {
    test('light and dark themes define spacing extensions', () {
      expect(AppTheme.light().extension<AppSpacing>(), isNotNull);
      expect(AppTheme.dark().extension<AppSpacing>(), isNotNull);
    });
  });
}
