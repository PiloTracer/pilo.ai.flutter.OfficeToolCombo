import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/features/document_factory/domain/repositories/document_factory_repository.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_providers.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_ui_state.dart';

class DocumentFactoryViewModel extends Notifier<DocumentFactoryUiState> {
  DocumentFactoryRepository get _repository =>
      ref.read(documentFactoryRepositoryProvider);

  @override
  DocumentFactoryUiState build() {
    return const DocumentFactoryUiState();
  }

  /// Restores persisted job metadata; a record still marked `running` means
  /// the previous session was interrupted mid-batch (SPEC §4.4).
  Future<void> loadInitialState() async {
    final lastJob = await _repository.readLastJob();
    if (!ref.mounted) return;
    if (lastJob != null && lastJob.status == DocumentJobStatus.running) {
      await _repository.markLastJobInterrupted();
      if (!ref.mounted) return;
      state = state.copyWith(showInterruptedNotice: true, clearJob: true);
      return;
    }
    state = state.copyWith(lastJob: lastJob, clearJob: lastJob == null);
  }

  Future<void> pickTemplate() async {
    final pickResult = await _repository.pickTemplateFile();
    if (!ref.mounted) return;
    await pickResult.when(
      success: (path) async {
        if (path == null || path.isEmpty) {
          return;
        }
        final inspection = await _repository.inspectTemplate(path);
        if (!ref.mounted) return;
        inspection.when(
          success: (result) {
            state = state.copyWith(
              templatePath: path,
              templateName: result.template.name,
              placeholders: result.template.placeholders,
              mapping: result.restoredMapping ?? const <String, String>{},
              mappingDirty: false,
              status: DocumentFactoryStatus.idle,
              clearError: true,
              clearJob: true,
            );
          },
          failure: (failure) => _showError(failure.message),
        );
      },
      failure: (failure) async => _showError(failure.message),
    );
  }

  Future<void> pickDataSheet() async {
    final pickResult = await _repository.pickDataSheetFile();
    if (!ref.mounted) return;
    await pickResult.when(
      success: (path) async {
        if (path == null || path.isEmpty) {
          return;
        }
        final inspection = await _repository.inspectDataSheet(path);
        if (!ref.mounted) return;
        inspection.when(
          success: (result) {
            state = state.copyWith(
              dataSheetPath: path,
              dataSheetName: _basename(path),
              sheetHeaders: result.headers,
              dataRowCount: result.dataRowCount,
              status: DocumentFactoryStatus.idle,
              clearError: true,
              clearJob: true,
            );
          },
          failure: (failure) => _showError(failure.message),
        );
      },
      failure: (failure) async => _showError(failure.message),
    );
  }

  Future<void> pickOutputFolder() async {
    final pickResult = await _repository.pickOutputFolder();
    if (!ref.mounted) return;
    pickResult.when(
      success: (path) {
        if (path == null || path.isEmpty) {
          return;
        }
        state = state.copyWith(
          outputDirPath: path,
          status: DocumentFactoryStatus.idle,
          clearError: true,
        );
      },
      failure: (failure) => _showError(failure.message),
    );
  }

  void updateMapping(String placeholder, String column) {
    state = state.copyWith(
      mapping: <String, String>{...state.mapping, placeholder: column},
      mappingDirty: true,
    );
  }

  /// Returns true when the mapping was persisted (SPEC §4.1 confirmation).
  Future<bool> saveMapping() async {
    final templatePath = state.templatePath;
    if (templatePath == null || !state.isFullyMapped) {
      return false;
    }
    final result = await _repository.saveMapping(templatePath, state.mapping);
    if (!ref.mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(mappingDirty: false);
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<void> generate() async {
    if (!state.canGenerate) {
      return;
    }
    state = state.copyWith(
      status: DocumentFactoryStatus.generating,
      doneCount: 0,
      failedCount: 0,
      skippedCount: 0,
      totalRows: state.dataRowCount,
      showInterruptedNotice: false,
      clearError: true,
      clearJob: true,
    );

    final result = await _repository.runBatch(
      templatePath: state.templatePath!,
      dataSheetPath: state.dataSheetPath!,
      outputDirPath: state.outputDirPath!,
      mapping: state.mapping,
      onProgress: (progress) {
        if (!ref.mounted) return;
        state = state.copyWith(
          doneCount: progress.done,
          failedCount: progress.failed,
          skippedCount: progress.skipped,
          totalRows: progress.total,
        );
      },
    );
    if (!ref.mounted) return;

    result.when(
      success: (job) {
        state = state.copyWith(
          status: switch (job.status) {
            DocumentJobStatus.succeeded => DocumentFactoryStatus.success,
            DocumentJobStatus.partial => DocumentFactoryStatus.partial,
            DocumentJobStatus.failed => DocumentFactoryStatus.error,
            _ => DocumentFactoryStatus.idle,
          },
          errorCode: job.status == DocumentJobStatus.failed
              ? DocumentFactoryFailureCodes.generation
              : null,
          doneCount: job.doneCount,
          failedCount: job.failedCount,
          skippedCount: job.skippedCount,
          totalRows: job.totalRows,
          lastJob: job,
          clearError: job.status != DocumentJobStatus.failed,
        );
      },
      failure: (failure) => _showError(failure.message),
    );
  }

  /// SPEC §6 — "Try again" re-enables generation without clearing selections.
  void dismissError() {
    state = state.copyWith(
      status: DocumentFactoryStatus.idle,
      clearError: true,
    );
  }

  Future<void> openOutputFolder() async {
    final path = state.outputDirPath;
    if (path == null) {
      return;
    }
    final result = await _repository.revealOutputFolder(path);
    if (!ref.mounted) return;
    result.when(
      success: (_) {},
      failure: (failure) => _showError(failure.message),
    );
  }

  void _showError(String rawCode) {
    state = state.copyWith(
      status: DocumentFactoryStatus.error,
      errorCode: _codeOf(rawCode),
    );
  }

  /// Failure messages carry the stable code, optionally followed by
  /// technical detail after a colon (e.g. `document_factory.sheetRead: …`).
  String _codeOf(String message) {
    final head = message.split(':').first.trim();
    const known = {
      DocumentFactoryFailureCodes.templateRead,
      DocumentFactoryFailureCodes.sheetRead,
      DocumentFactoryFailureCodes.duplicateHeaders,
      DocumentFactoryFailureCodes.noPlaceholders,
      DocumentFactoryFailureCodes.outputNotWritable,
      DocumentFactoryFailureCodes.mappingSave,
      DocumentFactoryFailureCodes.generation,
      DocumentFactoryFailureCodes.reveal,
    };
    return known.contains(head) ? head : DocumentFactoryFailureCodes.generation;
  }

  String _basename(String path) {
    final segments = path.split(RegExp(r'[/\\]'));
    return segments.isEmpty ? path : segments.last;
  }
}

final documentFactoryViewModelProvider =
    NotifierProvider<DocumentFactoryViewModel, DocumentFactoryUiState>(
      DocumentFactoryViewModel.new,
    );
