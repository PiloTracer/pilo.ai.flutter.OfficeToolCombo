import 'package:equatable/equatable.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';

enum PriceMonitorStatus { loading, ready, error }

/// In-app banner fallback alert (R10) — shown when the OS notification
/// could not be delivered, with the same title/body (SPEC §4.3).
class PriceBannerAlert extends Equatable {
  const PriceBannerAlert({
    required this.title,
    required this.body,
    this.showSystemSettingsHint = false,
  });

  final String title;
  final String body;

  /// macOS-only: OS notifications are likely denied — point the user to
  /// System Settings (SPEC §11).
  final bool showSystemSettingsHint;

  @override
  List<Object?> get props => [title, body, showSystemSettingsHint];
}

/// UI state for the price monitor screen.
class PriceMonitorUiState {
  const PriceMonitorUiState({
    this.status = PriceMonitorStatus.loading,
    this.watches = const <PriceWatch>[],
    this.samples = const <String, PriceSample>{},
    this.isOffline = false,
    this.banner,
    this.errorCode,
  });

  final PriceMonitorStatus status;
  final List<PriceWatch> watches;

  /// Latest sample per watch id (success or failed), for row display.
  final Map<String, PriceSample> samples;

  /// Global offline flag from the connectivity probe (SPEC §6).
  final bool isOffline;
  final PriceBannerAlert? banner;

  /// Stable PriceMonitorFailureCodes value for the current error state.
  final String? errorCode;

  PriceMonitorUiState copyWith({
    PriceMonitorStatus? status,
    List<PriceWatch>? watches,
    Map<String, PriceSample>? samples,
    bool? isOffline,
    PriceBannerAlert? banner,
    String? errorCode,
    bool clearBanner = false,
    bool clearError = false,
  }) {
    return PriceMonitorUiState(
      status: status ?? this.status,
      watches: watches ?? this.watches,
      samples: samples ?? this.samples,
      isOffline: isOffline ?? this.isOffline,
      banner: clearBanner ? null : (banner ?? this.banner),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}
