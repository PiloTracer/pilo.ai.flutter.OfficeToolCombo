import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_item.freezed.dart';

@freezed
abstract class InventoryItem with _$InventoryItem {
  const factory InventoryItem({
    required String id,
    required String sku,
    required String barcode,
    required String name,
    @Default('') String description,
    required int quantityOnHand,
    required DateTime updatedAt,
  }) = _InventoryItem;
}
