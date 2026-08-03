import 'package:decimal/decimal.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';

/// Threshold cross detection (R3, R4, R5). Pure and stateless — the
/// previous successful sample carries all the state needed.
abstract final class ThresholdCrossDetector {
  /// True when [price] sits on the alert side of [threshold].
  static bool isOnAlertSide({
    required PriceWatchDirection direction,
    required Decimal threshold,
    required Decimal price,
  }) {
    return switch (direction) {
      PriceWatchDirection.above => price >= threshold,
      PriceWatchDirection.below => price <= threshold,
    };
  }

  /// Whether fetching [current] should fire a notification.
  ///
  /// - R5: with no previous successful sample, [current] only establishes
  ///   the baseline — never notifies.
  /// - R3/R4: notify only on the transition into the alert side; staying on
  ///   the alert side does not re-notify until the price crosses back.
  static bool didCross({
    required PriceWatchDirection direction,
    required Decimal threshold,
    required Decimal? previous,
    required Decimal current,
  }) {
    if (previous == null) {
      return false;
    }
    final wasOnAlertSide = isOnAlertSide(
      direction: direction,
      threshold: threshold,
      price: previous,
    );
    final isNowOnAlertSide = isOnAlertSide(
      direction: direction,
      threshold: threshold,
      price: current,
    );
    return !wasOnAlertSide && isNowOnAlertSide;
  }
}
