import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/failures/consolidator_failure.dart';

Failure mapConsolidatorFailure(ConsolidatorFailure failure) {
  return IoFailure(failure.message);
}
