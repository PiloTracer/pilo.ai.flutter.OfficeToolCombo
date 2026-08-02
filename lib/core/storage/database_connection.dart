import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the local sqlite database in the application support directory.
LazyDatabase openDatabaseConnection() {
  return LazyDatabase(() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(supportDir.path, 'database'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    final file = File(p.join(dbDir.path, 'office_tool_combo.sqlite'));
    // Foreground NativeDatabase avoids background-isolate hangs on Linux desktop.
    return NativeDatabase(file);
  });
}

/// In-memory database for unit tests.
LazyDatabase openInMemoryDatabaseConnection() {
  return LazyDatabase(() async => NativeDatabase.memory());
}
