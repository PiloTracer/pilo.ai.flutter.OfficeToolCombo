import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_color_scheme.dart';
import 'package:office_tool_combo/core/theme/app_component_themes.dart';
import 'package:office_tool_combo/core/theme/app_durations.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = AppColorScheme.light();
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: AppTypography.textTheme(scheme),
      extensions: const [
        AppSpacing.standard,
        AppRadii.standard,
        AppDurations.standard,
      ],
    );
    return AppComponentThemes.apply(base);
  }

  static ThemeData dark() {
    final scheme = AppColorScheme.dark();
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: AppTypography.textTheme(scheme),
      extensions: const [
        AppSpacing.standard,
        AppRadii.standard,
        AppDurations.standard,
      ],
    );
    return AppComponentThemes.apply(base);
  }
}
