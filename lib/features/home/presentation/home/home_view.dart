import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/home/presentation/home/widgets/tool_card.dart';
import 'package:office_tool_combo/features/settings/presentation/language_menu_button.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static List<
    ({String title, String subtitle, String route, IconData icon, bool available})
  > _tools(AppLocalizations l10n) => [
    (
      title: l10n.toolReportConsolidatorTitle,
      subtitle: l10n.toolReportConsolidatorSubtitle,
      route: '/tools/report-consolidator',
      icon: Icons.table_chart_outlined,
      available: true,
    ),
    (
      title: l10n.toolBarcodeInventoryTitle,
      subtitle: l10n.toolBarcodeInventorySubtitle,
      route: '/tools/barcode-inventory',
      icon: Icons.qr_code_scanner_outlined,
      available: true,
    ),
    (
      title: l10n.toolDocumentFactoryTitle,
      subtitle: l10n.toolDocumentFactorySubtitle,
      route: '/tools/document-factory',
      icon: Icons.picture_as_pdf_outlined,
      available: true,
    ),
    (
      title: l10n.toolPriceMonitorTitle,
      subtitle: l10n.toolPriceMonitorSubtitle,
      route: '/tools/price-monitor',
      icon: Icons.notifications_active_outlined,
      available: true,
    ),
    (
      title: l10n.toolScheduledBackupTitle,
      subtitle: l10n.toolScheduledBackupSubtitle,
      route: '/tools/scheduled-backup',
      icon: Icons.backup_outlined,
      available: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final tools = _tools(l10n);

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: spacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      spacing.gapSm,
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.appTitle,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                          const LanguageMenuButton(),
                        ],
                      ),
                      spacing.gapSm,
                      Text(
                        l10n.homeTagline,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      spacing.gapLg,
                      Text(
                        l10n.homeChooseTool,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      spacing.gapMd,
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  spacing.lg,
                  0,
                  spacing.lg,
                  spacing.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: tools.length,
                  separatorBuilder: (_, _) => spacing.gapMd,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return ToolCard(
                      title: tool.title,
                      subtitle: tool.subtitle,
                      route: tool.route,
                      icon: tool.icon,
                      available: tool.available,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
