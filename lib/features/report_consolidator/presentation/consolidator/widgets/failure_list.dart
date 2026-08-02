import 'package:flutter/material.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';

class FailureList extends StatelessWidget {
  const FailureList({super.key, required this.failures});

  final List<SpreadsheetFileResult> failures;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: failures.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final failure = failures[index];
        return Semantics(
          label: 'Failed file ${failure.fileName}',
          child: ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(failure.fileName),
            subtitle: Text(failure.errorMessage ?? 'Could not read workbook'),
          ),
        );
      },
    );
  }
}
