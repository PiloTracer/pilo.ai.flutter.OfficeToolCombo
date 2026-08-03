import 'package:dio/dio.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/failures/price_monitor_failure.dart';
import 'package:office_tool_combo/features/price_monitor/domain/fetch/price_fetcher.dart';
import 'package:office_tool_combo/features/price_monitor/domain/services/price_parser.dart';

export 'package:office_tool_combo/features/price_monitor/domain/fetch/price_fetcher.dart';

/// dio-backed fetch with timeout; the response body goes through
/// [PriceParser] (JSON first, then HTML/text fallback).
class DioPriceFetchService implements PriceFetchService {
  DioPriceFetchService({
    Dio? dio,
    this.parser = const PriceParser(),
    this.timeout = const Duration(seconds: 10),
    AppLogger? logger,
  }) : _dio = dio ?? Dio(),
       _logger = logger ?? AppLogger();

  final Dio _dio;
  final PriceParser parser;
  final Duration timeout;
  final AppLogger _logger;

  @override
  Future<PriceFetchOutcome> fetch(PriceWatch watch) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get<Object>(
        watch.url,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          // 4xx/5xx still surface a body we refuse to parse — treat as
          // failure with the status class logged (NFR8: never the full URL).
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      final body = response.data?.toString() ?? '';
      final price = parser.parse(body);
      if (price == null) {
        _logger.info(
          'price_monitor.parse_failed watchId=${watch.id} '
          'latencyMs=${stopwatch.elapsedMilliseconds}',
        );
        return const PriceFetchFailed(
          code: PriceMonitorFailureCodes.parse,
          message: 'No price could be read from the page',
        );
      }
      return PriceFetchSuccess(price);
    } on DioException catch (error) {
      final statusClass = error.response?.statusCode == null
          ? 'network'
          : '${error.response!.statusCode! ~/ 100}xx';
      _logger.info(
        'price_monitor.fetch_failed watchId=${watch.id} '
        'statusClass=$statusClass latencyMs=${stopwatch.elapsedMilliseconds}',
      );
      return const PriceFetchFailed(
        code: PriceMonitorFailureCodes.fetch,
        message: 'The price could not be fetched',
      );
    }
  }
}
