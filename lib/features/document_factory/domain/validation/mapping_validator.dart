/// Validates a field mapping (placeholder → column header) against the
/// discovered placeholders and the data-sheet header row.
abstract final class MappingValidator {
  /// Placeholders without a non-empty column assignment (SPEC R1).
  static List<String> unmappedPlaceholders(
    List<String> placeholders,
    Map<String, String> mapping,
  ) {
    return placeholders
        .where((placeholder) => (mapping[placeholder] ?? '').isEmpty)
        .toList(growable: false);
  }

  static bool isComplete(
    List<String> placeholders,
    Map<String, String> mapping,
  ) {
    return placeholders.isNotEmpty &&
        unmappedPlaceholders(placeholders, mapping).isEmpty;
  }

  /// Column assignments whose header no longer exists in the sheet.
  static List<String> unknownColumns(
    Map<String, String> mapping,
    List<String> headers,
  ) {
    final headerSet = headers.toSet();
    return mapping.values
        .where((column) => column.isNotEmpty && !headerSet.contains(column))
        .toList(growable: false);
  }

  /// A mapping may only be saved when its keys match the discovered
  /// placeholders exactly and every value is a known column (SPEC §7).
  static bool isSaveable(
    List<String> placeholders,
    Map<String, String> mapping,
    List<String> headers,
  ) {
    if (!isComplete(placeholders, mapping)) {
      return false;
    }
    if (mapping.keys.toSet().difference(placeholders.toSet()).isNotEmpty) {
      return false;
    }
    return unknownColumns(mapping, headers).isEmpty;
  }
}
