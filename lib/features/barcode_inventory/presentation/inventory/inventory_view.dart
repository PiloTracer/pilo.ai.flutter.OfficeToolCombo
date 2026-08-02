import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/inventory_dialogs.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/recent_scans_list.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/scanner_field.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/stock_list.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';

class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends ConsumerState<InventoryView> {
  final _scanController = TextEditingController();
  final _scanFocusNode = FocusNode();
  final _searchController = TextEditingController();
  Timer? _toastTimer;
  String? _lastHandledPendingBarcode;
  String? _lastHandledCountBarcode;
  bool _scannerCaptureFocus = true;

  @override
  void dispose() {
    _toastTimer?.cancel();
    _scanController.dispose();
    _scanFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(inventoryViewModelProvider.notifier).loadInventory());
    });
  }

  Future<T?> _showInventoryDialog<T>(
    Widget Function(BuildContext) builder,
  ) async {
    setState(() => _scannerCaptureFocus = false);
    _scanFocusNode.unfocus();
    try {
      return await showDialog<T>(context: context, builder: builder);
    } finally {
      if (mounted) {
        setState(() => _scannerCaptureFocus = true);
      }
    }
  }

  Future<void> _scanFromImages() async {
    setState(() => _scannerCaptureFocus = false);
    _scanFocusNode.unfocus();
    final viewModel = ref.read(inventoryViewModelProvider.notifier);
    try {
      final outcome = await viewModel.pickAndDecodeImages();
      if (!mounted || outcome == null) {
        return;
      }

      var scansHandled = 0;
      for (final barcode in outcome.decodedBarcodes) {
        final result = await viewModel.submitScan(barcode);
        if (!mounted) {
          return;
        }
        await _handleScanResult(result);
        result.when(
          cleared: () {},
          handled: () => scansHandled++,
          needsCreate: () => scansHandled++,
          needsCount: (_) => scansHandled++,
          failed: (_) {},
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.batchSummary(scansHandled: scansHandled)),
        ),
      );
      _scheduleToastClear();
    } finally {
      if (mounted) {
        setState(() => _scannerCaptureFocus = true);
      }
    }
  }

  Future<void> _handleScanSubmitted(String value) async {
    final viewModel = ref.read(inventoryViewModelProvider.notifier);
    final result = await viewModel.submitScan(value);
    if (!mounted) {
      return;
    }
    await _handleScanResult(result);
  }

  Future<void> _handleScanResult(ScanSubmissionResult result) async {
    final viewModel = ref.read(inventoryViewModelProvider.notifier);
    final state = ref.read(inventoryViewModelProvider);

    await result.when(
      cleared: () async {},
      handled: () async {
        _scheduleToastClear();
      },
      needsCreate: () async {
        final barcode = state.pendingUnknownBarcode;
        if (barcode == null || barcode == _lastHandledPendingBarcode) {
          return;
        }
        _lastHandledPendingBarcode = barcode;
        final created = await _showInventoryDialog<CreateItemResult>(
          (context) => CreateItemDialog(barcode: barcode),
        );
        _lastHandledPendingBarcode = null;
        if (!mounted) {
          return;
        }
        if (created == null) {
          viewModel.cancelPendingDialog();
          return;
        }
        await viewModel.confirmCreateItem(
          barcode: barcode,
          name: created.name,
          description: created.description,
          startingQuantity: created.quantity,
        );
        _scheduleToastClear();
      },
      needsCount: (currentQty) async {
        final barcode =
            state.pendingCountBarcode ?? state.pendingUnknownBarcode;
        if (barcode == null || barcode == _lastHandledCountBarcode) {
          return;
        }
        _lastHandledCountBarcode = barcode;
        final qty = await _showInventoryDialog<int>(
          (context) => CountQuantityDialog(
            barcode: barcode,
            currentQuantity: currentQty,
          ),
        );
        _lastHandledCountBarcode = null;
        if (!mounted) {
          return;
        }
        if (qty == null) {
          viewModel.cancelPendingDialog();
          return;
        }
        await viewModel.confirmCountQuantity(barcode: barcode, quantity: qty);
        _scheduleToastClear();
      },
      failed: (_) async {
        _scheduleToastClear();
      },
    );
  }

  void _scheduleToastClear() {
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(inventoryViewModelProvider.notifier).clearToast();
      }
    });
  }

  Future<void> _showManualEntry() async {
    final barcode = await _showInventoryDialog<String>(
      (context) => const ManualEntryDialog(),
    );
    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }
    await _handleScanSubmitted(barcode.trim());
  }

  Future<void> _editItem(InventoryItem item) async {
    final edited =
        await _showInventoryDialog<
          ({String name, String description, int quantity})
        >(
          (context) => EditItemDialog(
            name: item.name,
            description: item.description,
            quantity: item.quantityOnHand,
          ),
        );
    if (!mounted || edited == null) {
      return;
    }
    await ref
        .read(inventoryViewModelProvider.notifier)
        .updateItem(
          id: item.id,
          name: edited.name,
          description: edited.description,
          quantityOnHand: edited.quantity,
        );
    _scheduleToastClear();
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final confirmed = await _showInventoryDialog<bool>(
      (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    await ref.read(inventoryViewModelProvider.notifier).deleteItem(item.id);
    _scheduleToastClear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(inventoryViewModelProvider, (previous, next) {
      if (next.toastMessage != null &&
          next.toastMessage != previous?.toastMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.toastMessage!)));
      }
    });

    final state = ref.watch(inventoryViewModelProvider);
    final viewModel = ref.read(inventoryViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final isInteractive =
        state.phase != InventoryPhase.loading &&
        state.phase != InventoryPhase.error &&
        !state.isDecodingImages;

    return ToolShellScaffold(
      title: 'Barcode inventory',
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'import':
                await viewModel.importCsv();
              case 'export':
                await viewModel.exportCsv();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'import', child: Text('Import CSV')),
            PopupMenuItem(value: 'export', child: Text('Export CSV')),
          ],
        ),
      ],
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Barcode inventory',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              spacing.gapSm,
              Text(
                'Scan products with a USB or Bluetooth wedge reader, upload one or '
                'more barcode images, or enter identifiers manually. Supports QR '
                'codes, linear barcodes, and alphanumeric SKUs.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              spacing.gapMd,
              _SummaryRow(state: state),
              spacing.gapMd,
              SegmentedButton<ScanMode>(
                segments: ScanMode.values
                    .map(
                      (mode) => ButtonSegment(
                        value: mode,
                        label: Text(mode.label),
                        tooltip: mode.description,
                      ),
                    )
                    .toList(growable: false),
                selected: {state.scanMode},
                onSelectionChanged: isInteractive
                    ? (selection) => viewModel.setScanMode(selection.first)
                    : null,
              ),
              spacing.gapMd,
              ScannerField(
                controller: _scanController,
                focusNode: _scanFocusNode,
                enabled: isInteractive && _scannerCaptureFocus,
                captureFocus: _scannerCaptureFocus,
                onSubmitted: _handleScanSubmitted,
              ),
              spacing.gapSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isInteractive ? _showManualEntry : null,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Manual entry'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isInteractive ? _scanFromImages : null,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Scan from images'),
                  ),
                ],
              ),
              spacing.gapMd,
              Semantics(
                label: 'Search stock',
                child: TextField(
                  controller: _searchController,
                  enabled: isInteractive,
                  decoration: InputDecoration(
                    labelText: 'Search stock',
                    hintText: 'Name, barcode, notes — typos & accents OK',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: viewModel.isSearchActive
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: isInteractive
                                ? () {
                                    _searchController.clear();
                                    viewModel.setSearchQuery('');
                                  }
                                : null,
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: viewModel.setSearchQuery,
                ),
              ),
              if (viewModel.isSearchActive) ...[
                spacing.gapXs,
                Text(
                  viewModel.filteredItemCount == 1
                      ? '1 match'
                      : '${viewModel.filteredItemCount} matches',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              spacing.gapMd,
              Expanded(
                child: _InventoryBody(
                  state: state,
                  filteredItems: viewModel.filteredItems,
                  onRetry: viewModel.retryLoad,
                  onEdit: _editItem,
                  onDelete: _deleteItem,
                ),
              ),
            ],
          ),
          if (state.isDecodingImages)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.scrim.withValues(alpha: 0.35),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          spacing.gapSm,
                          Text(
                            'Reading barcodes from images…',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          spacing.gapXs,
                          Text(
                            'You can still move the window while this runs.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.state});

  final InventoryUiState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.inventory_2_outlined, size: 18),
          label: Text('${state.distinctSkuCount} items'),
        ),
        Chip(
          avatar: const Icon(Icons.numbers_outlined, size: 18),
          label: Text('${state.totalUnits} units on hand'),
        ),
        if (state.showOfflineBadge)
          const Chip(
            avatar: Icon(Icons.cloud_off_outlined, size: 18),
            label: Text('Working offline'),
          ),
      ],
    );
  }
}

