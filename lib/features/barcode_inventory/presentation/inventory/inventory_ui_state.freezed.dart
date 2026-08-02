// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InventoryUiState {

 InventoryPhase get phase; List<InventoryItem> get items; List<ScanEvent> get recentScans; String get searchQuery; ScanMode get scanMode; String? get errorMessage; String? get toastMessage; String? get pendingUnknownBarcode; String? get pendingCountBarcode; int get skippedRowCount; bool get showOfflineBadge; bool get isDecodingImages; String? get lastExportPath;
/// Create a copy of InventoryUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryUiStateCopyWith<InventoryUiState> get copyWith => _$InventoryUiStateCopyWithImpl<InventoryUiState>(this as InventoryUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryUiState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.recentScans, recentScans)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.scanMode, scanMode) || other.scanMode == scanMode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.toastMessage, toastMessage) || other.toastMessage == toastMessage)&&(identical(other.pendingUnknownBarcode, pendingUnknownBarcode) || other.pendingUnknownBarcode == pendingUnknownBarcode)&&(identical(other.pendingCountBarcode, pendingCountBarcode) || other.pendingCountBarcode == pendingCountBarcode)&&(identical(other.skippedRowCount, skippedRowCount) || other.skippedRowCount == skippedRowCount)&&(identical(other.showOfflineBadge, showOfflineBadge) || other.showOfflineBadge == showOfflineBadge)&&(identical(other.isDecodingImages, isDecodingImages) || other.isDecodingImages == isDecodingImages)&&(identical(other.lastExportPath, lastExportPath) || other.lastExportPath == lastExportPath));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(recentScans),searchQuery,scanMode,errorMessage,toastMessage,pendingUnknownBarcode,pendingCountBarcode,skippedRowCount,showOfflineBadge,isDecodingImages,lastExportPath);

@override
String toString() {
  return 'InventoryUiState(phase: $phase, items: $items, recentScans: $recentScans, searchQuery: $searchQuery, scanMode: $scanMode, errorMessage: $errorMessage, toastMessage: $toastMessage, pendingUnknownBarcode: $pendingUnknownBarcode, pendingCountBarcode: $pendingCountBarcode, skippedRowCount: $skippedRowCount, showOfflineBadge: $showOfflineBadge, isDecodingImages: $isDecodingImages, lastExportPath: $lastExportPath)';
}


}

