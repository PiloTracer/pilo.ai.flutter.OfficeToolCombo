import 'dart:async';
import 'dart:io';

import 'package:office_tool_combo/features/price_monitor/domain/connectivity/connectivity.dart';

export 'package:office_tool_combo/features/price_monitor/domain/connectivity/connectivity.dart';

/// Default probe: DNS lookup with a short timeout. Never throws.
class NetworkConnectivityService implements ConnectivityService {
  NetworkConnectivityService({
    this.host = 'example.com',
    this.timeout = const Duration(seconds: 3),
  });

  final String host;
  final Duration timeout;

  @override
  Future<bool> isOnline() async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      return addresses.any((address) => address.address.isNotEmpty);
    } on Object {
      return false;
    }
  }
}
