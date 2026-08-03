import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';
import 'package:office_tool_combo/features/price_monitor/domain/validation/watch_validator.dart';

/// Store-backed implementation; validation (R2, R8, R9) happens here so
/// both the editor and any future caller get the same guarantees.
class PriceMonitorRepositoryImpl implements PriceMonitorRepository {
  PriceMonitorRepositoryImpl({required this._store, AppLogger? logger})
    : _logger = logger ?? AppLogger();

  final PriceMonitorStore _store;
  final AppLogger _logger;

  @override
  Future<Result<List<PriceWatch>>> loadWatches() async {
    try {
      return Success<List<PriceWatch>>(await _store.readWatches());
    } on Object catch (error, stack) {
      _logger.error('price_monitor.load_failed', error, stack);
      return Err<List<PriceWatch>>(_asFailure(const PriceWatchLoadFailure()));
    }
  }

  @override
  Future<Result<PriceWatch>> saveWatch(PriceWatch watch) async {
    final label = watch.label.trim();
    final validationError =
        WatchValidator.validateLabel(label) ??
        WatchValidator.validateUrl(watch.url) ??
        WatchValidator.validateThreshold(watch.threshold.toString());
    if (validationError != null) {
      _logger.info('price_monitor.validation_failed code=$validationError');
      return Err<PriceWatch>(
        _asFailure(
          PriceWatchValidationFailure(
            code: validationError,
            message: 'Watch validation failed',
          ),
        ),
      );
    }

    final normalized = watch.copyWith(label: label, url: watch.url.trim());
    try {
      final watches = await _store.readWatches();
      final index = watches.indexWhere((item) => item.id == normalized.id);
      if (index >= 0) {
        watches[index] = normalized;
      } else {
        watches.add(normalized);
        _logger.info('price_monitor.watch_created watchId=${normalized.id}');
      }
      await _store.writeWatches(watches);
      return Success<PriceWatch>(normalized);
    } on Object catch (error, stack) {
      _logger.error('price_monitor.save_failed', error, stack);
      return Err<PriceWatch>(_asFailure(const PriceWatchSaveFailure()));
    }
  }

  @override
  Future<Result<void>> deleteWatch(String watchId) async {
    try {
      final watches = await _store.readWatches()
        ..removeWhere((watch) => watch.id == watchId);
      await _store.writeWatches(watches);
      await _store.removeSamples(watchId);
      _logger.info('price_monitor.watch_deleted watchId=$watchId');
      return const Success<void>(null);
    } on Object catch (error, stack) {
      _logger.error('price_monitor.delete_failed', error, stack);
      return Err<void>(_asFailure(const PriceWatchDeleteFailure()));
    }
  }

  @override
  Future<Result<void>> setWatchEnabled(String watchId, bool enabled) async {
    try {
      final watches = await _store.readWatches();
      final index = watches.indexWhere((watch) => watch.id == watchId);
      if (index < 0) {
        return Err<void>(_asFailure(const PriceWatchSaveFailure()));
      }
      watches[index] = watches[index].copyWith(enabled: enabled);
      await _store.writeWatches(watches);
      _logger.info(
        'price_monitor.watch_enabled watchId=$watchId enabled=$enabled',
      );
      return const Success<void>(null);
    } on Object catch (error, stack) {
      _logger.error('price_monitor.save_failed', error, stack);
      return Err<void>(_asFailure(const PriceWatchSaveFailure()));
    }
  }

  @override
  Future<Map<String, PriceSample>> readLatestSamples() {
    return _store.readLatestSamples();
  }

  @override
  Future<PriceSample?> readLastSuccessfulSample(String watchId) {
    return _store.readLastSuccessfulSample(watchId);
  }

  @override
  Future<void> resetCrossBaseline(String watchId) {
    return _store.clearLastSuccessfulSample(watchId);
  }

  @override
  Future<void> writeSample(PriceSample sample) async {
    await _store.writeLatestSample(sample);
    if (sample.isSuccess) {
      await _store.writeLastSuccessfulSample(sample);
    }
  }

  @override
  Future<int> readPollIntervalMinutes() {
    return _store.readPollMinutes();
  }

  Failure _asFailure(PriceMonitorFailure failure) {
    return IoFailure(failure.code);
  }
}
