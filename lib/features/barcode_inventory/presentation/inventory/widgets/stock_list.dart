import 'package:flutter/material.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';

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
          label:
              '${item.name}, barcode ${item.barcode}, quantity ${item.quantityOnHand}',
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
                  Chip(label: Text('Qty: ${item.quantityOnHand}')),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(item);
                      } else if (value == 'delete') {
                        onDelete(item);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit item')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete item'),
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
