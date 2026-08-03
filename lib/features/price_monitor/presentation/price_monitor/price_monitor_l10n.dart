import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Maps stable [PriceMonitorFailureCodes] to localized messages.
///
/// Failures travel across the data/presentation boundary as a [Failure]
/// whose `message` is the failure code (same pattern as barcode inventory);
/// anything that is not a known code falls back to the generic message.
extension PriceMonitorFailureL10n on AppLocalizations {
  String priceMonitorFailureMessage(String code) {
    return switch (code) {
      PriceMonitorFailureCodes.load => priceMonitorLoadErrorMessage,
      PriceMonitorFailureCodes.save ||
      PriceMonitorFailureCodes.delete => priceMonitorSaveError,
      PriceMonitorFailureCodes.fetch => priceMonitorFetchFailed,
      PriceMonitorFailureCodes.parse => priceMonitorParseFailed,
      PriceMonitorFailureCodes.validationLabel => priceMonitorLabelError,
      PriceMonitorFailureCodes.validationLabelTooLong =>
        priceMonitorLabelTooLongError,
      PriceMonitorFailureCodes.validationUrl => priceMonitorUrlError,
      PriceMonitorFailureCodes.validationThreshold =>
        priceMonitorThresholdError,
      _ => priceMonitorErrorGeneric,
    };
  }
}
