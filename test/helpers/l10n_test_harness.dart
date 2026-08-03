import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Wraps [home] in a [MaterialApp] wired with the app's localization
/// delegates, so widgets under test can use `AppLocalizations.of(context)`.
///
/// Pass `locale: const Locale('es')` to exercise the Spanish strings.
Widget buildL10nTestApp({
  required Widget home,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme,
    home: home,
  );
}

extension L10nTestHarness on WidgetTester {
  /// Pumps [home] inside a localized [MaterialApp]; see [buildL10nTestApp].
  Future<void> pumpWithL10n(
    Widget home, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) {
    return pumpWidget(buildL10nTestApp(home: home, locale: locale, theme: theme));
  }
}
