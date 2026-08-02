import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_colors.dart';

abstract final class AppColorScheme {
  static ColorScheme light() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.seed,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD8E4F2),
      onPrimaryContainer: AppColors.neutral900,
      secondary: AppColors.neutral700,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.neutral100,
      onSecondaryContainer: AppColors.neutral900,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: Color(0xFF5C2020),
      surface: AppColors.neutral50,
      onSurface: AppColors.neutral900,
      onSurfaceVariant: AppColors.neutral600,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
      shadow: AppColors.neutral950,
      scrim: AppColors.neutral950,
      inverseSurface: AppColors.neutral900,
      onInverseSurface: AppColors.neutral100,
      inversePrimary: AppColors.seedDark,
      surfaceContainerHighest: Colors.white,
      surfaceContainerHigh: AppColors.neutral50,
      surfaceContainer: AppColors.neutral100,
      surfaceContainerLow: AppColors.neutral100,
      surfaceContainerLowest: Colors.white,
    );
  }

  static ColorScheme dark() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.seedDark,
      onPrimary: AppColors.neutral950,
      primaryContainer: Color(0xFF243B55),
      onPrimaryContainer: AppColors.neutral100,
      secondary: AppColors.neutral400,
      onSecondary: AppColors.neutral950,
      secondaryContainer: AppColors.neutral800,
      onSecondaryContainer: AppColors.neutral100,
      tertiary: Color(0xFF9CC4F0),
      onTertiary: AppColors.neutral950,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF5C2020),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.neutral950,
      onSurface: AppColors.neutral100,
      onSurfaceVariant: AppColors.neutral400,
      outline: AppColors.neutral700,
      outlineVariant: AppColors.neutral800,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.neutral100,
      onInverseSurface: AppColors.neutral900,
      inversePrimary: AppColors.seed,
      surfaceContainerHighest: AppColors.neutral800,
      surfaceContainerHigh: AppColors.neutral900,
      surfaceContainer: AppColors.neutral900,
      surfaceContainerLow: AppColors.neutral950,
      surfaceContainerLowest: AppColors.neutral950,
    );
  }
}
