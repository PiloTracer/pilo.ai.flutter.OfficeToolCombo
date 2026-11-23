/// Domain failures for price monitor. Mapped to [Failure] at boundaries.
///
/// Each failure carries a stable machine-readable [code] (see
/// [PriceMonitorFailureCodes]) so the presentation layer can map it to a
/// localized message. [message] stays an English technical description for
/// logs and debugging — domain and data layers remain locale-free.
sealed class PriceMonitorFailure {
  const PriceMonitorFailure({required this.code, required this.message});

  final String code;
  final String message;
}

/// Stable failure codes consumed by the presentation layer for localization.
abstract final class PriceMonitorFailureCodes {
  static const load = 'price_monitor.load';
  static const save = 'price_monitor.save';
  static const delete = 'price_monitor.delete';
  static const fetch = 'price_monitor.fetch';
  static const parse = 'price_monitor.parse';
  static const validationLabel = 'price_monitor.validation.label';
  static const validationLabelTooLong = 'price_monitor.validation.labelTooLong';
  static const validationUrl = 'price_monitor.validation.url';
  static const validationThreshold = 'price_monitor.validation.threshold';
  static const osNotifyFailed = 'price_monitor.os_notify_failed';
}

final class PriceWatchLoadFailure extends PriceMonitorFailure {
  const PriceWatchLoadFailure([String message = 'Could not load watches'])
    : super(code: PriceMonitorFailureCodes.load, message: message);
}

final class PriceWatchSaveFailure extends PriceMonitorFailure {
  const PriceWatchSaveFailure([String message = 'Could not save the watch'])
    : super(code: PriceMonitorFailureCodes.save, message: message);
}

final class PriceWatchDeleteFailure extends PriceMonitorFailure {
  const PriceWatchDeleteFailure([String message = 'Could not delete the watch'])
    : super(code: PriceMonitorFailureCodes.delete, message: message);
}

/// Field-level validation failure (R2, R8, R9). The [code] is one of the
/// `price_monitor.validation.*` constants.
final class PriceWatchValidationFailure extends PriceMonitorFailure {
  const PriceWatchValidationFailure({
    required super.code,
    required super.message,
  });
}

final class PriceFetchFailure extends PriceMonitorFailure {
  const PriceFetchFailure([String message = 'The price could not be fetched'])
    : super(code: PriceMonitorFailureCodes.fetch, message: message);
}

final class PriceParseFailure extends PriceMonitorFailure {
  const PriceParseFailure([
    String message = 'No price could be read from the page',
  ]) : super(code: PriceMonitorFailureCodes.parse, message: message);
}

final class OsNotificationFailure extends PriceMonitorFailure {
  const OsNotificationFailure([
    String message = 'The OS notification could not be shown',
  ]) : super(code: PriceMonitorFailureCodes.osNotifyFailed, message: message);
}
