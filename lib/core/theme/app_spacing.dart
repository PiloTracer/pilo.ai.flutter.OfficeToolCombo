import 'package:flutter/material.dart';

/// Spacing scale: 4 / 8 / 16 / 24 / 32 (multiples of 4).
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  static const standard = AppSpacing();

  EdgeInsets get screenPadding => EdgeInsets.all(lg);
  EdgeInsets get cardPadding => EdgeInsets.all(md);
  SizedBox get gapXs => SizedBox(height: xs, width: xs);
  SizedBox get gapSm => SizedBox(height: sm, width: sm);
  SizedBox get gapMd => SizedBox(height: md, width: md);
  SizedBox get gapLg => SizedBox(height: lg, width: lg);

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }

  static double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension AppSpacingContext on BuildContext {
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
}
