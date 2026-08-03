import 'dart:io';

import 'package:office_tool_combo/core/logging/app_logger.dart';

import 'package:office_tool_combo/features/price_monitor/domain/alerting/os_notifications.dart';

export 'package:office_tool_combo/features/price_monitor/domain/alerting/os_notifications.dart';

/// Desktop implementation: `notify-send` on Linux, `osascript` on macOS,
/// unsupported on Windows (SPEC §11 — banner fallback covers the rest).
class DesktopOsNotificationService implements OsNotificationService {
  DesktopOsNotificationService({
    AppLogger? logger,
    this.timeout = const Duration(seconds: 2),
  }) : _logger = logger ?? AppLogger();

  final AppLogger _logger;
  final Duration timeout;

  @override
  Future<OsNotifyOutcome> showNotification({
    required String title,
    required String body,
  }) async {
    if (Platform.isLinux) {
      return _run('notify-send', [title, body], platform: 'linux');
    }
    if (Platform.isMacOS) {
      final script =
          'display notification "${_escape(body)}" '
          'with title "${_escape(title)}"';
      return _run('osascript', ['-e', script], platform: 'macos');
    }
    return OsNotifyOutcome.unsupported;
  }

  Future<OsNotifyOutcome> _run(
    String executable,
    List<String> arguments, {
    required String platform,
  }) async {
    try {
      final result = await Process.run(executable, arguments).timeout(timeout);
      if (result.exitCode == 0) {
        return OsNotifyOutcome.delivered;
      }
      _logger.info(
        'price_monitor.os_notify_failed platform=$platform '
        'exitCode=${result.exitCode}',
      );
      return OsNotifyOutcome.failed;
    } on Object {
      // Binary missing (Linux DE without notify-send) or timed out.
      _logger.info('price_monitor.os_notify_failed platform=$platform');
      return OsNotifyOutcome.failed;
    }
  }

  String _escape(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}
