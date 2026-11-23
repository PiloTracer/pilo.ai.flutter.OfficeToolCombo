/// Domain failures for the report consolidator. Mapped to [Failure] at boundaries.
sealed class ConsolidatorFailure {
  const ConsolidatorFailure(this.message);

  final String message;
}

final class EmptyFolderFailure extends ConsolidatorFailure {
  const EmptyFolderFailure() : super(emptyFolderMessage);

  static const emptyFolderMessage =
      'No spreadsheets found in the selected folder';
}

final class UnreadableFolderFailure extends ConsolidatorFailure {
  UnreadableFolderFailure(String detail)
    : super('Could not read folder: $detail');
}

final class WriteFailedFailure extends ConsolidatorFailure {
  WriteFailedFailure(String detail)
    : super('Could not write consolidated workbook: $detail');
}

final class CancelledFailure extends ConsolidatorFailure {
  const CancelledFailure() : super('Merge was cancelled');
}

final class UnexpectedConsolidatorFailure extends ConsolidatorFailure {
  UnexpectedConsolidatorFailure(String detail)
    : super('Unexpected consolidator error: $detail');
}
