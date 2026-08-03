import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/validation/mapping_validator.dart';

enum DocumentFactoryStatus { idle, generating, success, partial, error }

/// UI state for the document factory screen.
class DocumentFactoryUiState {
  const DocumentFactoryUiState({
    this.isLoading = false,
    this.templatePath,
    this.templateName,
    this.placeholders = const <String>[],
    this.dataSheetPath,
    this.dataSheetName,
    this.sheetHeaders = const <String>[],
    this.dataRowCount = 0,
    this.mapping = const <String, String>{},
    this.mappingDirty = false,
    this.outputDirPath,
    this.status = DocumentFactoryStatus.idle,
    this.doneCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.totalRows = 0,
    this.lastJob,
    this.errorCode,
    this.showInterruptedNotice = false,
  });

  final bool isLoading;
  final String? templatePath;
  final String? templateName;
  final List<String> placeholders;
  final String? dataSheetPath;
  final String? dataSheetName;
  final List<String> sheetHeaders;
  final int dataRowCount;
  final Map<String, String> mapping;
  final bool mappingDirty;
  final String? outputDirPath;
  final DocumentFactoryStatus status;
  final int doneCount;
  final int failedCount;
  final int skippedCount;
  final int totalRows;
  final DocumentJob? lastJob;

  /// Stable DocumentFactoryFailureCodes value for the current error state.
  final String? errorCode;
  final bool showInterruptedNotice;

  bool get isGenerating => status == DocumentFactoryStatus.generating;

  bool get isFullyMapped => MappingValidator.isComplete(placeholders, mapping);

  /// SPEC R1 — all placeholders mapped, template/sheet/output selected.
  bool get canGenerate =>
      templatePath != null &&
      dataSheetPath != null &&
      outputDirPath != null &&
      placeholders.isNotEmpty &&
      isFullyMapped &&
      !isGenerating;

  bool get canSaveMapping =>
      placeholders.isNotEmpty &&
      sheetHeaders.isNotEmpty &&
      isFullyMapped &&
      mappingDirty &&
      !isGenerating;

  double get progressFraction {
    if (totalRows <= 0) {
      return 0;
    }
    return (doneCount + failedCount + skippedCount) / totalRows;
  }

  String? get outputDirName {
    final path = outputDirPath;
    if (path == null || path.isEmpty) {
      return null;
    }
    final segments = path.split(RegExp(r'[/\\]'));
    return segments.isEmpty ? path : segments.last;
  }

  DocumentFactoryUiState copyWith({
    bool? isLoading,
    String? templatePath,
    String? templateName,
    List<String>? placeholders,
    String? dataSheetPath,
    String? dataSheetName,
    List<String>? sheetHeaders,
    int? dataRowCount,
    Map<String, String>? mapping,
    bool? mappingDirty,
    String? outputDirPath,
    DocumentFactoryStatus? status,
    int? doneCount,
    int? failedCount,
    int? skippedCount,
    int? totalRows,
    DocumentJob? lastJob,
    String? errorCode,
    bool? showInterruptedNotice,
    bool clearError = false,
    bool clearJob = false,
  }) {
    return DocumentFactoryUiState(
      isLoading: isLoading ?? this.isLoading,
      templatePath: templatePath ?? this.templatePath,
      templateName: templateName ?? this.templateName,
      placeholders: placeholders ?? this.placeholders,
      dataSheetPath: dataSheetPath ?? this.dataSheetPath,
      dataSheetName: dataSheetName ?? this.dataSheetName,
      sheetHeaders: sheetHeaders ?? this.sheetHeaders,
      dataRowCount: dataRowCount ?? this.dataRowCount,
      mapping: mapping ?? this.mapping,
      mappingDirty: mappingDirty ?? this.mappingDirty,
      outputDirPath: outputDirPath ?? this.outputDirPath,
      status: status ?? this.status,
      doneCount: doneCount ?? this.doneCount,
      failedCount: failedCount ?? this.failedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      totalRows: totalRows ?? this.totalRows,
      lastJob: clearJob ? null : (lastJob ?? this.lastJob),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      showInterruptedNotice:
          showInterruptedNotice ?? this.showInterruptedNotice,
    );
  }
}
