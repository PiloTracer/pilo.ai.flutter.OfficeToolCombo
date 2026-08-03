import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Minimal logger with a persistent crash sink (F6-T3).
///
/// [error] also appends to a rotating log file in the app support
/// directory so fatal errors (wired in `bootstrap.dart`) survive the
/// session. Home-directory paths are redacted before persisting — client
/// names must never land in logs (F0-T9, NFR8). Logging never throws.
class AppLogger {
  AppLogger({this.logFile});

  static const _maxLogBytes = 512 * 1024;

  /// Injectable crash-log destination; defaults to the app support
  /// directory on first error.
  File? logFile;

  void info(String message) {
    developer.log(_redact(message), name: 'OfficeToolCombo');
  }

  void error(String label, Object error, StackTrace? stack) {
    developer.log(
      '$error',
      name: 'OfficeToolCombo.$label',
      error: error,
      stackTrace: stack,
    );
    unawaited(_persist(label, error, stack));
  }

  Future<void> _persist(String label, Object error, StackTrace? stack) async {
    try {
      final file = logFile ??= await _defaultLogFile();
      if (file.existsSync() && file.lengthSync() > _maxLogBytes) {
        final rotated = File('${file.path}.old');
        if (rotated.existsSync()) {
          rotated.deleteSync();
        }
        file.renameSync(rotated.path);
      }
      final entry = StringBuffer()
        ..write(DateTime.now().toUtc().toIso8601String())
        ..write(' [')
        ..write(label)
        ..write('] ')
        ..writeln(_redact('$error'));
      if (stack != null) {
        entry.writeln(_redact(stack.toString()));
      }
      await file.writeAsString(
        entry.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } on Object {
      // Logging must never take the app down.
    }
  }

  Future<File> _defaultLogFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory('${supportDir.path}${Platform.pathSeparator}logs');
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }
    return File('${logDir.path}${Platform.pathSeparator}office_tool_combo.log');
  }

  String _redact(String message) {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return message;
    }
    return message.replaceAll(home, '~');
  }
}
