// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanEvent {

 int get id; String get barcode; String? get itemId; DateTime get scannedAt; int get delta;
/// Create a copy of ScanEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanEventCopyWith<ScanEvent> get copyWith => _$ScanEventCopyWithImpl<ScanEvent>(this as ScanEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt)&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,id,barcode,itemId,scannedAt,delta);

@override
String toString() {
  return 'ScanEvent(id: $id, barcode: $barcode, itemId: $itemId, scannedAt: $scannedAt, delta: $delta)';
}


}

/// @nodoc
abstract mixin class $ScanEventCopyWith<$Res>  {
  factory $ScanEventCopyWith(ScanEvent value, $Res Function(ScanEvent) _then) = _$ScanEventCopyWithImpl;
@useResult
$Res call({
 int id, String barcode, String? itemId, DateTime scannedAt, int delta
});




}
/// @nodoc
class _$ScanEventCopyWithImpl<$Res>
    implements $ScanEventCopyWith<$Res> {
  _$ScanEventCopyWithImpl(this._self, this._then);

  final ScanEvent _self;
  final $Res Function(ScanEvent) _then;

/// Create a copy of ScanEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? barcode = null,Object? itemId = freezed,Object? scannedAt = null,Object? delta = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,scannedAt: null == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as DateTime,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanEvent].
extension ScanEventPatterns on ScanEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanEvent value)  $default,){
final _that = this;
switch (_that) {
case _ScanEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ScanEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String barcode,  String? itemId,  DateTime scannedAt,  int delta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanEvent() when $default != null:
return $default(_that.id,_that.barcode,_that.itemId,_that.scannedAt,_that.delta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String barcode,  String? itemId,  DateTime scannedAt,  int delta)  $default,) {final _that = this;
switch (_that) {
case _ScanEvent():
return $default(_that.id,_that.barcode,_that.itemId,_that.scannedAt,_that.delta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String barcode,  String? itemId,  DateTime scannedAt,  int delta)?  $default,) {final _that = this;
switch (_that) {
case _ScanEvent() when $default != null:
return $default(_that.id,_that.barcode,_that.itemId,_that.scannedAt,_that.delta);case _:
  return null;

}
}

}

/// @nodoc


class _ScanEvent implements ScanEvent {
  const _ScanEvent({required this.id, required this.barcode, this.itemId, required this.scannedAt, required this.delta});
  

@override final  int id;
@override final  String barcode;
@override final  String? itemId;
@override final  DateTime scannedAt;
@override final  int delta;

/// Create a copy of ScanEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanEventCopyWith<_ScanEvent> get copyWith => __$ScanEventCopyWithImpl<_ScanEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt)&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,id,barcode,itemId,scannedAt,delta);

@override
String toString() {
  return 'ScanEvent(id: $id, barcode: $barcode, itemId: $itemId, scannedAt: $scannedAt, delta: $delta)';
}


}

/// @nodoc
abstract mixin class _$ScanEventCopyWith<$Res> implements $ScanEventCopyWith<$Res> {
  factory _$ScanEventCopyWith(_ScanEvent value, $Res Function(_ScanEvent) _then) = __$ScanEventCopyWithImpl;
@override @useResult
$Res call({
 int id, String barcode, String? itemId, DateTime scannedAt, int delta
});




}
/// @nodoc
class __$ScanEventCopyWithImpl<$Res>
    implements _$ScanEventCopyWith<$Res> {
  __$ScanEventCopyWithImpl(this._self, this._then);

  final _ScanEvent _self;
  final $Res Function(_ScanEvent) _then;

/// Create a copy of ScanEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? barcode = null,Object? itemId = freezed,Object? scannedAt = null,Object? delta = null,}) {
  return _then(_ScanEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,scannedAt: null == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as DateTime,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
