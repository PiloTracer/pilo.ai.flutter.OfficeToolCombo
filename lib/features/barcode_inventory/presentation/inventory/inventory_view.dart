import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_l10n.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/inventory_dialogs.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/recent_scans_list.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/scanner_field.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/stock_list.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

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
          content: Text(
            _batchSummary(
              AppLocalizations.of(context),
              outcome,
              scansHandled: scansHandled,
            ),
          ),
        ),
      );
      _scheduleToastClear();
    } finally {
      if (mounted) {
        setState(() => _scannerCaptureFocus = true);
      }
    }
  }

  String _batchSummary(
    AppLocalizations l10n,
    MultiImageDecodeOutcome outcome, {
    required int scansHandled,
  }) {
    final parts = <String>[];
    if (scansHandled > 0) {
      parts.add(l10n.inventoryBatchScansProcessed(scansHandled));
    }
    if (outcome.failureCount > 0) {
      parts.add(l10n.inventoryBatchImagesNoCode(outcome.failureCount));
    }
    if (parts.isEmpty) {
      return l10n.inventoryBatchNoBarcodes;
    }
    return parts.join(' · ');
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
    final confirmed = await _showInventoryDialog<bool>((context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.inventoryDeleteTitle),
        content: Text(l10n.inventoryDeleteMessage(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.inventoryCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.inventoryDelete),
          ),
        ],
      );
    });
    if (!mounted || confirmed != true) {
      return;
    }
    await ref.read(inventoryViewModelProvider.notifier).deleteItem(item.id);
    _scheduleToastClear();
  }

  /// Importing a CSV replaces the whole inventory, so confirm first.
  Future<void> _confirmAndImportCsv() async {
    final confirmed = await _showInventoryDialog<bool>(
      (context) => const ImportConfirmationDialog(),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    await ref.read(inventoryViewModelProvider.notifier).importCsv();
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

    final l10n = AppLocalizations.of(context);
    final state = ref.watch(inventoryViewModelProvider);
    final viewModel = ref.read(inventoryViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final isInteractive =
        state.phase != InventoryPhase.loading &&
        state.phase != InventoryPhase.error &&
        !state.isDecodingImages;

    return ToolShellScaffold(
      title: l10n.inventoryTitle,
      actions: [
        PopupMenuButton<String>(
          tooltip: l10n.inventoryMoreActionsTooltip,
          onSelected: (value) async {
            switch (value) {
              case 'import':
                await _confirmAndImportCsv();
              case 'export':
                await viewModel.exportCsv();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'import',
              child: Text(l10n.inventoryImportCsv),
            ),
            PopupMenuItem(
              value: 'export',
              child: Text(l10n.inventoryExportCsv),
            ),
          ],
        ),
      ],
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.inventoryTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              spacing.gapSm,
              Text(
                l10n.inventoryIntro,
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
                        label: Text(mode.localizedLabel(l10n)),
                        tooltip: mode.localizedDescription(l10n),
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
                label: l10n.inventoryScanFieldSemantics,
                labelText: l10n.inventoryScanFieldLabel,
                hintText: l10n.inventoryScanFieldHint,
              ),
              spacing.gapSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isInteractive ? _showManualEntry : null,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: Text(l10n.inventoryManualEntry),
                  ),
                  OutlinedButton.icon(
                    onPressed: isInteractive ? _scanFromImages : null,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(l10n.inventoryScanFromImages),
                  ),
                ],
              ),
              spacing.gapMd,
              Semantics(
                label: l10n.inventorySearchStockLabel,
                child: TextField(
                  controller: _searchController,
                  enabled: isInteractive,
                  decoration: InputDecoration(
                    labelText: l10n.inventorySearchStockLabel,
                    hintText: l10n.inventorySearchStockHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: viewModel.isSearchActive
                        ? IconButton(
                            tooltip: l10n.inventoryClearSearchTooltip,
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
                  l10n.inventorySearchMatchCount(viewModel.filteredItemCount),
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
                  onDismissSkipped: viewModel.dismissSkippedRows,
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
                      padding: spacing.screenPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          spacing.gapSm,
                          Text(
                            l10n.inventoryDecodingImagesTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          spacing.gapXs,
                          Text(
                            l10n.inventoryDecodingImagesSubtitle,
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
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.inventory_2_outlined, size: 18),
          label: Text(l10n.inventoryItemsChip(state.distinctSkuCount)),
        ),
        Chip(
          avatar: const Icon(Icons.numbers_outlined, size: 18),
          label: Text(l10n.inventoryUnitsChip(state.totalUnits)),
        ),
        if (state.showOfflineBadge)
          Chip(
            avatar: const Icon(Icons.cloud_off_outlined, size: 18),
            label: Text(l10n.inventoryOfflineBadge),
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
    required this.onDismissSkipped,
  });

  final InventoryUiState state;
  final List<InventoryItem> filteredItems;
  final VoidCallback onRetry;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onDelete;
  final VoidCallback onDismissSkipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return switch (state.phase) {
      InventoryPhase.loading => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            spacing.gapMd,
            Text(l10n.inventoryLoading),
          ],
        ),
      ),
      InventoryPhase.error => StatePanel(
        icon: Icons.error_outline,
        title: l10n.inventoryLoadErrorTitle,
        message: state.errorMessage ?? l10n.inventoryGenericError,
        action: FilledButton(
          onPressed: onRetry,
          child: Text(l10n.inventoryRetry),
        ),
      ),
      InventoryPhase.empty ||
      InventoryPhase.partial ||
      InventoryPhase.offline ||
      InventoryPhase.success => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.phase == InventoryPhase.empty && state.searchQuery.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.md),
              child: StatePanel(
                icon: Icons.qr_code_2_outlined,
                title: l10n.inventoryEmptyTitle,
                message: l10n.inventoryEmptyMessage,
              ),
            ),
          if (state.phase == InventoryPhase.partial)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: MaterialBanner(
                content: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.inventoryImportSkippedBanner(state.skippedRowCount),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: onDismissSkipped,
                    child: Text(l10n.inventoryDismiss),
                  ),
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
                  ? l10n.inventoryEmptyTitle
                  : l10n.inventoryNoMatchingItems,
            ),
          ),
          spacing.gapMd,
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
