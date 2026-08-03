import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/settings/data/settings_store.dart';
import 'package:office_tool_combo/features/settings/data/shared_preferences_settings_store.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return SharedPreferencesSettingsStore();
});

/// Holds the user's locale override. `null` means "follow the system locale".
///
/// The persisted choice is loaded asynchronously after [build]; the app
/// starts on the system locale and switches once the stored value arrives.
class LocaleController extends Notifier<Locale?> {
  static const supportedLanguageCodes = ['en', 'es'];

  @override
  Locale? build() {
    unawaited(_hydrate());
    return null;
  }

  Future<void> _hydrate() async {
    final code = await ref.read(settingsStoreProvider).readLocaleCode();
    if (code != null && supportedLanguageCodes.contains(code)) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await ref
        .read(settingsStoreProvider)
        .writeLocaleCode(locale?.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
