import 'package:flutter/material.dart';

@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({this.sm = 8, this.md = 12, this.lg = 16, this.full = 999});

  final double sm;
  final double md;
  final double lg;
  final double full;

  static const standard = AppRadii();

  BorderRadius get smAll => BorderRadius.circular(sm);
  BorderRadius get mdAll => BorderRadius.circular(md);
  BorderRadius get lgAll => BorderRadius.circular(lg);

  @override
  AppRadii copyWith({double? sm, double? md, double? lg, double? full}) {
    return AppRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      full: full ?? this.full,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    double lerp(double a, double b) => a + (b - a) * t;
    return AppRadii(
      sm: lerp(sm, other.sm),
      md: lerp(md, other.md),
      lg: lerp(lg, other.lg),
      full: lerp(full, other.full),
    );
  }
}

extension AppRadiiContext on BuildContext {
  AppRadii get radii => Theme.of(this).extension<AppRadii>()!;
}
