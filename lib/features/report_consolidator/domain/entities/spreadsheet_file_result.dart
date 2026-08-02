import 'package:freezed_annotation/freezed_annotation.dart';

part 'spreadsheet_file_result.freezed.dart';

enum SpreadsheetParseStatus { pending, success, failed }

@freezed
abstract class SpreadsheetFileResult with _$SpreadsheetFileResult {
  const factory SpreadsheetFileResult({
    required String fileName,
    required SpreadsheetParseStatus parseStatus,
    String? errorMessage,
  }) = _SpreadsheetFileResult;
}
