import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/report_consolidator/data/repositories/consolidator_repository_impl.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/repositories/consolidator_repository.dart';

final consolidatorRepositoryProvider = Provider<ConsolidatorRepository>((ref) {
  return ConsolidatorRepositoryImpl();
});
