import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/inventory_search_matcher.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_providers.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';

class InventoryViewModel extends Notifier<InventoryUiState> {
  InventoryRepository get _repository => ref.read(inventoryRepositoryProvider);

  @override
  InventoryUiState build() {
    return const InventoryUiState(phase: InventoryPhase.loading);
  }

  Future<void> loadInventory() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(phase: InventoryPhase.loading, errorMessage: null);

    final itemsResult = await _repository.loadItems();
    if (!ref.mounted) {
      return;
    }
    final scansResult = await _repository.loadRecentScans();
    if (!ref.mounted) {
      return;
    }

    itemsResult.when(
      success: (items) {
        scansResult.when(
          success: (scans) {
            if (!ref.mounted) {
              return;
            }
            state = state.copyWith(
              phase: _phaseForItems(items, state.skippedRowCount),
              items: items,
              recentScans: scans,
              errorMessage: null,
            );
          },
          failure: (failure) {
            if (!ref.mounted) {
              return;
            }
            state = state.copyWith(
              phase: InventoryPhase.error,
              items: items,
              errorMessage: failure.message,
            );
          },
        );
      },
      failure: (failure) {
        if (!ref.mounted) {
          return;
        }
        state = state.copyWith(
          phase: InventoryPhase.error,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> retryLoad() => loadInventory();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  List<InventoryItem> get filteredItems {
    return InventorySearchMatcher.filterAndRank(state.items, state.searchQuery);
  }

  int get filteredItemCount => filteredItems.length;

  bool get isSearchActive => state.searchQuery.trim().isNotEmpty;

  void setScanMode(ScanMode mode) {
    state = state.copyWith(scanMode: mode, toastMessage: null);
  }

  void clearToast() {
    if (state.toastMessage != null) {
      state = state.copyWith(toastMessage: null);
    }
  }

  Future<ScanSubmissionResult> submitScan(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) {
      return const ScanSubmissionResult.cleared();
    }

    if (state.scanMode == ScanMode.count) {
      final existing = state.items
          .where((item) => item.barcode == barcode)
          .firstOrNull;
      if (existing == null) {
        state = state.copyWith(pendingUnknownBarcode: barcode);
        return const ScanSubmissionResult.needsCreate();
      }
      state = state.copyWith(pendingCountBarcode: barcode);
      return ScanSubmissionResult.needsCount(existing.quantityOnHand);
    }

    final known = state.items.any((item) => item.barcode == barcode);
    if (!known) {
      state = state.copyWith(pendingUnknownBarcode: barcode);
      return const ScanSubmissionResult.needsCreate();
    }

    return _applyScan(barcode);
  }

  Future<ScanSubmissionResult> submitManualBarcode(String barcode) async {
    return submitScan(barcode);
  }

  Future<ScanSubmissionResult> confirmCreateItem({
    required String barcode,
    required String name,
    String description = '',
    required int startingQuantity,
  }) async {
    final result = await _repository.createItem(
      barcode: barcode,
      name: name,
      description: description,
      startingQuantity: startingQuantity,
    );

    return result.when(
      success: (item) async {
        await _refreshAfterMutation(
          toast: 'Added ${item.name}',
          clearPending: true,
        );
        return const ScanSubmissionResult.handled();
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return ScanSubmissionResult.failed(failure.message);
      },
    );
  }

  Future<ScanSubmissionResult> confirmCountQuantity({
    required String barcode,
    required int quantity,
  }) async {
    final result = await _repository.processScan(
      barcode: barcode,
      mode: ScanMode.count,
      countQuantity: quantity,
    );

    return result.when(
      success: (item) async {
        await _refreshAfterMutation(
          toast: 'Updated ${item.name}: ${item.quantityOnHand}',
          clearPending: true,
        );
        return const ScanSubmissionResult.handled();
      },
      failure: (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
          pendingCountBarcode: null,
        );
        return ScanSubmissionResult.failed(failure.message);
      },
    );
  }

  void cancelPendingDialog() {
    state = state.copyWith(
      pendingUnknownBarcode: null,
      pendingCountBarcode: null,
    );
  }

  Future<MultiImageDecodeOutcome?> pickAndDecodeImages() async {
    if (!ref.mounted) {
      return null;
    }

    final pickResult = await _repository.pickBarcodeImagePaths();
    if (!ref.mounted) {
      return null;
    }

    final paths = pickResult.when(
      success: (value) => value,
      failure: (failure) {
        state = state.copyWith(toastMessage: failure.message);
        return null;
      },
    );
    if (paths == null || paths.isEmpty) {
      return null;
    }

    state = state.copyWith(isDecodingImages: true);
    try {
      final decodeResult = await _repository.decodeBarcodeImagePaths(paths);
      if (!ref.mounted) {
        return null;
      }
      return decodeResult.when(
        success: (outcome) => outcome.isEmpty ? null : outcome,
        failure: (failure) {
          state = state.copyWith(toastMessage: failure.message);
          return null;
        },
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isDecodingImages: false);
      }
    }
  }

