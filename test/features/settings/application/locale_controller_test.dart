import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/settings/application/locale_controller.dart';
import 'package:office_tool_combo/features/settings/data/settings_store.dart';

void main() {
  group('LocaleController', () {
    test('starts on system locale, then hydrates the stored choice', () async {
      final store = InMemorySettingsStore(localeCode: 'es');
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(container.read(localeControllerProvider), isNull);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeControllerProvider), const Locale('es'));
    });

    test('ignores unsupported stored language codes', () async {
      final store = InMemorySettingsStore(localeCode: 'fr');
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      container.read(localeControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeControllerProvider), isNull);
    });

    test('setLocale updates state and persists to the store', () async {
      final store = InMemorySettingsStore();
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container
          .read(localeControllerProvider.notifier)
          .setLocale(const Locale('en'));
      expect(container.read(localeControllerProvider), const Locale('en'));
      expect(store.localeCode, 'en');

      await container.read(localeControllerProvider.notifier).setLocale(null);
      expect(container.read(localeControllerProvider), isNull);
      expect(store.localeCode, isNull);
    });
  });
}
