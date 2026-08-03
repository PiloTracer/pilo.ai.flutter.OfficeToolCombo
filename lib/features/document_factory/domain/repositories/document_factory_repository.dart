import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_template.dart';

/// Result of reading a template file: discovered placeholders plus the
/// mapping restored from the store for this exact file path (SPEC R6).
class TemplateInspection {
  const TemplateInspection({
    required this.template,
    required this.restoredMapping,
  });

  final DocumentTemplate template;
  final Map<String, String>? restoredMapping;
}

/// Result of reading a data sheet: header row and data row count.
class SheetInspection {
  const SheetInspection({required this.headers, required this.dataRowCount});

  final List<String> headers;
  final int dataRowCount;
}

/// Progress emitted per processed row while a batch runs.
class DocumentBatchProgress {
  const DocumentBatchProgress({
    required this.done,
    required this.failed,
    required this.skipped,
    required this.total,
  });

  final int done;
  final int failed;
  final int skipped;
  final int total;
}

/// File/data access for the document factory.
///
/// Failures are returned as `Err` whose `Failure.message` carries a stable
/// code from `DocumentFactoryFailureCodes`; the presentation layer maps the
/// code to a localized message (same pattern as barcode inventory).
abstract class DocumentFactoryRepository {
  /// Opens the file picker for an HTML template; null when cancelled.
  Future<Result<String?>> pickTemplateFile();

  /// Opens the file picker for an `.xlsx` data sheet; null when cancelled.
  Future<Result<String?>> pickDataSheetFile();

  /// Opens the folder picker for the output directory; null when cancelled.
  Future<Result<String?>> pickOutputFolder();

  /// Reads the template file and discovers its placeholders.
  Future<Result<TemplateInspection>> inspectTemplate(String path);

  /// Reads the header row of the data sheet.
  Future<Result<SheetInspection>> inspectDataSheet(String path);

  /// Persists the mapping for [templatePath] (SPEC R6).
  Future<Result<void>> saveMapping(
    String templatePath,
    Map<String, String> mapping,
  );

  /// Runs the batch in a background isolate with per-row progress.
  ///
  /// Probes output-folder writability before the job starts (SPEC R4) and
  /// records the job status so an interrupted run is detected on the next
  /// launch (SPEC §4.4).
  Future<Result<DocumentJob>> runBatch({
    required String templatePath,
    required String dataSheetPath,
    required String outputDirPath,
    required Map<String, String> mapping,
    void Function(DocumentBatchProgress progress)? onProgress,
  });

  /// Last persisted job record, if any. A record still marked `running`
  /// means the previous app session was interrupted.
  Future<DocumentJob?> readLastJob();

  /// Marks a stale `running` record as interrupted (failed).
  Future<void> markLastJobInterrupted();

  /// Opens the output folder in the platform file manager.
  Future<Result<void>> revealOutputFolder(String path);
}
