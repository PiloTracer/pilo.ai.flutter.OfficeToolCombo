import 'package:office_tool_combo/features/document_factory/domain/failures/document_factory_failure.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Maps stable [DocumentFactoryFailureCodes] to localized messages.
///
/// Failures travel across the data/presentation boundary as a [Failure]
/// whose `message` is the failure code (same pattern as barcode inventory);
/// anything that is not a known code falls back to the generic message.
extension DocumentFactoryFailureL10n on AppLocalizations {
  String documentFactoryFailureMessage(String code) {
    return switch (code) {
      DocumentFactoryFailureCodes.templateRead => documentFactoryErrorTemplate,
      DocumentFactoryFailureCodes.sheetRead => documentFactoryErrorSheet,
      DocumentFactoryFailureCodes.duplicateHeaders =>
        documentFactoryDuplicateHeaders,
      DocumentFactoryFailureCodes.outputNotWritable =>
        documentFactoryErrorOutput,
      DocumentFactoryFailureCodes.mappingSave =>
        documentFactoryMappingSaveError,
      DocumentFactoryFailureCodes.rowMissingValue ||
      DocumentFactoryFailureCodes.rowRender => documentFactoryRowRenderFailure,
      DocumentFactoryFailureCodes.reveal => documentFactoryRevealError,
      _ => documentFactoryErrorGeneric,
    };
  }
}
