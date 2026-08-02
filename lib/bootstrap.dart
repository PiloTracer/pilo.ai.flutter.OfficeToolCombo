import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/app.dart';
import 'package:office_tool_combo/core/logging/app_logger.dart';

/// Process entry used by all flavors. Wires zone + error handlers, then runApp.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = AppLogger();

  FlutterError.onError = (details) {
    logger.error('FlutterError', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('PlatformDispatcher', error, stack);
    return true;
  };

  runZonedGuarded(() {
    runApp(ProviderScope(child: OfficeToolComboApp(logger: logger)));
  }, (error, stack) => logger.error('Zone', error, stack));
}
