import 'package:flutter/material.dart';

/// Primitive palette — consumed only by [AppColorScheme], never by widgets.
abstract final class AppColors {
  static const seed = Color(0xFF1E3A5F);
  static const seedLight = Color(0xFF2E5077);
  static const seedDark = Color(0xFF8EB4E3);

  static const neutral950 = Color(0xFF0F1419);
  static const neutral900 = Color(0xFF1A2332);
  static const neutral800 = Color(0xFF2A3544);
  static const neutral700 = Color(0xFF3D4A5C);
  static const neutral600 = Color(0xFF5C6778);
  static const neutral500 = Color(0xFF7A8494);
  static const neutral400 = Color(0xFF9AA3B2);
  static const neutral300 = Color(0xFFB8BFCA);
  static const neutral200 = Color(0xFFD5DAE2);
  static const neutral100 = Color(0xFFEBEEF2);
  static const neutral50 = Color(0xFFF5F7FA);

  static const success = Color(0xFF2E7D5A);
  static const successContainer = Color(0xFFD4EDE0);
  static const warning = Color(0xFFB8860B);
  static const warningContainer = Color(0xFFFFF0C2);
  static const error = Color(0xFFB54A4A);
  static const errorContainer = Color(0xFFF9DEDE);
  static const info = Color(0xFF3D6B9E);
  static const infoContainer = Color(0xFFDCE8F5);

  static const successDarkFg = Color(0xFF7BC4A4);
  static const successDarkBg = Color(0xFF1A3D2E);
  static const warningDarkFg = Color(0xFFE8C56A);
  static const warningDarkBg = Color(0xFF3D3010);
}
