/// Domain failures for document factory. Mapped to [Failure] at boundaries.
///
/// Each failure carries a stable machine-readable [code] (see
/// [DocumentFactoryFailureCodes]) so the presentation layer can map it to a
/// localized message. [message] stays an English technical description for
/// logs and debugging — domain and data layers remain locale-free.
sealed class DocumentFactoryFailure {
  const DocumentFactoryFailure({required this.code, required this.message});

  final String code;
  final String message;
}

/// Stable failure codes consumed by the presentation layer for localization.
abstract final class DocumentFactoryFailureCodes {
  static const templateRead = 'document_factory.templateRead';
  static const sheetRead = 'document_factory.sheetRead';
  static const duplicateHeaders = 'document_factory.duplicateHeaders';
  static const noPlaceholders = 'document_factory.noPlaceholders';
  static const outputNotWritable = 'document_factory.outputNotWritable';
  static const mappingSave = 'document_factory.mappingSave';
  static const generation = 'document_factory.generation';
  static const rowMissingValue = 'document_factory.rowMissingValue';
  static const rowRender = 'document_factory.rowRender';
  static const reveal = 'document_factory.reveal';
}

final class TemplateReadFailure extends DocumentFactoryFailure {
  const TemplateReadFailure([
    String message = 'Could not read the template file',
  ]) : super(code: DocumentFactoryFailureCodes.templateRead, message: message);
}

final class SheetReadFailure extends DocumentFactoryFailure {
  const SheetReadFailure([String message = 'Could not read the data sheet'])
    : super(code: DocumentFactoryFailureCodes.sheetRead, message: message);
}

final class DuplicateHeadersFailure extends DocumentFactoryFailure {
  const DuplicateHeadersFailure([
    String message = 'The data sheet has duplicate column headers',
  ]) : super(
         code: DocumentFactoryFailureCodes.duplicateHeaders,
         message: message,
       );
}

final class NoPlaceholdersFailure extends DocumentFactoryFailure {
  const NoPlaceholdersFailure([
    String message = 'No placeholders found in the template',
  ]) : super(
         code: DocumentFactoryFailureCodes.noPlaceholders,
         message: message,
       );
}

final class OutputNotWritableFailure extends DocumentFactoryFailure {
  const OutputNotWritableFailure([
    String message = 'The output folder is not writable',
  ]) : super(
         code: DocumentFactoryFailureCodes.outputNotWritable,
         message: message,
       );
}

final class MappingSaveFailure extends DocumentFactoryFailure {
  const MappingSaveFailure([
    String message = 'Could not save the field mapping',
  ]) : super(code: DocumentFactoryFailureCodes.mappingSave, message: message);
}

final class GenerationFailure extends DocumentFactoryFailure {
  const GenerationFailure([
    String message = 'Something went wrong during PDF generation',
  ]) : super(code: DocumentFactoryFailureCodes.generation, message: message);
}

final class RevealOutputFailure extends DocumentFactoryFailure {
  const RevealOutputFailure([
    String message = 'Could not open the output folder on this desktop',
  ]) : super(code: DocumentFactoryFailureCodes.reveal, message: message);
}