/// @nodoc
abstract mixin class $InventoryUiStateCopyWith<$Res>  {
  factory $InventoryUiStateCopyWith(InventoryUiState value, $Res Function(InventoryUiState) _then) = _$InventoryUiStateCopyWithImpl;
@useResult
$Res call({
 InventoryPhase phase, List<InventoryItem> items, List<ScanEvent> recentScans, String searchQuery, ScanMode scanMode, String? errorMessage, String? toastMessage, String? pendingUnknownBarcode, String? pendingCountBarcode, int skippedRowCount, bool showOfflineBadge, bool isDecodingImages, String? lastExportPath
});




}
/// @nodoc
class _$InventoryUiStateCopyWithImpl<$Res>
    implements $InventoryUiStateCopyWith<$Res> {
  _$InventoryUiStateCopyWithImpl(this._self, this._then);

  final InventoryUiState _self;
  final $Res Function(InventoryUiState) _then;

/// Create a copy of InventoryUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? items = null,Object? recentScans = null,Object? searchQuery = null,Object? scanMode = null,Object? errorMessage = freezed,Object? toastMessage = freezed,Object? pendingUnknownBarcode = freezed,Object? pendingCountBarcode = freezed,Object? skippedRowCount = null,Object? showOfflineBadge = null,Object? isDecodingImages = null,Object? lastExportPath = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as InventoryPhase,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<InventoryItem>,recentScans: null == recentScans ? _self.recentScans : recentScans // ignore: cast_nullable_to_non_nullable
as List<ScanEvent>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,scanMode: null == scanMode ? _self.scanMode : scanMode // ignore: cast_nullable_to_non_nullable
as ScanMode,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,toastMessage: freezed == toastMessage ? _self.toastMessage : toastMessage // ignore: cast_nullable_to_non_nullable
as String?,pendingUnknownBarcode: freezed == pendingUnknownBarcode ? _self.pendingUnknownBarcode : pendingUnknownBarcode // ignore: cast_nullable_to_non_nullable
as String?,pendingCountBarcode: freezed == pendingCountBarcode ? _self.pendingCountBarcode : pendingCountBarcode // ignore: cast_nullable_to_non_nullable
as String?,skippedRowCount: null == skippedRowCount ? _self.skippedRowCount : skippedRowCount // ignore: cast_nullable_to_non_nullable
as int,showOfflineBadge: null == showOfflineBadge ? _self.showOfflineBadge : showOfflineBadge // ignore: cast_nullable_to_non_nullable
as bool,isDecodingImages: null == isDecodingImages ? _self.isDecodingImages : isDecodingImages // ignore: cast_nullable_to_non_nullable
as bool,lastExportPath: freezed == lastExportPath ? _self.lastExportPath : lastExportPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryUiState].
extension InventoryUiStatePatterns on InventoryUiState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryUiState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryUiState value)  $default,){
final _that = this;
switch (_that) {
case _InventoryUiState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryUiState value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryUiState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InventoryPhase phase,  List<InventoryItem> items,  List<ScanEvent> recentScans,  String searchQuery,  ScanMode scanMode,  String? errorMessage,  String? toastMessage,  String? pendingUnknownBarcode,  String? pendingCountBarcode,  int skippedRowCount,  bool showOfflineBadge,  bool isDecodingImages,  String? lastExportPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryUiState() when $default != null:
return $default(_that.phase,_that.items,_that.recentScans,_that.searchQuery,_that.scanMode,_that.errorMessage,_that.toastMessage,_that.pendingUnknownBarcode,_that.pendingCountBarcode,_that.skippedRowCount,_that.showOfflineBadge,_that.isDecodingImages,_that.lastExportPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InventoryPhase phase,  List<InventoryItem> items,  List<ScanEvent> recentScans,  String searchQuery,  ScanMode scanMode,  String? errorMessage,  String? toastMessage,  String? pendingUnknownBarcode,  String? pendingCountBarcode,  int skippedRowCount,  bool showOfflineBadge,  bool isDecodingImages,  String? lastExportPath)  $default,) {final _that = this;
switch (_that) {
case _InventoryUiState():
return $default(_that.phase,_that.items,_that.recentScans,_that.searchQuery,_that.scanMode,_that.errorMessage,_that.toastMessage,_that.pendingUnknownBarcode,_that.pendingCountBarcode,_that.skippedRowCount,_that.showOfflineBadge,_that.isDecodingImages,_that.lastExportPath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InventoryPhase phase,  List<InventoryItem> items,  List<ScanEvent> recentScans,  String searchQuery,  ScanMode scanMode,  String? errorMessage,  String? toastMessage,  String? pendingUnknownBarcode,  String? pendingCountBarcode,  int skippedRowCount,  bool showOfflineBadge,  bool isDecodingImages,  String? lastExportPath)?  $default,) {final _that = this;
switch (_that) {
case _InventoryUiState() when $default != null:
return $default(_that.phase,_that.items,_that.recentScans,_that.searchQuery,_that.scanMode,_that.errorMessage,_that.toastMessage,_that.pendingUnknownBarcode,_that.pendingCountBarcode,_that.skippedRowCount,_that.showOfflineBadge,_that.isDecodingImages,_that.lastExportPath);case _:
  return null;

}
}

}

/// @nodoc


class _InventoryUiState implements InventoryUiState {
  const _InventoryUiState({this.phase = InventoryPhase.loading, final  List<InventoryItem> items = const <InventoryItem>[], final  List<ScanEvent> recentScans = const <ScanEvent>[], this.searchQuery = '', this.scanMode = ScanMode.receive, this.errorMessage, this.toastMessage, this.pendingUnknownBarcode, this.pendingCountBarcode, this.skippedRowCount = 0, this.showOfflineBadge = false, this.isDecodingImages = false, this.lastExportPath}): _items = items,_recentScans = recentScans;
  

@override@JsonKey() final  InventoryPhase phase;
 final  List<InventoryItem> _items;
@override@JsonKey() List<InventoryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<ScanEvent> _recentScans;
@override@JsonKey() List<ScanEvent> get recentScans {
  if (_recentScans is EqualUnmodifiableListView) return _recentScans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentScans);
}

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  ScanMode scanMode;
@override final  String? errorMessage;
@override final  String? toastMessage;
@override final  String? pendingUnknownBarcode;
@override final  String? pendingCountBarcode;
@override@JsonKey() final  int skippedRowCount;
@override@JsonKey() final  bool showOfflineBadge;
@override@JsonKey() final  bool isDecodingImages;
@override final  String? lastExportPath;

/// Create a copy of InventoryUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryUiStateCopyWith<_InventoryUiState> get copyWith => __$InventoryUiStateCopyWithImpl<_InventoryUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryUiState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._recentScans, _recentScans)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.scanMode, scanMode) || other.scanMode == scanMode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.toastMessage, toastMessage) || other.toastMessage == toastMessage)&&(identical(other.pendingUnknownBarcode, pendingUnknownBarcode) || other.pendingUnknownBarcode == pendingUnknownBarcode)&&(identical(other.pendingCountBarcode, pendingCountBarcode) || other.pendingCountBarcode == pendingCountBarcode)&&(identical(other.skippedRowCount, skippedRowCount) || other.skippedRowCount == skippedRowCount)&&(identical(other.showOfflineBadge, showOfflineBadge) || other.showOfflineBadge == showOfflineBadge)&&(identical(other.isDecodingImages, isDecodingImages) || other.isDecodingImages == isDecodingImages)&&(identical(other.lastExportPath, lastExportPath) || other.lastExportPath == lastExportPath));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_recentScans),searchQuery,scanMode,errorMessage,toastMessage,pendingUnknownBarcode,pendingCountBarcode,skippedRowCount,showOfflineBadge,isDecodingImages,lastExportPath);

@override
String toString() {
  return 'InventoryUiState(phase: $phase, items: $items, recentScans: $recentScans, searchQuery: $searchQuery, scanMode: $scanMode, errorMessage: $errorMessage, toastMessage: $toastMessage, pendingUnknownBarcode: $pendingUnknownBarcode, pendingCountBarcode: $pendingCountBarcode, skippedRowCount: $skippedRowCount, showOfflineBadge: $showOfflineBadge, isDecodingImages: $isDecodingImages, lastExportPath: $lastExportPath)';
}


}

