import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';

abstract final class AppComponentThemes {
  static ThemeData apply(ThemeData base) {
    final scheme = base.colorScheme;
    final spacing = base.extension<AppSpacing>() ?? AppSpacing.standard;
    final radii = base.extension<AppRadii>() ?? AppRadii.standard;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: radii.mdAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, spacing.lg + spacing.sm),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm + spacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: radii.smAll),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, spacing.lg + spacing.sm),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm + spacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: radii.smAll),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: radii.smAll),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: spacing.md,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainer,
        color: scheme.primary,
      ),
      iconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: spacing.lg,
      ),
    );
  }
}
