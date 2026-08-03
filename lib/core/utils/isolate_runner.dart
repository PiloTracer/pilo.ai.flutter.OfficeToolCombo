import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Runs CPU-heavy work off the UI isolate.
class IsolateRunner {
  const IsolateRunner();

  Future<R> run<M, R>(M message, FutureOr<R> Function(M message) callback) {
    return compute(callback, message);
  }

  /// Like [run], but the worker can stream progress values back to the
  /// caller while it runs.
  ///
  /// [callback] must be a top-level or static function so it can cross the
  /// isolate boundary; both [M] and [P] must be sendable through a
  /// [SendPort] (primitives, strings, and collections of those).
  Future<R> runWithProgress<M, R, P>(
    M message,
    FutureOr<R> Function(M message, void Function(P progress) emit) callback, {
    void Function(P progress)? onProgress,
  }) async {
    final port = ReceivePort();
    Isolate? isolate;
    try {
      isolate = await Isolate.spawn(
        _isolateEntry<M, R, P>,
        _IsolateArgs<M, R, P>(
          sendPort: port.sendPort,
          message: message,
          callback: callback,
        ),
      );

      await for (final event in port) {
        switch (event) {
          case _IsolateProgress<P>(:final value):
            onProgress?.call(value);
          case _IsolateResult<R>(:final value):
            return value;
          case _IsolateError(:final message):
            throw StateError('Isolate failed: $message');
        }
      }
      throw StateError('Isolate exited without producing a result');
    } finally {
      isolate?.kill();
      port.close();
    }
  }

  static Future<void> _isolateEntry<M, R, P>(
    _IsolateArgs<M, R, P> args,
  ) async {
    try {
      final result = await args.callback(
        args.message,
        (progress) => args.sendPort.send(_IsolateProgress<P>(progress)),
      );
      args.sendPort.send(_IsolateResult<R>(result));
    } on Object catch (error) {
      args.sendPort.send(_IsolateError(error.toString()));
    }
  }
}

class _IsolateArgs<M, R, P> {
  const _IsolateArgs({
    required this.sendPort,
    required this.message,
    required this.callback,
  });

  final SendPort sendPort;
  final M message;
  final FutureOr<R> Function(M message, void Function(P progress) emit)
  callback;
}

class _IsolateProgress<P> {
  const _IsolateProgress(this.value);

  final P value;
}

class _IsolateResult<R> {
  const _IsolateResult(this.value);

  final R value;
}

class _IsolateError {
  const _IsolateError(this.message);

  final String message;
}
