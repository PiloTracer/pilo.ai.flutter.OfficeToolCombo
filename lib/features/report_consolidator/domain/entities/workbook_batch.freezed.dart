// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workbook_batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkbookBatch {

 String get id; String get sourceFolderPath; String? get outputPath; WorkbookBatchStatus get status; DateTime get startedAt; DateTime? get finishedAt; List<SpreadsheetFileResult> get files;
/// Create a copy of WorkbookBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkbookBatchCopyWith<WorkbookBatch> get copyWith => _$WorkbookBatchCopyWithImpl<WorkbookBatch>(this as WorkbookBatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkbookBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceFolderPath, sourceFolderPath) || other.sourceFolderPath == sourceFolderPath)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&const DeepCollectionEquality().equals(other.files, files));
}


@override
int get hashCode => Object.hash(runtimeType,id,sourceFolderPath,outputPath,status,startedAt,finishedAt,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'WorkbookBatch(id: $id, sourceFolderPath: $sourceFolderPath, outputPath: $outputPath, status: $status, startedAt: $startedAt, finishedAt: $finishedAt, files: $files)';
}


}

/// @nodoc
abstract mixin class $WorkbookBatchCopyWith<$Res>  {
  factory $WorkbookBatchCopyWith(WorkbookBatch value, $Res Function(WorkbookBatch) _then) = _$WorkbookBatchCopyWithImpl;
@useResult
$Res call({
 String id, String sourceFolderPath, String? outputPath, WorkbookBatchStatus status, DateTime startedAt, DateTime? finishedAt, List<SpreadsheetFileResult> files
});




}
/// @nodoc
class _$WorkbookBatchCopyWithImpl<$Res>
    implements $WorkbookBatchCopyWith<$Res> {
  _$WorkbookBatchCopyWithImpl(this._self, this._then);

  final WorkbookBatch _self;
  final $Res Function(WorkbookBatch) _then;

/// Create a copy of WorkbookBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceFolderPath = null,Object? outputPath = freezed,Object? status = null,Object? startedAt = null,Object? finishedAt = freezed,Object? files = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceFolderPath: null == sourceFolderPath ? _self.sourceFolderPath : sourceFolderPath // ignore: cast_nullable_to_non_nullable
as String,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkbookBatchStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<SpreadsheetFileResult>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkbookBatch].
extension WorkbookBatchPatterns on WorkbookBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkbookBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkbookBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkbookBatch value)  $default,){
final _that = this;
switch (_that) {
case _WorkbookBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkbookBatch value)?  $default,){
final _that = this;
switch (_that) {
case _WorkbookBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourceFolderPath,  String? outputPath,  WorkbookBatchStatus status,  DateTime startedAt,  DateTime? finishedAt,  List<SpreadsheetFileResult> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkbookBatch() when $default != null:
return $default(_that.id,_that.sourceFolderPath,_that.outputPath,_that.status,_that.startedAt,_that.finishedAt,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourceFolderPath,  String? outputPath,  WorkbookBatchStatus status,  DateTime startedAt,  DateTime? finishedAt,  List<SpreadsheetFileResult> files)  $default,) {final _that = this;
switch (_that) {
case _WorkbookBatch():
return $default(_that.id,_that.sourceFolderPath,_that.outputPath,_that.status,_that.startedAt,_that.finishedAt,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourceFolderPath,  String? outputPath,  WorkbookBatchStatus status,  DateTime startedAt,  DateTime? finishedAt,  List<SpreadsheetFileResult> files)?  $default,) {final _that = this;
switch (_that) {
case _WorkbookBatch() when $default != null:
return $default(_that.id,_that.sourceFolderPath,_that.outputPath,_that.status,_that.startedAt,_that.finishedAt,_that.files);case _:
  return null;

}
}

}

/// @nodoc


class _WorkbookBatch implements WorkbookBatch {
  const _WorkbookBatch({required this.id, required this.sourceFolderPath, this.outputPath, required this.status, required this.startedAt, this.finishedAt, final  List<SpreadsheetFileResult> files = const <SpreadsheetFileResult>[]}): _files = files;
  

@override final  String id;
@override final  String sourceFolderPath;
@override final  String? outputPath;
@override final  WorkbookBatchStatus status;
@override final  DateTime startedAt;
@override final  DateTime? finishedAt;
 final  List<SpreadsheetFileResult> _files;
@override@JsonKey() List<SpreadsheetFileResult> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of WorkbookBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkbookBatchCopyWith<_WorkbookBatch> get copyWith => __$WorkbookBatchCopyWithImpl<_WorkbookBatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkbookBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceFolderPath, sourceFolderPath) || other.sourceFolderPath == sourceFolderPath)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,id,sourceFolderPath,outputPath,status,startedAt,finishedAt,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'WorkbookBatch(id: $id, sourceFolderPath: $sourceFolderPath, outputPath: $outputPath, status: $status, startedAt: $startedAt, finishedAt: $finishedAt, files: $files)';
}


}

/// @nodoc
abstract mixin class _$WorkbookBatchCopyWith<$Res> implements $WorkbookBatchCopyWith<$Res> {
  factory _$WorkbookBatchCopyWith(_WorkbookBatch value, $Res Function(_WorkbookBatch) _then) = __$WorkbookBatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourceFolderPath, String? outputPath, WorkbookBatchStatus status, DateTime startedAt, DateTime? finishedAt, List<SpreadsheetFileResult> files
});




}
/// @nodoc
class __$WorkbookBatchCopyWithImpl<$Res>
    implements _$WorkbookBatchCopyWith<$Res> {
  __$WorkbookBatchCopyWithImpl(this._self, this._then);

  final _WorkbookBatch _self;
  final $Res Function(_WorkbookBatch) _then;

/// Create a copy of WorkbookBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceFolderPath = null,Object? outputPath = freezed,Object? status = null,Object? startedAt = null,Object? finishedAt = freezed,Object? files = null,}) {
  return _then(_WorkbookBatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceFolderPath: null == sourceFolderPath ? _self.sourceFolderPath : sourceFolderPath // ignore: cast_nullable_to_non_nullable
as String,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkbookBatchStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<SpreadsheetFileResult>,
  ));
}


}

// dart format on
