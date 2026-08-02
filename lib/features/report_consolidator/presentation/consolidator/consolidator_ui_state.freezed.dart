// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consolidator_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConsolidatorUiState {

 ConsolidatorPhase get phase; String? get selectedFolderPath; String? get outputFileName; double get progress; String? get errorMessage; WorkbookBatch? get lastBatch;
/// Create a copy of ConsolidatorUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsolidatorUiStateCopyWith<ConsolidatorUiState> get copyWith => _$ConsolidatorUiStateCopyWithImpl<ConsolidatorUiState>(this as ConsolidatorUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsolidatorUiState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedFolderPath, selectedFolderPath) || other.selectedFolderPath == selectedFolderPath)&&(identical(other.outputFileName, outputFileName) || other.outputFileName == outputFileName)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastBatch, lastBatch) || other.lastBatch == lastBatch));
}


@override
int get hashCode => Object.hash(runtimeType,phase,selectedFolderPath,outputFileName,progress,errorMessage,lastBatch);

@override
String toString() {
  return 'ConsolidatorUiState(phase: $phase, selectedFolderPath: $selectedFolderPath, outputFileName: $outputFileName, progress: $progress, errorMessage: $errorMessage, lastBatch: $lastBatch)';
}


}

/// @nodoc
abstract mixin class $ConsolidatorUiStateCopyWith<$Res>  {
  factory $ConsolidatorUiStateCopyWith(ConsolidatorUiState value, $Res Function(ConsolidatorUiState) _then) = _$ConsolidatorUiStateCopyWithImpl;
@useResult
$Res call({
 ConsolidatorPhase phase, String? selectedFolderPath, String? outputFileName, double progress, String? errorMessage, WorkbookBatch? lastBatch
});


$WorkbookBatchCopyWith<$Res>? get lastBatch;

}
/// @nodoc
class _$ConsolidatorUiStateCopyWithImpl<$Res>
    implements $ConsolidatorUiStateCopyWith<$Res> {
  _$ConsolidatorUiStateCopyWithImpl(this._self, this._then);

  final ConsolidatorUiState _self;
  final $Res Function(ConsolidatorUiState) _then;

/// Create a copy of ConsolidatorUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? selectedFolderPath = freezed,Object? outputFileName = freezed,Object? progress = null,Object? errorMessage = freezed,Object? lastBatch = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ConsolidatorPhase,selectedFolderPath: freezed == selectedFolderPath ? _self.selectedFolderPath : selectedFolderPath // ignore: cast_nullable_to_non_nullable
as String?,outputFileName: freezed == outputFileName ? _self.outputFileName : outputFileName // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,lastBatch: freezed == lastBatch ? _self.lastBatch : lastBatch // ignore: cast_nullable_to_non_nullable
as WorkbookBatch?,
  ));
}
/// Create a copy of ConsolidatorUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkbookBatchCopyWith<$Res>? get lastBatch {
    if (_self.lastBatch == null) {
    return null;
  }

  return $WorkbookBatchCopyWith<$Res>(_self.lastBatch!, (value) {
    return _then(_self.copyWith(lastBatch: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConsolidatorUiState].
extension ConsolidatorUiStatePatterns on ConsolidatorUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsolidatorUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsolidatorUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsolidatorUiState value)  $default,){
final _that = this;
switch (_that) {
case _ConsolidatorUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsolidatorUiState value)?  $default,){
final _that = this;
switch (_that) {
case _ConsolidatorUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConsolidatorPhase phase,  String? selectedFolderPath,  String? outputFileName,  double progress,  String? errorMessage,  WorkbookBatch? lastBatch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsolidatorUiState() when $default != null:
return $default(_that.phase,_that.selectedFolderPath,_that.outputFileName,_that.progress,_that.errorMessage,_that.lastBatch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConsolidatorPhase phase,  String? selectedFolderPath,  String? outputFileName,  double progress,  String? errorMessage,  WorkbookBatch? lastBatch)  $default,) {final _that = this;
switch (_that) {
case _ConsolidatorUiState():
return $default(_that.phase,_that.selectedFolderPath,_that.outputFileName,_that.progress,_that.errorMessage,_that.lastBatch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConsolidatorPhase phase,  String? selectedFolderPath,  String? outputFileName,  double progress,  String? errorMessage,  WorkbookBatch? lastBatch)?  $default,) {final _that = this;
switch (_that) {
case _ConsolidatorUiState() when $default != null:
return $default(_that.phase,_that.selectedFolderPath,_that.outputFileName,_that.progress,_that.errorMessage,_that.lastBatch);case _:
  return null;

}
}

}

/// @nodoc


class _ConsolidatorUiState implements ConsolidatorUiState {
  const _ConsolidatorUiState({this.phase = ConsolidatorPhase.empty, this.selectedFolderPath, this.outputFileName, this.progress = 0, this.errorMessage, this.lastBatch});
  

@override@JsonKey() final  ConsolidatorPhase phase;
@override final  String? selectedFolderPath;
@override final  String? outputFileName;
@override@JsonKey() final  double progress;
@override final  String? errorMessage;
@override final  WorkbookBatch? lastBatch;

/// Create a copy of ConsolidatorUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsolidatorUiStateCopyWith<_ConsolidatorUiState> get copyWith => __$ConsolidatorUiStateCopyWithImpl<_ConsolidatorUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsolidatorUiState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedFolderPath, selectedFolderPath) || other.selectedFolderPath == selectedFolderPath)&&(identical(other.outputFileName, outputFileName) || other.outputFileName == outputFileName)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastBatch, lastBatch) || other.lastBatch == lastBatch));
}


@override
int get hashCode => Object.hash(runtimeType,phase,selectedFolderPath,outputFileName,progress,errorMessage,lastBatch);

@override
String toString() {
  return 'ConsolidatorUiState(phase: $phase, selectedFolderPath: $selectedFolderPath, outputFileName: $outputFileName, progress: $progress, errorMessage: $errorMessage, lastBatch: $lastBatch)';
}


}

/// @nodoc
abstract mixin class _$ConsolidatorUiStateCopyWith<$Res> implements $ConsolidatorUiStateCopyWith<$Res> {
  factory _$ConsolidatorUiStateCopyWith(_ConsolidatorUiState value, $Res Function(_ConsolidatorUiState) _then) = __$ConsolidatorUiStateCopyWithImpl;
@override @useResult
$Res call({
 ConsolidatorPhase phase, String? selectedFolderPath, String? outputFileName, double progress, String? errorMessage, WorkbookBatch? lastBatch
});


@override $WorkbookBatchCopyWith<$Res>? get lastBatch;

}
/// @nodoc
class __$ConsolidatorUiStateCopyWithImpl<$Res>
    implements _$ConsolidatorUiStateCopyWith<$Res> {
  __$ConsolidatorUiStateCopyWithImpl(this._self, this._then);

  final _ConsolidatorUiState _self;
  final $Res Function(_ConsolidatorUiState) _then;

/// Create a copy of ConsolidatorUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? selectedFolderPath = freezed,Object? outputFileName = freezed,Object? progress = null,Object? errorMessage = freezed,Object? lastBatch = freezed,}) {
  return _then(_ConsolidatorUiState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ConsolidatorPhase,selectedFolderPath: freezed == selectedFolderPath ? _self.selectedFolderPath : selectedFolderPath // ignore: cast_nullable_to_non_nullable
as String?,outputFileName: freezed == outputFileName ? _self.outputFileName : outputFileName // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,lastBatch: freezed == lastBatch ? _self.lastBatch : lastBatch // ignore: cast_nullable_to_non_nullable
as WorkbookBatch?,
  ));
}

/// Create a copy of ConsolidatorUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkbookBatchCopyWith<$Res>? get lastBatch {
    if (_self.lastBatch == null) {
    return null;
  }

  return $WorkbookBatchCopyWith<$Res>(_self.lastBatch!, (value) {
    return _then(_self.copyWith(lastBatch: value));
  });
}
}

// dart format on
