import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.iconBackgroundColor,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? scheme.surfaceContainer,
                borderRadius: radii.lgAll,
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.md),
                child: Icon(
                  icon,
                  size: spacing.xl + spacing.sm,
                  color: iconColor ?? scheme.onSurfaceVariant,
                  semanticLabel: '',
                ),
              ),
            ),
            spacing.gapMd,
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            spacing.gapSm,
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[spacing.gapLg, action!],
          ],
        ),
      ),
    );
  }
}
