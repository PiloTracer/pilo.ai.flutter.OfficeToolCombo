import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/services/threshold_cross_detector.dart';

void main() {
  final ten = Decimal.parse('10');

  bool crossed(
    PriceWatchDirection direction,
    String? previous,
    String current,
  ) {
    return ThresholdCrossDetector.didCross(
      direction: direction,
      threshold: ten,
      previous: previous == null ? null : Decimal.parse(previous),
      current: Decimal.parse(current),
    );
  }

  group('ThresholdCrossDetector — above (R3)', () {
    test('first sample establishes baseline and never notifies (R5)', () {
      expect(crossed(PriceWatchDirection.above, null, '15'), isFalse);
      expect(crossed(PriceWatchDirection.above, null, '5'), isFalse);
    });

    test('crossing up to the threshold notifies (>=)', () {
      expect(crossed(PriceWatchDirection.above, '9', '10'), isTrue);
      expect(crossed(PriceWatchDirection.above, '9', '11'), isTrue);
    });

    test('staying on the alert side does not repeat', () {
      expect(crossed(PriceWatchDirection.above, '10', '11'), isFalse);
    });

    test('cross-back re-arms, next cross notifies again', () {
      expect(crossed(PriceWatchDirection.above, '11', '9'), isFalse);
      expect(crossed(PriceWatchDirection.above, '9', '10'), isTrue);
    });
  });

  group('ThresholdCrossDetector — below (R4)', () {
    test('crossing down to the threshold notifies (<=)', () {
      expect(crossed(PriceWatchDirection.below, '11', '10'), isTrue);
      expect(crossed(PriceWatchDirection.below, '11', '9'), isTrue);
    });

    test('staying below does not repeat', () {
      expect(crossed(PriceWatchDirection.below, '9', '8'), isFalse);
    });

    test('cross-back re-arms', () {
      expect(crossed(PriceWatchDirection.below, '9', '11'), isFalse);
      expect(crossed(PriceWatchDirection.below, '11', '9'), isTrue);
    });
  });
}
