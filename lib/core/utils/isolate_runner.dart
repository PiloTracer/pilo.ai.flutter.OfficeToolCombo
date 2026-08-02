import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs CPU-heavy work off the UI isolate.
class IsolateRunner {
  const IsolateRunner();

  Future<R> run<M, R>(M message, FutureOr<R> Function(M message) callback) {
    return compute(callback, message);
  }
}
