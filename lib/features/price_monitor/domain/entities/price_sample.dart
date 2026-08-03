import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Whether the latest fetch attempt produced a price (SPEC §7).
enum PriceSampleStatus {
  success,
  failed;

  static PriceSampleStatus fromName(String name) {
    return PriceSampleStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => PriceSampleStatus.failed,
    );
  }
}

/// Latest fetch outcome for a watch. Only the latest sample per watch is
/// kept for display (SPEC §2 — history is out of scope for v1).
class PriceSample extends Equatable {
  const PriceSample({
    required this.watchId,
    required this.price,
    required this.fetchedAt,
    required this.status,
  });

  final String watchId;

  /// Parsed price; null when [status] is [PriceSampleStatus.failed].
  final Decimal? price;
  final DateTime fetchedAt;
  final PriceSampleStatus status;

  bool get isSuccess => status == PriceSampleStatus.success;

  PriceSample copyWith({
    String? watchId,
    Decimal? price,
    DateTime? fetchedAt,
    PriceSampleStatus? status,
  }) {
    return PriceSample(
      watchId: watchId ?? this.watchId,
      price: price ?? this.price,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'watchId': watchId,
      'price': price?.toString(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'status': status.name,
    };
  }

  static PriceSample fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] as String?;
    return PriceSample(
      watchId: json['watchId'] as String,
      price: rawPrice == null ? null : Decimal.parse(rawPrice),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String).toUtc(),
      status: PriceSampleStatus.fromName(json['status'] as String),
    );
  }

  @override
  List<Object?> get props => [watchId, price, fetchedAt, status];
}
