// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spreadsheet_file_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpreadsheetFileResult {

 String get fileName; SpreadsheetParseStatus get parseStatus; String? get errorMessage;
/// Create a copy of SpreadsheetFileResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadsheetFileResultCopyWith<SpreadsheetFileResult> get copyWith => _$SpreadsheetFileResultCopyWithImpl<SpreadsheetFileResult>(this as SpreadsheetFileResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadsheetFileResult&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.parseStatus, parseStatus) || other.parseStatus == parseStatus)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,fileName,parseStatus,errorMessage);

@override
String toString() {
  return 'SpreadsheetFileResult(fileName: $fileName, parseStatus: $parseStatus, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SpreadsheetFileResultCopyWith<$Res>  {
  factory $SpreadsheetFileResultCopyWith(SpreadsheetFileResult value, $Res Function(SpreadsheetFileResult) _then) = _$SpreadsheetFileResultCopyWithImpl;
@useResult
$Res call({
 String fileName, SpreadsheetParseStatus parseStatus, String? errorMessage
});




}
/// @nodoc
class _$SpreadsheetFileResultCopyWithImpl<$Res>
    implements $SpreadsheetFileResultCopyWith<$Res> {
  _$SpreadsheetFileResultCopyWithImpl(this._self, this._then);

  final SpreadsheetFileResult _self;
  final $Res Function(SpreadsheetFileResult) _then;

/// Create a copy of SpreadsheetFileResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? parseStatus = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,parseStatus: null == parseStatus ? _self.parseStatus : parseStatus // ignore: cast_nullable_to_non_nullable
as SpreadsheetParseStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SpreadsheetFileResult].
extension SpreadsheetFileResultPatterns on SpreadsheetFileResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpreadsheetFileResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpreadsheetFileResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpreadsheetFileResult value)  $default,){
final _that = this;
switch (_that) {
case _SpreadsheetFileResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpreadsheetFileResult value)?  $default,){
final _that = this;
switch (_that) {
case _SpreadsheetFileResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  SpreadsheetParseStatus parseStatus,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpreadsheetFileResult() when $default != null:
return $default(_that.fileName,_that.parseStatus,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  SpreadsheetParseStatus parseStatus,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SpreadsheetFileResult():
return $default(_that.fileName,_that.parseStatus,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  SpreadsheetParseStatus parseStatus,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SpreadsheetFileResult() when $default != null:
return $default(_that.fileName,_that.parseStatus,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SpreadsheetFileResult implements SpreadsheetFileResult {
  const _SpreadsheetFileResult({required this.fileName, required this.parseStatus, this.errorMessage});
  

@override final  String fileName;
@override final  SpreadsheetParseStatus parseStatus;
@override final  String? errorMessage;

/// Create a copy of SpreadsheetFileResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpreadsheetFileResultCopyWith<_SpreadsheetFileResult> get copyWith => __$SpreadsheetFileResultCopyWithImpl<_SpreadsheetFileResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpreadsheetFileResult&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.parseStatus, parseStatus) || other.parseStatus == parseStatus)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,fileName,parseStatus,errorMessage);

@override
String toString() {
  return 'SpreadsheetFileResult(fileName: $fileName, parseStatus: $parseStatus, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SpreadsheetFileResultCopyWith<$Res> implements $SpreadsheetFileResultCopyWith<$Res> {
  factory _$SpreadsheetFileResultCopyWith(_SpreadsheetFileResult value, $Res Function(_SpreadsheetFileResult) _then) = __$SpreadsheetFileResultCopyWithImpl;
@override @useResult
$Res call({
 String fileName, SpreadsheetParseStatus parseStatus, String? errorMessage
});




}
/// @nodoc
class __$SpreadsheetFileResultCopyWithImpl<$Res>
    implements _$SpreadsheetFileResultCopyWith<$Res> {
  __$SpreadsheetFileResultCopyWithImpl(this._self, this._then);

  final _SpreadsheetFileResult _self;
  final $Res Function(_SpreadsheetFileResult) _then;

/// Create a copy of SpreadsheetFileResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? parseStatus = null,Object? errorMessage = freezed,}) {
  return _then(_SpreadsheetFileResult(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,parseStatus: null == parseStatus ? _self.parseStatus : parseStatus // ignore: cast_nullable_to_non_nullable
as SpreadsheetParseStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
