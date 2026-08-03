import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class StockList extends StatelessWidget {
  const StockList({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    this.emptyMessage = 'No matching items',
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onDelete;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => spacing.gapXs,
      itemBuilder: (context, index) {
        final item = items[index];
        return Semantics(
          label: l10n.inventoryItemSemantics(
            item.name,
            item.barcode,
            item.quantityOnHand,
          ),
          child: Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                item.description.isEmpty
                    ? '${item.barcode} · SKU ${item.sku}'
                    : '${item.barcode} · SKU ${item.sku}\n${item.description}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(label: Text(l10n.inventoryQuantityChip(item.quantityOnHand))),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(item);
                      } else if (value == 'delete') {
                        onDelete(item);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.inventoryEditItem),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.inventoryDeleteItem),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
