import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class RecentScansList extends StatelessWidget {
  const RecentScansList({
    super.key,
    required this.events,
    required this.itemNamesById,
  });

  final List<ScanEvent> events;
  final Map<String, String> itemNamesById;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final spacing = context.spacing;
    return Card(
      child: Padding(
        padding: spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).inventoryRecentScans,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            spacing.gapSm,
            ...events.take(8).map((event) {
              final name = event.itemId == null
                  ? event.barcode
                  : itemNamesById[event.itemId!] ?? event.barcode;
              final deltaLabel = event.delta >= 0
                  ? '+${event.delta}'
                  : '${event.delta}';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle: Text(event.barcode),
                trailing: Text(deltaLabel),
              );
            }),
          ],
        ),
      ),
    );
  }
}
