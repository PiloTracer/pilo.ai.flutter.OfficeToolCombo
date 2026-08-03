import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Direction in which a threshold cross triggers an alert (SPEC §2).
enum PriceWatchDirection {
  above,
  below;

  static PriceWatchDirection fromName(String name) {
    return PriceWatchDirection.values.firstWhere(
      (direction) => direction.name == name,
      orElse: () => PriceWatchDirection.above,
    );
  }
}

/// A single price watch (SPEC §7). Immutable; JSON-serializable for the
/// SharedPreferences-backed store.
class PriceWatch extends Equatable {
  const PriceWatch({
    required this.id,
    required this.label,
    required this.url,
    required this.threshold,
    required this.direction,
    required this.enabled,
  });

  static const maxLabelLength = 120;

  final String id;
  final String label;

  /// http(s) address fetched by the poll scheduler.
  final String url;

  /// Compared as [Decimal], never floating point (SPEC §2).
  final Decimal threshold;
  final PriceWatchDirection direction;
  final bool enabled;

  PriceWatch copyWith({
    String? id,
    String? label,
    String? url,
    Decimal? threshold,
    PriceWatchDirection? direction,
    bool? enabled,
  }) {
    return PriceWatch(
      id: id ?? this.id,
      label: label ?? this.label,
      url: url ?? this.url,
      threshold: threshold ?? this.threshold,
      direction: direction ?? this.direction,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'url': url,
      'threshold': threshold.toString(),
      'direction': direction.name,
      'enabled': enabled,
    };
  }

  static PriceWatch fromJson(Map<String, dynamic> json) {
    return PriceWatch(
      id: json['id'] as String,
      label: json['label'] as String,
      url: json['url'] as String,
      threshold: Decimal.parse(json['threshold'] as String),
      direction: PriceWatchDirection.fromName(json['direction'] as String),
      enabled: json['enabled'] as bool,
    );
  }

  @override
  List<Object?> get props => [id, label, url, threshold, direction, enabled];
}
