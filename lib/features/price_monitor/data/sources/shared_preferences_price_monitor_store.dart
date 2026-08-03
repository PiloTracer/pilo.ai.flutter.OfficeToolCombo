import 'dart:convert';

import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads [SharedPreferences] on first read/write so the repository provider
/// stays synchronous. Watches and samples are stored as JSON documents.
class SharedPreferencesPriceMonitorStore implements PriceMonitorStore {
  SharedPreferencesPriceMonitorStore();

  static const watchesKey = 'price_monitor_watches';
  static const latestSamplesKey = 'price_monitor_samples';
  static const lastSuccessfulSamplesKey = 'price_monitor_last_success';
  static const pollMinutesKey = 'pricePollMinutes';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<PriceWatch>> readWatches() async {
    final preferences = await _instance();
    final raw = preferences.getString(watchesKey);
    if (raw == null || raw.isEmpty) {
      return <PriceWatch>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => PriceWatch.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      return <PriceWatch>[];
    }
  }

  @override
  Future<void> writeWatches(List<PriceWatch> watches) async {
    final preferences = await _instance();
    final encoded = jsonEncode(watches.map((watch) => watch.toJson()).toList());
    await preferences.setString(watchesKey, encoded);
  }

  @override
  Future<Map<String, PriceSample>> readLatestSamples() async {
    return _readSampleMap(latestSamplesKey);
  }

  @override
  Future<void> writeLatestSample(PriceSample sample) async {
    await _writeSampleToMap(latestSamplesKey, sample);
  }

  @override
  Future<void> removeSamples(String watchId) async {
    final preferences = await _instance();
    for (final key in [latestSamplesKey, lastSuccessfulSamplesKey]) {
      final samples = await _readSampleMap(key);
      if (samples.remove(watchId) != null) {
        await preferences.setString(key, _encodeSampleMap(samples));
      }
    }
  }

  @override
  Future<PriceSample?> readLastSuccessfulSample(String watchId) async {
    final samples = await _readSampleMap(lastSuccessfulSamplesKey);
    return samples[watchId];
  }

  @override
  Future<void> writeLastSuccessfulSample(PriceSample sample) async {
    await _writeSampleToMap(lastSuccessfulSamplesKey, sample);
  }

  @override
  Future<void> clearLastSuccessfulSample(String watchId) async {
    final preferences = await _instance();
    final samples = await _readSampleMap(lastSuccessfulSamplesKey);
    if (samples.remove(watchId) != null) {
      await preferences.setString(
        lastSuccessfulSamplesKey,
        _encodeSampleMap(samples),
      );
    }
  }

  @override
  Future<int> readPollMinutes() async {
    final preferences = await _instance();
    final minutes = preferences.getInt(pollMinutesKey);
    if (minutes == null || minutes < 1) {
      return PriceMonitorRepository.defaultPollMinutes;
    }
    return minutes;
  }

  @override
  Future<void> writePollMinutes(int minutes) async {
    final preferences = await _instance();
    await preferences.setInt(pollMinutesKey, minutes);
  }

  Future<Map<String, PriceSample>> _readSampleMap(String key) async {
    final preferences = await _instance();
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, PriceSample>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (watchId, value) => MapEntry(
          watchId,
          PriceSample.fromJson(value as Map<String, dynamic>),
        ),
      );
    } on Object {
      return <String, PriceSample>{};
    }
  }

  Future<void> _writeSampleToMap(String key, PriceSample sample) async {
    final preferences = await _instance();
    final samples = await _readSampleMap(key);
    samples[sample.watchId] = sample;
    await preferences.setString(key, _encodeSampleMap(samples));
  }

  String _encodeSampleMap(Map<String, PriceSample> samples) {
    return jsonEncode(
      samples.map(
        (watchId, sample) =>
            MapEntry<String, dynamic>(watchId, sample.toJson()),
      ),
    );
  }
}
