import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/repositories/backup_repository_impl.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/shared_preferences_backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/repositories/backup_repository.dart';

final backupStoreProvider = Provider<BackupStore>((ref) {
  return SharedPreferencesBackupStore();
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final repository = BackupRepositoryImpl(store: ref.read(backupStoreProvider));
  // F6 — app close during a run cancels it and removes the partial archive.
  ref.onDispose(() => unawaited(repository.cancelActiveRun()));
  return repository;
});

/// Offline note only (SPEC §10) — backups never need the network. Reuses the
/// price monitor's injectable connectivity abstraction.
final backupConnectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return NetworkConnectivityService();
});
