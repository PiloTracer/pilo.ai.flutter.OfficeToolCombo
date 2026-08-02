import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_colors.dart';

/// Semantic status tones — defined in the theme layer, consumed by widgets.
abstract final class AppStatusTone {
  static Color successForeground(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.successDarkFg
        : AppColors.success;
  }

  static Color successBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.successDarkBg
        : AppColors.successContainer;
  }

  static Color warningForeground(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.warningDarkFg
        : AppColors.warning;
  }

  static Color warningBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.warningDarkBg
        : AppColors.warningContainer;
  }

  static Color errorForeground(ColorScheme scheme) => scheme.error;

  static Color errorBackground(ColorScheme scheme) => scheme.errorContainer;

  static Color successForegroundOf(BuildContext context) =>
      successForeground(Theme.of(context).brightness);

  static Color successBackgroundOf(BuildContext context) =>
      successBackground(Theme.of(context).brightness);

  static Color warningForegroundOf(BuildContext context) =>
      warningForeground(Theme.of(context).brightness);

  static Color warningBackgroundOf(BuildContext context) =>
      warningBackground(Theme.of(context).brightness);

  static Color errorForegroundOf(BuildContext context) =>
      errorForeground(Theme.of(context).colorScheme);

  static Color errorBackgroundOf(BuildContext context) =>
      errorBackground(Theme.of(context).colorScheme);
}
