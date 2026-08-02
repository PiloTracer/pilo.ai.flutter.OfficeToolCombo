import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';

void main() {
  testWidgets('home lists five office tools', (tester) async {
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
  });
}
