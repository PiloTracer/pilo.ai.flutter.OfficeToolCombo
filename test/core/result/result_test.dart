import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';

void main() {
  test('Success.when returns data branch', () {
    const Result<int> result = Success(7);
    final value = result.when(success: (data) => data, failure: (_) => -1);
    expect(value, 7);
  });

  test('Err.when returns failure branch', () {
    const Result<int> result = Err(UnexpectedFailure('boom'));
    final value = result.when(success: (_) => -1, failure: (f) => f.message);
    expect(value, 'boom');
  });
}
