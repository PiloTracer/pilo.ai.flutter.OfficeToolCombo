import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';

/// Read/write contract for price watches and their latest samples.
abstract class PriceMonitorRepository {
  /// Loads all watches, ordered by creation (insertion order).
  Future<Result<List<PriceWatch>>> loadWatches();

  /// Validates (R2, R8, R9) and persists [watch]; returns the stored watch.
  Future<Result<PriceWatch>> saveWatch(PriceWatch watch);

  Future<Result<void>> deleteWatch(String watchId);

  Future<Result<void>> setWatchEnabled(String watchId, bool enabled);

  /// Latest sample per watch (success or failed), for list display.
  Future<Map<String, PriceSample>> readLatestSamples();

  /// Last *successful* sample for cross detection (R3/R4 previous sample).
  Future<PriceSample?> readLastSuccessfulSample(String watchId);

  /// R5 — clears the baseline so the next successful fetch after
  /// (re-)enabling a watch establishes a fresh one without notifying.
  Future<void> resetCrossBaseline(String watchId);

  /// Records [sample] as the latest display sample; successful samples also
  /// overwrite the last-successful record used for cross detection.
  Future<void> writeSample(PriceSample sample);

  /// R6 — poll interval in minutes; defaults to
  /// [PriceMonitorRepository.defaultPollMinutes].
  Future<int> readPollIntervalMinutes();

  static const defaultPollMinutes = 10;
}

/// Monotonic id source — microtime alone can repeat in fast tests.
class PriceWatchIdGenerator {
  static var _counter = 0;

  static String nextId() {
    _counter += 1;
    return 'watch-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
