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
/// same guarantees (R5 — one run at a time). Every run is recorded in the
/// unified run log with the job's id and label.
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

  /// The unified run log keeps at most 50 entries across all jobs.
  static const maxRunLogEntries = 50;

  final BackupStore _store;
  final IsolateRunner _isolateRunner;
  final DateTime Function() _now;
  final AppLogger _logger;

  var _runInProgress = false;
  String? _activeCancelPath;
  BackupJob? _activeJob;

  @override
  bool get isRunInProgress => _runInProgress;

  @override
  Future<Result<List<BackupJob>>> loadJobs() async {
    try {
      return Success<List<BackupJob>>(await _store.readJobs());
    } on Object catch (error, stack) {
      _logger.error('backup.load_failed', error, stack);
      return Err<List<BackupJob>>(_asFailure(const BackupConfigLoadFailure()));
    }
  }

  @override
  Future<Result<void>> saveJob(BackupJob job) async {
    try {
      final jobs = await _store.readJobs();
      final index = jobs.indexWhere((existing) => existing.id == job.id);
      if (index >= 0) {
        jobs[index] = job;
      } else {
        jobs.add(job);
      }
      await _store.writeJobs(jobs);
      return const Success<void>(null);
    } on Object catch (error, stack) {
      _logger.error('backup.save_failed', error, stack);
      return Err<void>(_asFailure(const BackupConfigSaveFailure()));
    }
  }

  @override
  Future<Result<void>> deleteJob(String jobId) async {
    try {
      final jobs = await _store.readJobs()
        ..removeWhere((job) => job.id == jobId);
      await _store.writeJobs(jobs);
      return const Success<void>(null);
    } on Object catch (error, stack) {
      _logger.error('backup.save_failed', error, stack);
      return Err<void>(_asFailure(const BackupConfigSaveFailure()));
    }
  }

  @override
  Future<List<BackupRunLogEntry>> readRunLog() async {
    final entries = await _store.readRunLog();
    return entries.take(maxRunLogEntries).toList(growable: false);
  }

  @override
  Future<DateTime?> lastRunAt(String jobId) async {
    final entries = await _store.readRunLog();
    for (final entry in entries) {
      if (entry.jobId == jobId) {
        return entry.finishedAt;
      }
    }
    return null;
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
  Future<Result<BackupRunLogEntry>> runBackup({
    required BackupJob job,
    required BackupTrigger trigger,
    void Function(BackupRunProgress progress)? onProgress,
  }) async {
    // R5 — at most one run at a time; the caller skips and logs.
    if (_runInProgress) {
      return Err<BackupRunLogEntry>(
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
        job,
        BackupFailureCodes.sourceMissing,
        'Source folder missing at run',
      );
    }
    final destination = job.destinationFolder;
    if (destination == null || destination.isEmpty) {
      return _failRun(
        job,
        BackupFailureCodes.destinationNotWritable,
        'Destination not writable',
      );
    }
    // R4 — pure path check first, before any filesystem probe.
    if (_normalizePath(source) == _normalizePath(destination)) {
      return _failRun(
        job,
        BackupFailureCodes.sameFolders,
        'Source and destination are the same folder',
      );
    }
    if (!await _probeWritable(destination)) {
      return _failRun(
        job,
        BackupFailureCodes.destinationNotWritable,
        'Destination not writable',
      );
    }

    _runInProgress = true;
    _activeJob = job;
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

    _logger.info('backup_run_started trigger=${trigger.name} jobId=${job.id}');
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
      _activeJob = null;
      return _failRun(
        job,
        BackupFailureCodes.run,
        'Zip isolate failed: $error',
      );
    } finally {
      _activeCancelPath = null;
    }

    if (response.cancelled) {
      _runInProgress = false;
      _activeJob = null;
      return _failRun(
        job,
        BackupFailureCodes.interrupted,
        'Run cancelled; partial archive removed',
        status: BackupRunStatus.cancelled,
      );
    }
    final errorCode = response.errorCode;
    if (errorCode != null) {
      _runInProgress = false;
      _activeJob = null;
      return _failRun(job, errorCode, 'Zip run failed: $errorCode');
    }

    final finishedAt = _now().toUtc();
    final entry = BackupRunLogEntry(
      jobId: job.id,
      jobLabel: job.label,
      finishedAt: finishedAt,
      status: BackupRunStatus.succeeded,
      archiveName: archiveName,
      archiveBytes: response.bytesWritten,
      archivePath: '$destination${Platform.pathSeparator}$archiveName',
    );
    // R7/R8 — only successful runs carry an archive; keep the 50 newest.
    await _appendLogEntry(entry);
    _runInProgress = false;
    _activeJob = null;
    _logger.info(
      'backup_run_finished jobId=${job.id} status=succeeded '
      'durationMs=${stopwatch.elapsedMilliseconds} '
      'bytesWritten=${response.bytesWritten}',
    );
    return Success<BackupRunLogEntry>(entry);
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
    final job = _activeJob;
    if (job != null) {
      await _appendLogEntry(
        BackupRunLogEntry(
          jobId: job.id,
          jobLabel: job.label,
          finishedAt: _now().toUtc(),
          status: BackupRunStatus.failed,
          messageCode: BackupFailureCodes.interrupted,
        ),
      );
    }
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

  /// Records a failed run (R7 — no archive name) in the unified log and
  /// returns the matching [Err].
  Future<Result<BackupRunLogEntry>> _failRun(
    BackupJob job,
    String code,
    String logMessage, {
    BackupRunStatus status = BackupRunStatus.failed,
  }) async {
    _logger.info(
      'backup_run_finished jobId=${job.id} status=${status.name} '
      'failureType=$code',
    );
    final entry = BackupRunLogEntry(
      jobId: job.id,
      jobLabel: job.label,
      finishedAt: _now().toUtc(),
      status: status,
      messageCode: code,
    );
    await _appendLogEntry(entry);
    return Err<BackupRunLogEntry>(
      _asFailure(BackupRunFailure(code: code, message: logMessage)),
    );
  }

  Future<void> _appendLogEntry(BackupRunLogEntry entry) async {
    try {
      final entries = await _store.readRunLog();
      entries.insert(0, entry);
      await _store.writeRunLog(
        entries.take(maxRunLogEntries).toList(growable: false),
      );
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
