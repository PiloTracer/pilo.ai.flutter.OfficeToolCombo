import 'package:flutter/material.dart';

@immutable
class AppDurations extends ThemeExtension<AppDurations> {
  const AppDurations({
    this.fast = const Duration(milliseconds: 150),
    this.normal = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 400),
  });

  final Duration fast;
  final Duration normal;
  final Duration slow;

  static const standard = AppDurations();

  Duration motion(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return reduceMotion ? Duration.zero : normal;
  }

  @override
  AppDurations copyWith({Duration? fast, Duration? normal, Duration? slow}) {
    return AppDurations(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
    );
  }

  @override
  AppDurations lerp(ThemeExtension<AppDurations>? other, double t) {
    return other is AppDurations ? other : this;
  }
}

extension AppDurationsContext on BuildContext {
  AppDurations get durations => Theme.of(this).extension<AppDurations>()!;
}
