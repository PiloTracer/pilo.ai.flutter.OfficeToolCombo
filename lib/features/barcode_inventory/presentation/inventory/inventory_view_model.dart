import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/csv_import_summary.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/inventory_search_matcher.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_l10n.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_providers.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class InventoryViewModel extends Notifier<InventoryUiState> {
  InventoryRepository get _repository => ref.read(inventoryRepositoryProvider);

  AppLocalizations get _l10n => ref.read(inventoryLocalizationsProvider);

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
              errorMessage: _l10n.inventoryFailureMessage(failure.message),
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
          errorMessage: _l10n.inventoryFailureMessage(failure.message),
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

  void dismissSkippedRows() {
    if (state.skippedRowCount == 0) {
      return;
    }
    state = state.copyWith(
      skippedRowCount: 0,
      phase: _phaseForItems(state.items, 0),
    );
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
          toast: _l10n.inventoryToastAdded(item.name),
          clearPending: true,
        );
        return const ScanSubmissionResult.handled();
      },
      failure: (failure) {
        final message = _l10n.inventoryFailureMessage(failure.message);
        state = state.copyWith(errorMessage: message);
        return ScanSubmissionResult.failed(message);
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
          toast: _l10n.inventoryToastUpdated(item.name, item.quantityOnHand),
          clearPending: true,
        );
        return const ScanSubmissionResult.handled();
      },
      failure: (failure) {
        final message = _l10n.inventoryFailureMessage(failure.message);
        state = state.copyWith(
          errorMessage: message,
          pendingCountBarcode: null,
        );
        return ScanSubmissionResult.failed(message);
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

    final pickResult = await _repository.pickBarcodeImagePaths(
      dialogTitle: _l10n.inventoryScanFromImages,
    );
    if (!ref.mounted) {
      return null;
    }

    final paths = pickResult.when(
      success: (value) => value,
      failure: (failure) {
        state = state.copyWith(
          toastMessage: _l10n.inventoryFailureMessage(failure.message),
        );
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
          state = state.copyWith(
            toastMessage: _l10n.inventoryFailureMessage(failure.message),
          );
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
        await _refreshAfterMutation(
          toast: _l10n.inventoryToastUpdated(item.name, item.quantityOnHand),
        );
      },
      failure: (failure) {
        state = state.copyWith(
          errorMessage: _l10n.inventoryFailureMessage(failure.message),
        );
      },
    );
  }

  Future<void> deleteItem(String id) async {
    final result = await _repository.deleteItem(id);
    await result.when(
      success: (_) async {
        await _refreshAfterMutation(toast: _l10n.inventoryToastDeleted);
      },
      failure: (failure) {
        state = state.copyWith(
          errorMessage: _l10n.inventoryFailureMessage(failure.message),
        );
      },
    );
  }

  Future<void> exportCsv() async {
    final result = await _repository.exportInventoryCsv(
      dialogTitle: _l10n.inventoryExportCsv,
    );
    result.when(
      success: (path) {
        if (path == null) {
          return;
        }
        state = state.copyWith(
          toastMessage: _l10n.inventoryToastExported(path),
          lastExportPath: path,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          errorMessage: _l10n.inventoryFailureMessage(failure.message),
        );
      },
    );
  }

  Future<void> importCsv() async {
    final l10n = _l10n;
    try {
      final pick = await FilePicker.pickFiles(
        dialogTitle: l10n.inventoryImportCsv,
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
      await importCsvFile(path);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: l10n.inventoryErrorImport('$error'));
    }
  }

  /// Imports [path] after the file was picked. Split from [importCsv] so the
  /// flow past the platform file picker stays testable.
  Future<void> importCsvFile(String path) async {
    final l10n = _l10n;
    final result = await _repository.importInventoryCsv(path);
    await result.when(
      success: (summary) async {
        state = state.copyWith(
          skippedRowCount: summary.skippedCount + summary.duplicateCount,
        );
        await _refreshAfterMutation(toast: _importToast(l10n, summary));
      },
      failure: (failure) {
        state = state.copyWith(
          errorMessage: l10n.inventoryFailureMessage(failure.message),
        );
      },
    );
  }

  String _importToast(AppLocalizations l10n, CsvImportSummary summary) {
    final parts = <String>[l10n.inventoryToastImported(summary.importedCount)];
    if (summary.skippedCount > 0) {
      parts.add(l10n.inventoryImportSkippedPart(summary.skippedCount));
    }
    if (summary.duplicateCount > 0) {
      parts.add(l10n.inventoryImportDuplicatesPart(summary.duplicateCount));
    }
    return parts.join(' · ');
  }

  Future<ScanSubmissionResult> _applyScan(String barcode) async {
    final result = await _repository.processScan(
      barcode: barcode,
      mode: state.scanMode,
    );

    return result.when(
      success: (item) async {
        final l10n = _l10n;
        final verb = switch (state.scanMode) {
          ScanMode.receive => l10n.inventoryVerbReceived,
          ScanMode.ship => l10n.inventoryVerbShipped,
          ScanMode.count => l10n.inventoryVerbUpdated,
        };
        await _refreshAfterMutation(
          toast: l10n.inventoryToastScan(verb, item.name, item.quantityOnHand),
          clearPending: true,
        );
        return const ScanSubmissionResult.handled();
      },
      failure: (failure) {
        final message = _l10n.inventoryFailureMessage(failure.message);
        if (failure.message == InventoryFailureCodes.insufficientStock) {
          state = state.copyWith(toastMessage: message);
        } else {
          state = state.copyWith(errorMessage: message);
        }
        return ScanSubmissionResult.failed(message);
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
        state = state.copyWith(
          errorMessage: _l10n.inventoryFailureMessage(failure.message),
        );
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
