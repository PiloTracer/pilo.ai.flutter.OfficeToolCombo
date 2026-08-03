/// A user-owned HTML template file plus its discovered placeholders and the
/// operator's saved field mapping (placeholder → data-sheet column header).
class DocumentTemplate {
  const DocumentTemplate({
    required this.filePath,
    required this.placeholders,
    this.fieldMapping = const <String, String>{},
  });

  final String filePath;
  final List<String> placeholders;
  final Map<String, String> fieldMapping;

  /// Basename only — full paths are never shown in the UI (SPEC R9).
  String get name {
    final segments = filePath.split(RegExp(r'[/\\]'));
    return segments.isEmpty ? filePath : segments.last;
  }

  bool get hasPlaceholders => placeholders.isNotEmpty;

  /// SPEC R1 — every discovered placeholder must map to exactly one
  /// non-empty column header before a batch can start.
  bool get isFullyMapped => placeholders.every(
    (placeholder) => (fieldMapping[placeholder] ?? '').isNotEmpty,
  );

  DocumentTemplate copyWith({
    String? filePath,
    List<String>? placeholders,
    Map<String, String>? fieldMapping,
  }) {
    return DocumentTemplate(
      filePath: filePath ?? this.filePath,
      placeholders: placeholders ?? this.placeholders,
      fieldMapping: fieldMapping ?? this.fieldMapping,
    );
  }
}
