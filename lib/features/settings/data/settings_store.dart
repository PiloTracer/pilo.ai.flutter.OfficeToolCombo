/// Persists app-wide user settings across restarts.
abstract class SettingsStore {
  /// BCP-47 language code chosen by the user ('en', 'es'), or `null` when the
  /// app should follow the system locale.
  Future<String?> readLocaleCode();

  Future<void> writeLocaleCode(String? code);
}

class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({this.localeCode});

  String? localeCode;

  @override
  Future<String?> readLocaleCode() async => localeCode;

  @override
  Future<void> writeLocaleCode(String? code) async {
    localeCode = code;
  }
}
