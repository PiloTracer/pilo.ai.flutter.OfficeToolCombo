import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';

/// Persists document factory mappings and job metadata across app restarts.
abstract class DocumentFactoryPreferencesStore {
  /// Completed job metadata older than this is pruned (SPEC §7 retention).
  static const jobRetention = Duration(days: 30);

  Future<Map<String, String>?> readMapping(String templatePath);

  Future<void> writeMapping(String templatePath, Map<String, String> mapping);

  Future<DocumentJob?> readLastJob();

  Future<void> writeLastJob(DocumentJob job);
}

class InMemoryDocumentFactoryPreferencesStore
    implements DocumentFactoryPreferencesStore {
  final Map<String, Map<String, String>> _mappings = {};
  DocumentJob? lastJob;

  @override
  Future<Map<String, String>?> readMapping(String templatePath) async {
    final mapping = _mappings[templatePath];
    return mapping == null ? null : Map<String, String>.from(mapping);
  }

  @override
  Future<void> writeMapping(
    String templatePath,
    Map<String, String> mapping,
  ) async {
    _mappings[templatePath] = Map<String, String>.from(mapping);
  }

  @override
  Future<DocumentJob?> readLastJob() async => lastJob;

  @override
  Future<void> writeLastJob(DocumentJob job) async {
    lastJob = job;
  }
}
