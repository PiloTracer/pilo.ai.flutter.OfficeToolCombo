import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';

/// Persists price watches, latest samples, and poll settings across app
/// restarts (SPEC §7 — SharedPreferences-backed store for F4).
abstract class PriceMonitorStore {
  Future<List<PriceWatch>> readWatches();

  Future<void> writeWatches(List<PriceWatch> watches);

  /// Latest sample per watch id (any status), for list display.
  Future<Map<String, PriceSample>> readLatestSamples();

  Future<void> writeLatestSample(PriceSample sample);

  Future<void> removeSamples(String watchId);

  /// Last successful sample per watch id, for cross detection.
  Future<PriceSample?> readLastSuccessfulSample(String watchId);

  Future<void> writeLastSuccessfulSample(PriceSample sample);

  /// Drops the cross-detection baseline (R5 — first successful fetch after
  /// enable establishes a fresh baseline and never notifies).
  Future<void> clearLastSuccessfulSample(String watchId);

  /// R6 — `pricePollMinutes`; [PriceMonitorRepository.defaultPollMinutes]
  /// when never set.
  Future<int> readPollMinutes();

  Future<void> writePollMinutes(int minutes);
}

class InMemoryPriceMonitorStore implements PriceMonitorStore {
  final List<PriceWatch> watches = [];
  final Map<String, PriceSample> latestSamples = {};
  final Map<String, PriceSample> lastSuccessfulSamples = {};
  int? pollMinutes;

  @override
  Future<List<PriceWatch>> readWatches() async =>
      List<PriceWatch>.from(watches);

  @override
  Future<void> writeWatches(List<PriceWatch> watches) async {
    this.watches
      ..clear()
      ..addAll(watches);
  }

  @override
  Future<Map<String, PriceSample>> readLatestSamples() async =>
      Map<String, PriceSample>.from(latestSamples);

  @override
  Future<void> writeLatestSample(PriceSample sample) async {
    latestSamples[sample.watchId] = sample;
  }

  @override
  Future<void> removeSamples(String watchId) async {
    latestSamples.remove(watchId);
    lastSuccessfulSamples.remove(watchId);
  }

  @override
  Future<PriceSample?> readLastSuccessfulSample(String watchId) async =>
      lastSuccessfulSamples[watchId];

  @override
  Future<void> writeLastSuccessfulSample(PriceSample sample) async {
    lastSuccessfulSamples[sample.watchId] = sample;
  }

  @override
  Future<void> clearLastSuccessfulSample(String watchId) async {
    lastSuccessfulSamples.remove(watchId);
  }

  @override
  Future<int> readPollMinutes() async =>
      pollMinutes ?? PriceMonitorRepository.defaultPollMinutes;

  @override
  Future<void> writePollMinutes(int minutes) async {
    pollMinutes = minutes;
  }
}
