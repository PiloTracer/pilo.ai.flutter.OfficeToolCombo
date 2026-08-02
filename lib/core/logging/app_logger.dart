import 'dart:developer' as developer;

/// Minimal logger. Never logs absolute paths that may contain client names.
class AppLogger {
  void info(String message) {
    developer.log(message, name: 'OfficeToolCombo');
  }

  void error(String label, Object error, StackTrace? stack) {
    developer.log(
      '$error',
      name: 'OfficeToolCombo.$label',
      error: error,
      stackTrace: stack,
    );
  }
}
