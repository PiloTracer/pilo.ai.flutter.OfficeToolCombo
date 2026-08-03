import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/features/price_monitor/domain/validation/watch_validator.dart';

void main() {
  group('WatchValidator.validateLabel (R9)', () {
    test('empty or blank labels are rejected', () {
      expect(
        WatchValidator.validateLabel(''),
        PriceMonitorFailureCodes.validationLabel,
      );
      expect(
        WatchValidator.validateLabel('   '),
        PriceMonitorFailureCodes.validationLabel,
      );
    });

    test('labels over 120 characters are rejected', () {
      expect(
        WatchValidator.validateLabel('x' * 121),
        PriceMonitorFailureCodes.validationLabelTooLong,
      );
      expect(WatchValidator.validateLabel('x' * 120), isNull);
    });

    test('normal label passes', () {
      expect(WatchValidator.validateLabel('Coffee beans 1kg'), isNull);
    });
  });

  group('WatchValidator.validateUrl (R8)', () {
    test('only http and https are accepted', () {
      expect(
        WatchValidator.validateUrl('ftp://example.com'),
        PriceMonitorFailureCodes.validationUrl,
      );
      expect(
        WatchValidator.validateUrl('example.com'),
        PriceMonitorFailureCodes.validationUrl,
      );
      expect(
        WatchValidator.validateUrl('http://'),
        PriceMonitorFailureCodes.validationUrl,
      );
      expect(WatchValidator.validateUrl('http://example.com'), isNull);
      expect(WatchValidator.validateUrl('https://example.com/p?q=1'), isNull);
    });
  });

  group('WatchValidator.validateThreshold (R2)', () {
    test('zero and negative thresholds are rejected', () {
      expect(
        WatchValidator.validateThreshold('0'),
        PriceMonitorFailureCodes.validationThreshold,
      );
      expect(
        WatchValidator.validateThreshold('-1'),
        PriceMonitorFailureCodes.validationThreshold,
      );
      expect(
        WatchValidator.validateThreshold('0.00'),
        PriceMonitorFailureCodes.validationThreshold,
      );
    });

    test('non-numeric input is rejected', () {
      expect(
        WatchValidator.validateThreshold('abc'),
        PriceMonitorFailureCodes.validationThreshold,
      );
      expect(
        WatchValidator.validateThreshold(''),
        PriceMonitorFailureCodes.validationThreshold,
      );
    });

    test('positive decimals pass', () {
      expect(WatchValidator.validateThreshold('0.01'), isNull);
      expect(WatchValidator.validateThreshold('10'), isNull);
    });
  });
}
