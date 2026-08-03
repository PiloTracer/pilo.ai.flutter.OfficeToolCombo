import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// F0 placeholder for a tool route. Product behaviour arrives in F1–F5.
class ToolPlaceholderView extends StatelessWidget {
  const ToolPlaceholderView({
    super.key,
    required this.title,
    required this.toolId,
    this.icon = Icons.construction_outlined,
  });

  final String title;
  final String toolId;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return ToolShellScaffold(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          spacing.gapLg,
          Expanded(
            child: StatePanel(
              icon: icon,
              title: l10n.placeholderHeadline,
              message: l10n.placeholderMessage(title, toolId),
            ),
          ),
        ],
      ),
    );
  }
}
