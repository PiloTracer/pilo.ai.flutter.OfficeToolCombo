import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/inventory_item.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
part 'inventory_ui_state.freezed.dart';

enum InventoryPhase { loading, empty, partial, error, offline, success }

@freezed
abstract class InventoryUiState with _$InventoryUiState {
  const factory InventoryUiState({
    @Default(InventoryPhase.loading) InventoryPhase phase,
    @Default(<InventoryItem>[]) List<InventoryItem> items,
    @Default(<ScanEvent>[]) List<ScanEvent> recentScans,
    @Default('') String searchQuery,
    @Default(ScanMode.receive) ScanMode scanMode,
    String? errorMessage,
    String? toastMessage,
    String? pendingUnknownBarcode,
    String? pendingCountBarcode,
    @Default(0) int skippedRowCount,
    @Default(false) bool showOfflineBadge,
    @Default(false) bool isDecodingImages,
    String? lastExportPath,
  }) = _InventoryUiState;
}

extension InventoryUiStateX on InventoryUiState {
  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantityOnHand);

  int get distinctSkuCount => items.length;
}
