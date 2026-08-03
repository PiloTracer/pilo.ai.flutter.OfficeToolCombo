import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Field-mapping editor: one row per discovered placeholder, each with a
/// dropdown of data-sheet column headers (SPEC §5 region 4).
class FieldMappingEditor extends StatelessWidget {
  const FieldMappingEditor({
    super.key,
    required this.placeholders,
    required this.headers,
    required this.mapping,
    required this.onChanged,
  });

  final List<String> placeholders;
  final List<String> headers;
  final Map<String, String> mapping;
  final void Function(String placeholder, String column) onChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final placeholder in placeholders) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  placeholder,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              spacing.gapMd,
              Semantics(
                label: l10n.documentFactoryColumnFor(placeholder),
                child: DropdownButton<String>(
                  hint: Text(l10n.documentFactorySelectColumn),
                  value: headers.contains(mapping[placeholder])
                      ? mapping[placeholder]
                      : null,
                  items: headers
                      .map(
                        (header) => DropdownMenuItem<String>(
                          value: header,
                          child: Text(header),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (column) {
                    if (column != null) {
                      onChanged(placeholder, column);
                    }
                  },
                ),
              ),
            ],
          ),
          if (placeholder != placeholders.last) spacing.gapSm,
        ],
      ],
    );
  }
}
