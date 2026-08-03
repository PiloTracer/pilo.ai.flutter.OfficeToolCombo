import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/failures/backup_failure.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/services/archive_namer.dart';

/// Serializable payload for the zip isolate.
class BackupZipRequest {
  const BackupZipRequest({
    required this.sourcePath,
    required this.destinationPath,
    required this.archiveName,
    required this.cancelFilePath,
  });

  final String sourcePath;
  final String destinationPath;
  final String archiveName;

  /// Sentinel file: when it appears, the worker stops, removes the partial
  /// archive, and reports the run as cancelled (F6).
  final String cancelFilePath;
}

/// Outcome of a finished (or cancelled) zip run. [errorCode] is a stable
/// BackupFailureCodes value when the run did not succeed.
class BackupZipResponse {
  const BackupZipResponse({
    required this.fileCount,
    required this.bytesWritten,
    this.cancelled = false,
    this.errorCode,
  });

  final int fileCount;
  final int bytesWritten;
  final bool cancelled;
  final String? errorCode;
}

/// Linux/macOS and Windows error codes for the mapped write failures.
const _enospc = <int>{28, 112}; // ENOSPC / ERROR_DISK_FULL
const _enametoolong = <int>{
  36,
  206,
}; // ENAMETOOLONG / ERROR_FILENAME_EXCED_RANGE

/// Zip worker — must stay top-level so it can cross the isolate boundary.
///
/// Writes to `<archiveName>.partial` first and renames to the final name on
/// success, so an interrupted run never leaves a file that looks like a
/// valid archive (SPEC §9). Progress = files processed / total; emitted per
/// file, which keeps updates well under the 1 s budget (SPEC §13).
Future<BackupZipResponse> runBackupZipIsolate(
  BackupZipRequest request,
  void Function(BackupRunProgress progress)? emitProgress,
) async {
  final separator = Platform.pathSeparator;
  final partialPath =
      '${request.destinationPath}$separator${request.archiveName}'
      '${ArchiveNamer.partialSuffix}';
  final finalPath =
      '${request.destinationPath}$separator${request.archiveName}';

  try {
    // R1 — every file under the source folder at run start.
    final files = <File>[];
    await for (final entity in Directory(
      request.sourcePath,
    ).list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    final encoder = ZipFileEncoder();
    try {
      encoder.create(partialPath);
    } on FileSystemException catch (error) {
      return BackupZipResponse(
        fileCount: 0,
        bytesWritten: 0,
        errorCode: _writeErrorCode(error),
      );
    }

    var processed = 0;
    for (final file in files) {
      if (File(request.cancelFilePath).existsSync()) {
        await encoder.close();
        await _deleteIfExists(partialPath);
        return BackupZipResponse(
          fileCount: processed,
          bytesWritten: 0,
          cancelled: true,
        );
      }
      final relative = file.path.substring(request.sourcePath.length + 1);
      try {
        await encoder.addFile(file, relative);
      } on FileSystemException {
        await encoder.close();
        await _deleteIfExists(partialPath);
        return BackupZipResponse(
          fileCount: processed,
          bytesWritten: 0,
          errorCode: BackupFailureCodes.sourceNotReadable,
        );
      }
      processed += 1;
      emitProgress?.call(
        BackupRunProgress(processedFiles: processed, totalFiles: files.length),
      );
    }
    await encoder.close();

    try {
      await File(partialPath).rename(finalPath);
    } on FileSystemException catch (error) {
      await _deleteIfExists(partialPath);
      return BackupZipResponse(
        fileCount: processed,
        bytesWritten: 0,
        errorCode: _writeErrorCode(error),
      );
    }

    return BackupZipResponse(
      fileCount: processed,
      bytesWritten: await File(finalPath).length(),
    );
  } on PathNotFoundException {
    await _deleteIfExists(partialPath);
    return const BackupZipResponse(
      fileCount: 0,
      bytesWritten: 0,
      errorCode: BackupFailureCodes.sourceMissing,
    );
  } on FileSystemException {
    await _deleteIfExists(partialPath);
    return const BackupZipResponse(
      fileCount: 0,
      bytesWritten: 0,
      errorCode: BackupFailureCodes.sourceNotReadable,
    );
  } on Object {
    await _deleteIfExists(partialPath);
    return const BackupZipResponse(
      fileCount: 0,
      bytesWritten: 0,
      errorCode: BackupFailureCodes.run,
    );
  }
}

String _writeErrorCode(FileSystemException error) {
  final errno = error.osError?.errorCode;
  if (errno != null) {
    if (_enospc.contains(errno)) {
      return BackupFailureCodes.diskFull;
    }
    if (_enametoolong.contains(errno)) {
      return BackupFailureCodes.pathTooLong;
    }
  }
  return BackupFailureCodes.destinationNotWritable;
}

Future<void> _deleteIfExists(String path) async {
  try {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  } on Object {
    // Best-effort cleanup; a stale partial is removed on next launch.
  }
}
