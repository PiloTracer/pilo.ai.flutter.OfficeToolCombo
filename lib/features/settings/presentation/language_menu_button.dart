import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/settings/application/locale_controller.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Overflow menu that lets the user pick English, Spanish, or the system
/// default. The choice is persisted across restarts by [LocaleController].
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  static const _systemValue = 'system';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    final spacing = context.spacing;

    return PopupMenuButton<String>(
      tooltip: l10n.languageMenuLabel,
      icon: const Icon(Icons.language_outlined),
      onSelected: (value) {
        final locale = value == _systemValue ? null : Locale(value);
        unawaited(
          ref.read(localeControllerProvider.notifier).setLocale(locale),
        );
      },
      itemBuilder: (context) => [
        _localeItem(
          spacing,
          _systemValue,
          l10n.languageSystem,
          current == null,
        ),
        _localeItem(
          spacing,
          'en',
          l10n.languageEnglish,
          current?.languageCode == 'en',
        ),
        _localeItem(
          spacing,
          'es',
          l10n.languageSpanish,
          current?.languageCode == 'es',
        ),
      ],
    );
  }

  PopupMenuItem<String> _localeItem(
    AppSpacing spacing,
    String value,
    String label,
    bool selected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
          ),
          SizedBox(width: spacing.md),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
