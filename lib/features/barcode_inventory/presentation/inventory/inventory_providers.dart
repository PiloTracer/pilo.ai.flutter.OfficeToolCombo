import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/storage/database_provider.dart';
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';
import 'package:office_tool_combo/features/settings/application/locale_controller.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations_en.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations_es.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InventoryRepositoryImpl(database: db);
});

/// Resolves [AppLocalizations] without a [BuildContext] so notifiers can
/// produce localized toasts and error text. Follows the user's locale
/// override when set, otherwise the system locale.
final inventoryLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final override = ref.watch(localeControllerProvider);
  final languageCode =
      override?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return switch (languageCode) {
    'es' => AppLocalizationsEs(),
    _ => AppLocalizationsEn(),
  };
});
