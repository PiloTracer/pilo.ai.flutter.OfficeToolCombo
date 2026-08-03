import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.available = true,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: available
          ? l10n.toolRowSemantics(title, subtitle)
          : l10n.toolComingSoonSemantics(title),
      enabled: available,
      child: Material(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radii.mdAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: available ? () => context.go(route) : null,
          child: Padding(
            padding: spacing.cardPadding,
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: radii.smAll,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.sm + spacing.xs),
                    child: Icon(
                      icon,
                      color: scheme.onSurfaceVariant,
                      semanticLabel: '',
                    ),
                  ),
                ),
                spacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (!available) _ComingSoonBadge(spacing: spacing),
                        ],
                      ),
                      spacing.gapXs,
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                spacing.gapSm,
                Icon(
                  available ? Icons.chevron_right : Icons.schedule,
                  color: scheme.onSurfaceVariant,
                  semanticLabel: '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.spacing});

  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(spacing.sm),
      ),
      child: Text(
        AppLocalizations.of(context).comingSoonBadge,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
