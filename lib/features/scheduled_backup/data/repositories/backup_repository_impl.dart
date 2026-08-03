import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/platform/desktop_file_reveal.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/utils/isolate_runner.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/services/backup_zip_worker.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/shared_preferences_backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/failures/backup_failure.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/repositories/backup_repository.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/services/archive_namer.dart';

/// Store-backed implementation. Run validation (A3/A4, R4) happens here,
/// before the zip isolate starts, so manual and scheduled triggers get the
/// same guarantees (R5 — one run at a time).
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl({
    BackupStore? store,
    IsolateRunner? isolateRunner,
    DateTime Function()? now,
    AppLogger? logger,
  }) : _store = store ?? SharedPreferencesBackupStore(),
       _isolateRunner = isolateRunner ?? const IsolateRunner(),
       _now = now ?? DateTime.now,
       _logger = logger ?? AppLogger();

  /// SPEC §8 R8 — recent archives list is capped at 10 entries.
  static const maxArchiveEntries = 10;

  final BackupStore _store;
  final IsolateRunner _isolateRunner;
  final DateTime Function() _now;
  final AppLogger _logger;

  var _runInProgress = false;
  String? _activeCancelPath;

  @override
  bool get isRunInProgress => _runInProgress;

  @override
  Future<Result<BackupJob>> loadJob() async {
    try {
      return Success<BackupJob>(await _store.readJob() ?? const BackupJob());
    } on Object catch (error, stack) {
      _logger.error('backup.load_failed', error, stack);
      return Err<BackupJob>(_asFailure(const BackupConfigLoadFailure()));
    }
  }

  @override
  Future<Result<void>> saveJob(BackupJob job) async {
    try {
      await _store.writeJob(job);
      return const Success<void>(null);
    } on Object catch (error, stack) {
      _logger.error('backup.save_failed', error, stack);
      return Err<void>(_asFailure(const BackupConfigSaveFailure()));
    }
  }

  @override
  Future<BackupRunRecord?> readLastRun() => _store.readLastRun();

  @override
  Future<List<BackupArchiveEntry>> readArchives() async {
    final archives = await _store.readArchives();
    // R8 — the recent archives list shows at most 10 entries.
    return archives.take(maxArchiveEntries).toList(growable: false);
  }

  @override
  Future<Result<String?>> pickFolder({required String dialogTitle}) async {
    try {
      final path = await FilePicker.getDirectoryPath(dialogTitle: dialogTitle);
      return Success<String?>(path);
    } on Object catch (error) {
      return Err<String?>(IoFailure('Could not open folder picker: $error'));
    }
  }

  @override
  Future<Result<BackupRunRecord>> runBackup({
    required BackupJob job,
    required BackupTrigger trigger,
    void Function(BackupRunProgress progress)? onProgress,
  }) async {
    // R5 — at most one run at a time; the caller skips and logs.
    if (_runInProgress) {
      return Err<BackupRunRecord>(
        _asFailure(
          const BackupRunFailure(
            code: BackupFailureCodes.busy,
            message: 'A backup run is already in progress',
          ),
        ),
      );
    }

    // Validation before start (SPEC §7): source set + exists (A4),
    // destination set + writable probe (A3), source != destination (R4).
    final source = job.sourceFolder;
    if (source == null || source.isEmpty || !Directory(source).existsSync()) {
      return _failRun(
        BackupFailureCodes.sourceMissing,
        'Source folder missing at run',
      );
    }
    final destination = job.destinationFolder;
    if (destination == null || destination.isEmpty) {
      return _failRun(
        BackupFailureCodes.destinationNotWritable,
        'Destination not writable',
      );
    }
    // R4 — pure path check first, before any filesystem probe.
    if (_normalizePath(source) == _normalizePath(destination)) {
      return _failRun(
        BackupFailureCodes.sameFolders,
        'Source and destination are the same folder',
      );
    }
    if (!await _probeWritable(destination)) {
      return _failRun(
        BackupFailureCodes.destinationNotWritable,
        'Destination not writable',
      );
    }

    _runInProgress = true;
    final startedAt = _now();
    final archiveName = ArchiveNamer.resolveName(
      startedAt,
      (candidate) =>
          File('$destination${Platform.pathSeparator}$candidate').existsSync(),
    );
    final partialPath =
        '$destination${Platform.pathSeparator}$archiveName'
        '${ArchiveNamer.partialSuffix}';
    final cancelPath = '$partialPath.cancel';
    _activeCancelPath = cancelPath;

    _logger.info('backup_run_started trigger=${trigger.name} jobId=single');
    final stopwatch = Stopwatch()..start();

    BackupZipResponse response;
    try {
      response = await _isolateRunner
          .runWithProgress<
            BackupZipRequest,
            BackupZipResponse,
            BackupRunProgress
          >(
            BackupZipRequest(
              sourcePath: source,
              destinationPath: destination,
              archiveName: archiveName,
              cancelFilePath: cancelPath,
            ),
            runBackupZipIsolate,
            onProgress: onProgress,
          );
    } on Object catch (error, stack) {
      _logger.error('backup.run_isolate_failed', error, stack);
      await _deletePartial(partialPath);
      _runInProgress = false;
      return _failRun(BackupFailureCodes.run, 'Zip isolate failed: $error');
    } finally {
      _activeCancelPath = null;
    }

    if (response.cancelled) {
      _runInProgress = false;
      return _failRun(
        BackupFailureCodes.interrupted,
        'Run cancelled; partial archive removed',
        status: BackupRunStatus.cancelled,
      );
    }
    final errorCode = response.errorCode;
    if (errorCode != null) {
      _runInProgress = false;
      return _failRun(errorCode, 'Zip run failed: $errorCode');
    }

    final finishedAt = _now().toUtc();
    final entry = BackupArchiveEntry(
      name: archiveName,
      path: '$destination${Platform.pathSeparator}$archiveName',
      bytes: response.bytesWritten,
      finishedAt: finishedAt,
    );
    // R7/R8 — only successful runs add an entry; keep the 10 newest.
    try {
      final archives = await _store.readArchives();
      archives.insert(0, entry);
      await _store.writeArchives(
        archives.take(maxArchiveEntries).toList(growable: false),
      );
    } on Object catch (error, stack) {
      _logger.error('backup.archives_save_failed', error, stack);
    }

    final record = BackupRunRecord(
      status: BackupRunStatus.succeeded,
      messageCode: '',
      timestamp: finishedAt,
    );
    await _writeLastRun(record);
    _runInProgress = false;
    _logger.info(
      'backup_run_finished jobId=single status=succeeded '
      'durationMs=${stopwatch.elapsedMilliseconds} '
      'bytesWritten=${response.bytesWritten}',
    );
    return Success<BackupRunRecord>(record);
  }

  @override
  Future<void> cancelActiveRun() async {
    if (!_runInProgress) {
      return;
    }
    final cancelPath = _activeCancelPath;
    if (cancelPath != null) {
      try {
        await File(cancelPath).writeAsString('cancel', flush: true);
      } on Object {
        // Best-effort; the worker also cleans up on its own.
      }
    }
    // Record the interruption immediately — on app close nobody is left to
    // await the run future (F6, SPEC §9).
    await _writeLastRun(
      BackupRunRecord(
        status: BackupRunStatus.failed,
        messageCode: BackupFailureCodes.interrupted,
        timestamp: _now().toUtc(),
      ),
    );
  }

  @override
  Future<void> cleanupStalePartials(String destinationPath) async {
    try {
      final directory = Directory(destinationPath);
      if (!directory.existsSync()) {
        return;
      }
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File &&
            entity.path.endsWith(ArchiveNamer.partialSuffix)) {
          await entity.delete();
        }
      }
    } on Object {
      // Best-effort cleanup.
    }
  }

  @override
  Future<Result<void>> revealArchive(String path) async {
    final opened = await DesktopFileReveal.revealInFileManager(path);
    if (!opened) {
      return const Err<void>(IoFailure(BackupFailureCodes.reveal));
    }
    return const Success<void>(null);
  }

  /// Records a failed run (R7 — never adds an archive entry) and returns the
  /// matching [Err].
  Future<Result<BackupRunRecord>> _failRun(
    String code,
    String logMessage, {
    BackupRunStatus status = BackupRunStatus.failed,
  }) async {
    _logger.info(
      'backup_run_finished jobId=single status=${status.name} '
      'failureType=$code',
    );
    final record = BackupRunRecord(
      status: status,
      messageCode: code,
      timestamp: _now().toUtc(),
    );
    await _writeLastRun(record);
    return Err<BackupRunRecord>(
      _asFailure(BackupRunFailure(code: code, message: logMessage)),
    );
  }

  Future<void> _writeLastRun(BackupRunRecord record) async {
    try {
      await _store.writeLastRun(record);
    } on Object {
      // Bookkeeping must not fail the run itself.
    }
  }

  /// SPEC §7 — destination writability is verified with a probe file before
  /// zip creation starts.
  Future<bool> _probeWritable(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      if (!directory.existsSync()) {
        return false;
      }
      final probe = File(
        '$dirPath${Platform.pathSeparator}.scheduled_backup_probe',
      );
      await probe.writeAsBytes(const <int>[0], flush: true);
      await probe.delete();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _deletePartial(String partialPath) async {
    try {
      final file = File(partialPath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object {
      // Best-effort cleanup.
    }
  }

  String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  Failure _asFailure(BackupFailure failure) {
    return IoFailure(failure.code);
  }
}
