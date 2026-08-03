import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/document_factory/domain/entities/document_job.dart';
import 'package:office_tool_combo/features/document_factory/presentation/document_factory/document_factory_l10n.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Enumerated per-row failure list (SPEC §6 partial state).
class RowFailureList extends StatelessWidget {
  const RowFailureList({super.key, required this.failures});

  final List<RowFailure> failures;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final failure in failures) ...[
          Text(
            l10n.documentFactoryFailureRow(
              failure.rowNumber,
              l10n.documentFactoryFailureMessage(failure.code),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (failure != failures.last) spacing.gapXs,
        ],
      ],
    );
  }
}