class _InventoryBody extends StatelessWidget {
  const _InventoryBody({
    required this.state,
    required this.filteredItems,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryUiState state;
  final List<InventoryItem> filteredItems;
  final VoidCallback onRetry;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      InventoryPhase.loading => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading inventory…'),
          ],
        ),
      ),
      InventoryPhase.error => StatePanel(
        icon: Icons.error_outline,
        title: 'Could not load inventory',
        message: state.errorMessage ?? 'Something went wrong',
        action: FilledButton(
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ),
      InventoryPhase.empty ||
      InventoryPhase.partial ||
      InventoryPhase.offline ||
      InventoryPhase.success => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.phase == InventoryPhase.empty && state.searchQuery.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: StatePanel(
                icon: Icons.qr_code_2_outlined,
                title: 'No items yet',
                message: 'Scan a barcode to add your first item.',
              ),
            ),
          if (state.phase == InventoryPhase.partial)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MaterialBanner(
                content: Text(
                  'Some items could not be loaded (${state.skippedRowCount})',
                ),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Dismiss')),
                ],
              ),
            ),
          Expanded(
            flex: 3,
            child: StockList(
              items: filteredItems,
              onEdit: onEdit,
              onDelete: onDelete,
              emptyMessage: state.searchQuery.isEmpty
                  ? 'No items yet'
                  : 'No matching items',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 2,
            child: RecentScansList(
              events: state.recentScans,
              itemNamesById: {
                for (final item in state.items) item.id: item.name,
              },
            ),
          ),
        ],
      ),
    };
  }
}
