import 'dart:io';

/// Reveals [filePath] in the platform file manager (select/highlight when supported).
abstract final class DesktopFileReveal {
  static Future<bool> revealInFileManager(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }

    if (Platform.isMacOS) {
      final result = await Process.run('open', ['-R', filePath]);
      return result.exitCode == 0;
    }

    if (Platform.isWindows) {
      final normalized = filePath.replaceAll('/', r'\');
      final result = await Process.run('explorer', ['/select,', normalized]);
      return result.exitCode == 0;
    }

    if (Platform.isLinux) {
      final attempts = <List<String>>[
        ['nautilus', '--select', filePath],
        ['dolphin', '--select', filePath],
        ['thunar', '--select', filePath],
        ['nemo', '--select', filePath],
        ['xdg-open', file.parent.path],
      ];

      for (final command in attempts) {
        final executable = command.first;
        if (!_commandExists(executable)) {
          continue;
        }
        final result = await Process.run(executable, command.sublist(1));
        if (result.exitCode == 0) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _commandExists(String command) {
    try {
      final result = Process.runSync('which', [command]);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }
}
