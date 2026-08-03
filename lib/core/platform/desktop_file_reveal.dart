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
      // `explorer /select,` commonly exits 1 even when it opened the window
      // and selected the file — treat any completed launch as success.
      return result.exitCode == 0 || result.exitCode == 1;
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
        if (!await _commandExists(executable)) {
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

  static Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }
}