  Future<void> updateItem({
    required String id,
    required String name,
    String description = '',
    required int quantityOnHand,
  }) async {
    final result = await _repository.updateItem(
      id: id,
      name: name,
      description: description,
      quantityOnHand: quantityOnHand,
    );
    await result.when(
      success: (item) async {
        await _refreshAfterMutation(toast: 'Updated ${item.name}');
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  Future<void> deleteItem(String id) async {
    final result = await _repository.deleteItem(id);
    await result.when(
      success: (_) async {
        await _refreshAfterMutation(toast: 'Item deleted');
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  Future<void> exportCsv() async {
    final result = await _repository.exportInventoryCsv();
    result.when(
      success: (path) {
        if (path == null) {
          return;
        }
        state = state.copyWith(
          toastMessage: 'Exported inventory to $path',
          lastExportPath: path,
        );
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  Future<void> importCsv() async {
    try {
      final pick = await FilePicker.pickFiles(
        dialogTitle: 'Import inventory CSV',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (pick == null || pick.files.isEmpty) {
        return;
      }
      final path = pick.files.single.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final result = await _repository.importInventoryCsv(path);
      await result.when(
        success: (count) async {
          await _refreshAfterMutation(toast: 'Imported $count items');
        },
        failure: (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
      );
    } on Object catch (error) {
      state = state.copyWith(errorMessage: 'Could not import CSV: $error');
    }
  }

  Future<ScanSubmissionResult> _applyScan(String barcode) async {
    final result = await _repository.processScan(
      barcode: barcode,
      mode: state.scanMode,
    );

    return result.when(
      success: (item) async {
        final verb = switch (state.scanMode) {
          ScanMode.receive => 'Received',
          ScanMode.ship => 'Shipped',
          ScanMode.count => 'Updated',
        };
        await _refreshAfterMutation(
          toast: '$verb ${item.name}: ${item.quantityOnHand}',
          clearPending: true,
        );
        return const ScanSubmissionResult.handled();
      },
      failure: (failure) {
        if (failure.message ==
            const InventoryInsufficientStockFailure().message) {
          state = state.copyWith(toastMessage: failure.message);
        } else {
          state = state.copyWith(errorMessage: failure.message);
        }
        return ScanSubmissionResult.failed(failure.message);
      },
    );
  }

  Future<void> _refreshAfterMutation({
    required String toast,
    bool clearPending = false,
  }) async {
    final itemsResult = await _repository.loadItems();
    final scansResult = await _repository.loadRecentScans();

    itemsResult.when(
      success: (items) {
        scansResult.when(
          success: (scans) {
            state = state.copyWith(
              phase: _phaseForItems(items, state.skippedRowCount),
              items: items,
              recentScans: scans,
              toastMessage: toast,
              errorMessage: null,
              pendingUnknownBarcode: clearPending
                  ? null
                  : state.pendingUnknownBarcode,
              pendingCountBarcode: clearPending
                  ? null
                  : state.pendingCountBarcode,
            );
          },
          failure: (_) {
            state = state.copyWith(items: items, toastMessage: toast);
          },
        );
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  InventoryPhase _phaseForItems(List<dynamic> items, int skippedRows) {
    if (items.isEmpty && skippedRows == 0) {
      return InventoryPhase.empty;
    }
    if (skippedRows > 0) {
      return InventoryPhase.partial;
    }
    return InventoryPhase.success;
  }
}

sealed class ScanSubmissionResult {
  const ScanSubmissionResult();

  const factory ScanSubmissionResult.cleared() = _ScanCleared;
  const factory ScanSubmissionResult.handled() = _ScanHandled;
  const factory ScanSubmissionResult.needsCreate() = _ScanNeedsCreate;
  const factory ScanSubmissionResult.needsCount(int currentQty) =
      _ScanNeedsCount;
  const factory ScanSubmissionResult.failed(String message) = _ScanFailed;
}

final class _ScanCleared extends ScanSubmissionResult {
  const _ScanCleared();
}

final class _ScanHandled extends ScanSubmissionResult {
  const _ScanHandled();
}

final class _ScanNeedsCreate extends ScanSubmissionResult {
  const _ScanNeedsCreate();
}

final class _ScanNeedsCount extends ScanSubmissionResult {
  const _ScanNeedsCount(this.currentQty);
  final int currentQty;
}

final class _ScanFailed extends ScanSubmissionResult {
  const _ScanFailed(this.message);
  final String message;
}

extension ScanSubmissionResultX on ScanSubmissionResult {
  T when<T>({
    required T Function() cleared,
    required T Function() handled,
    required T Function() needsCreate,
    required T Function(int currentQty) needsCount,
    required T Function(String message) failed,
  }) {
    return switch (this) {
      _ScanCleared() => cleared(),
      _ScanHandled() => handled(),
      _ScanNeedsCreate() => needsCreate(),
      _ScanNeedsCount(:final currentQty) => needsCount(currentQty),
      _ScanFailed(:final message) => failed(message),
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

final inventoryViewModelProvider =
    NotifierProvider<InventoryViewModel, InventoryUiState>(
      InventoryViewModel.new,
    );
