import 'package:office_tool_combo/features/settings/data/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads [SharedPreferences] on first read/write so providers stay
/// synchronous.
class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore();

  static const localeCodeKey = 'app_locale_code';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> readLocaleCode() async {
    final preferences = await _instance();
    return preferences.getString(localeCodeKey);
  }

  @override
  Future<void> writeLocaleCode(String? code) async {
    final preferences = await _instance();
    if (code == null || code.isEmpty) {
      await preferences.remove(localeCodeKey);
      return;
    }
    await preferences.setString(localeCodeKey, code);
  }
}
