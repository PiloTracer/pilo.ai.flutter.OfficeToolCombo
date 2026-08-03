import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/price_monitor/data/repositories/price_monitor_repository_impl.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/os_notification_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/price_fetch_service.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/data/sources/shared_preferences_price_monitor_store.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';

final priceMonitorStoreProvider = Provider<PriceMonitorStore>((ref) {
  return SharedPreferencesPriceMonitorStore();
});

final priceMonitorRepositoryProvider = Provider<PriceMonitorRepository>((ref) {
  return PriceMonitorRepositoryImpl(store: ref.read(priceMonitorStoreProvider));
});

final priceFetchServiceProvider = Provider<PriceFetchService>((ref) {
  return DioPriceFetchService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return NetworkConnectivityService();
});

final osNotificationServiceProvider = Provider<OsNotificationService>((ref) {
  return DesktopOsNotificationService();
});
