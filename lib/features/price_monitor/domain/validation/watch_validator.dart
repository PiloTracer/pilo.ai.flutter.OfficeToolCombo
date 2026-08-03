import 'package:decimal/decimal.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';

/// Pure field validators for the watch editor (R2, R8, R9).
///
/// Each returns null when valid, otherwise a stable
/// [PriceMonitorFailureCodes] value that the presentation layer maps to a
/// localized message.
abstract final class WatchValidator {
  /// R9 — label required after trim; max [PriceWatch.maxLabelLength] chars.
  static String? validateLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return PriceMonitorFailureCodes.validationLabel;
    }
    if (trimmed.length > PriceWatch.maxLabelLength) {
      return PriceMonitorFailureCodes.validationLabelTooLong;
    }
    return null;
  }

  /// R8 — only http and https URLs with a host are accepted.
  static String? validateUrl(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return PriceMonitorFailureCodes.validationUrl;
    }
    return null;
  }

  /// R2 — threshold must parse as a Decimal strictly greater than zero.
  static String? validateThreshold(String threshold) {
    final parsed = Decimal.tryParse(threshold.trim());
    if (parsed == null || parsed <= Decimal.zero) {
      return PriceMonitorFailureCodes.validationThreshold;
    }
    return null;
  }
}
