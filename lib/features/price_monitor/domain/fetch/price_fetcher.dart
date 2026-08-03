import 'package:decimal/decimal.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';

/// Outcome of a single price fetch — a parsed price or a failure code.
sealed class PriceFetchOutcome {
  const PriceFetchOutcome();
}

final class PriceFetchSuccess extends PriceFetchOutcome {
  const PriceFetchSuccess(this.price);

  final Decimal price;
}

/// Fetch failure carrying a stable [PriceMonitorFailureCodes] value.
final class PriceFetchFailed extends PriceFetchOutcome {
  const PriceFetchFailed({required this.code, required this.message});

  final String code;
  final String message;
}

/// Fetches a watch URL and extracts a single price (SPEC §2).
abstract class PriceFetchService {
  Future<PriceFetchOutcome> fetch(PriceWatch watch);
}
