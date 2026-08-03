import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/settings/data/shared_preferences_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesSettingsStore', () {
    test('round-trips the locale code across store instances', () async {
      SharedPreferences.setMockInitialValues({});

      final writer = SharedPreferencesSettingsStore();
      await writer.writeLocaleCode('es');

      // A fresh instance simulates an app restart.
      final reader = SharedPreferencesSettingsStore();
      expect(await reader.readLocaleCode(), 'es');
    });

    test('returns null when no locale was ever stored', () async {
      SharedPreferences.setMockInitialValues({});

      final store = SharedPreferencesSettingsStore();

      expect(await store.readLocaleCode(), isNull);
    });

    test('clears the stored locale when writing null or empty', () async {
      SharedPreferences.setMockInitialValues({'app_locale_code': 'es'});

      final store = SharedPreferencesSettingsStore();
      await store.writeLocaleCode(null);
      expect(await store.readLocaleCode(), isNull);

      await store.writeLocaleCode('en');
      expect(await store.readLocaleCode(), 'en');

      await store.writeLocaleCode('');
      expect(await store.readLocaleCode(), isNull);
    });
  });
}
