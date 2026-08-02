import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _tools = <({String title, String subtitle, String route})>[
    (
      title: 'Report consolidator',
      subtitle: 'Merge a folder of Excel files into one clean workbook',
      route: '/tools/report-consolidator',
    ),
    (
      title: 'Barcode inventory',
      subtitle: 'Scan products with a USB wedge reader and track stock',
      route: '/tools/barcode-inventory',
    ),
    (
      title: 'Document factory',
      subtitle: 'Turn Excel rows into personalized PDFs',
      route: '/tools/document-factory',
    ),
    (
      title: 'Price monitor',
      subtitle: 'Watch prices in the background and get notified',
      route: '/tools/price-monitor',
    ),
    (
      title: 'Scheduled backup',
      subtitle: 'Zip a folder on a schedule with a dated archive name',
      route: '/tools/scheduled-backup',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OfficeToolCombo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _tools.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return Semantics(
            button: true,
            label: tool.title,
            child: ListTile(
              title: Text(tool.title),
              subtitle: Text(tool.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(tool.route),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          );
        },
      ),
    );
  }
}