/// @nodoc
abstract mixin class _$InventoryUiStateCopyWith<$Res> implements $InventoryUiStateCopyWith<$Res> {
  factory _$InventoryUiStateCopyWith(_InventoryUiState value, $Res Function(_InventoryUiState) _then) = __$InventoryUiStateCopyWithImpl;
@override @useResult
$Res call({
 InventoryPhase phase, List<InventoryItem> items, List<ScanEvent> recentScans, String searchQuery, ScanMode scanMode, String? errorMessage, String? toastMessage, String? pendingUnknownBarcode, String? pendingCountBarcode, int skippedRowCount, bool showOfflineBadge, bool isDecodingImages, String? lastExportPath
});




}
/// @nodoc
class __$InventoryUiStateCopyWithImpl<$Res>
    implements _$InventoryUiStateCopyWith<$Res> {
  __$InventoryUiStateCopyWithImpl(this._self, this._then);

  final _InventoryUiState _self;
  final $Res Function(_InventoryUiState) _then;

/// Create a copy of InventoryUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? items = null,Object? recentScans = null,Object? searchQuery = null,Object? scanMode = null,Object? errorMessage = freezed,Object? toastMessage = freezed,Object? pendingUnknownBarcode = freezed,Object? pendingCountBarcode = freezed,Object? skippedRowCount = null,Object? showOfflineBadge = null,Object? isDecodingImages = null,Object? lastExportPath = freezed,}) {
  return _then(_InventoryUiState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as InventoryPhase,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<InventoryItem>,recentScans: null == recentScans ? _self._recentScans : recentScans // ignore: cast_nullable_to_non_nullable
as List<ScanEvent>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,scanMode: null == scanMode ? _self.scanMode : scanMode // ignore: cast_nullable_to_non_nullable
as ScanMode,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,toastMessage: freezed == toastMessage ? _self.toastMessage : toastMessage // ignore: cast_nullable_to_non_nullable
as String?,pendingUnknownBarcode: freezed == pendingUnknownBarcode ? _self.pendingUnknownBarcode : pendingUnknownBarcode // ignore: cast_nullable_to_non_nullable
as String?,pendingCountBarcode: freezed == pendingCountBarcode ? _self.pendingCountBarcode : pendingCountBarcode // ignore: cast_nullable_to_non_nullable
as String?,skippedRowCount: null == skippedRowCount ? _self.skippedRowCount : skippedRowCount // ignore: cast_nullable_to_non_nullable
as int,showOfflineBadge: null == showOfflineBadge ? _self.showOfflineBadge : showOfflineBadge // ignore: cast_nullable_to_non_nullable
as bool,isDecodingImages: null == isDecodingImages ? _self.isDecodingImages : isDecodingImages // ignore: cast_nullable_to_non_nullable
as bool,lastExportPath: freezed == lastExportPath ? _self.lastExportPath : lastExportPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
