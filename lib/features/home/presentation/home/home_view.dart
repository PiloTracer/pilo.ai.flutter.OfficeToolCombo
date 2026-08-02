import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/home/presentation/home/widgets/tool_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _tools =
      <
        ({
          String title,
          String subtitle,
          String route,
          IconData icon,
          bool available,
        })
      >[
        (
          title: 'Report consolidator',
          subtitle: 'Merge a folder of Excel files into one clean workbook',
          route: '/tools/report-consolidator',
          icon: Icons.table_chart_outlined,
          available: true,
        ),
        (
          title: 'Barcode inventory',
          subtitle: 'Scan products with a USB wedge reader and track stock',
          route: '/tools/barcode-inventory',
          icon: Icons.qr_code_scanner_outlined,
          available: true,
        ),
        (
          title: 'Document factory',
          subtitle: 'Turn Excel rows into personalized PDFs',
          route: '/tools/document-factory',
          icon: Icons.picture_as_pdf_outlined,
          available: true,
        ),
        (
          title: 'Price monitor',
          subtitle: 'Watch prices in the background and get notified',
          route: '/tools/price-monitor',
          icon: Icons.notifications_active_outlined,
          available: true,
        ),
        (
          title: 'Scheduled backup',
          subtitle: 'Zip a folder on a schedule with a dated archive name',
          route: '/tools/scheduled-backup',
          icon: Icons.backup_outlined,
          available: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;

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
                      Text(
                        'OfficeToolCombo',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      spacing.gapSm,
                      Text(
                        'Five desk tools for everyday office work — '
                        'no terminal, no IT ticket.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      spacing.gapLg,
                      Text(
                        'Choose a tool',
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
                  itemCount: _tools.length,
                  separatorBuilder: (_, _) => spacing.gapMd,
                  itemBuilder: (context, index) {
                    final tool = _tools[index];
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
