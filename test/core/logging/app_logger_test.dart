import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';

void main() {
  late Directory tempDir;
  late File logFile;
  late AppLogger logger;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_logger_');
    logFile = File('${tempDir.path}${Platform.pathSeparator}crash.log');
    logger = AppLogger(logFile: logFile);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> waitForContent() async {
    for (var i = 0; i < 50; i++) {
      if (logFile.existsSync() && logFile.lengthSync() > 0) {
        return logFile.readAsStringSync();
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return '';
  }

  test('error persists label, error and stack to the log file', () async {
    logger.error('FlutterError', StateError('boom'), StackTrace.current);

    final content = await waitForContent();
    expect(content, contains('[FlutterError]'));
    expect(content, contains('boom'));
  });

  test('home directory paths are redacted before persisting', () async {
    final home = Platform.environment['HOME']!;
    logger.error(
      'Zone',
      Exception('failed reading $home/client_x/file.xlsx'),
      null,
    );

    final content = await waitForContent();
    expect(content, isNot(contains(home)));
    expect(content, contains('~/client_x/file.xlsx'));
  });

  test('info does not persist to the file', () async {
    logger.info('just an info line');
    logger.error('Zone', Exception('marker'), null);

    final content = await waitForContent();
    expect(content, isNot(contains('just an info line')));
    expect(content, contains('marker'));
  });
}
