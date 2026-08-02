import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';

class FailureList extends StatelessWidget {
  const FailureList({super.key, required this.failures});

  final List<SpreadsheetFileResult> failures;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: failures.length,
      separatorBuilder: (_, _) => Divider(height: spacing.md),
      itemBuilder: (context, index) {
        final failure = failures[index];
        return Semantics(
          label: 'Failed file ${failure.fileName}',
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_outlined,
              color: AppStatusTone.warningForegroundOf(context),
              semanticLabel: 'Warning',
            ),
            title: Text(
              failure.fileName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              failure.errorMessage ?? 'Could not read this workbook',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}
