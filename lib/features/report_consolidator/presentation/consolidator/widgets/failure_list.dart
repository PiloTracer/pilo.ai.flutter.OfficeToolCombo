import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class FailureList extends StatelessWidget {
  const FailureList({super.key, required this.failures});

  final List<SpreadsheetFileResult> failures;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: failures.length,
      separatorBuilder: (_, _) => Divider(height: spacing.md),
      itemBuilder: (context, index) {
        final failure = failures[index];
        return Semantics(
          label: l10n.consolidatorFailedFileSemantics(failure.fileName),
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_outlined,
              color: AppStatusTone.warningForegroundOf(context),
              semanticLabel: l10n.warningSemanticLabel,
            ),
            title: Text(
              failure.fileName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              failure.errorMessage ?? l10n.consolidatorFailureFallback,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}
