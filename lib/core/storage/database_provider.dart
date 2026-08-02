import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/storage/app_database.dart';
import 'package:office_tool_combo/core/storage/database_connection.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openDatabaseConnection());
  ref.onDispose(db.close);
  return db;
});
