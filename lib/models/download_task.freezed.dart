// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadTask {

 String get id; MediaItem get mediaItem; double get progress; DownloadState get state; String? get savedPath; String? get errorMessage;
/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadTaskCopyWith<DownloadTask> get copyWith => _$DownloadTaskCopyWithImpl<DownloadTask>(this as DownloadTask, _$identity);

  /// Serializes this DownloadTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.savedPath, savedPath) || other.savedPath == savedPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaItem,progress,state,savedPath,errorMessage);

@override
String toString() {
  return 'DownloadTask(id: $id, mediaItem: $mediaItem, progress: $progress, state: $state, savedPath: $savedPath, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $DownloadTaskCopyWith<$Res>  {
  factory $DownloadTaskCopyWith(DownloadTask value, $Res Function(DownloadTask) _then) = _$DownloadTaskCopyWithImpl;
@useResult
$Res call({
 String id, MediaItem mediaItem, double progress, DownloadState state, String? savedPath, String? errorMessage
});


$MediaItemCopyWith<$Res> get mediaItem;

}
/// @nodoc
class _$DownloadTaskCopyWithImpl<$Res>
    implements $DownloadTaskCopyWith<$Res> {
  _$DownloadTaskCopyWithImpl(this._self, this._then);

  final DownloadTask _self;
  final $Res Function(DownloadTask) _then;

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaItem = null,Object? progress = null,Object? state = null,Object? savedPath = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaItem: null == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as DownloadState,savedPath: freezed == savedPath ? _self.savedPath : savedPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaItemCopyWith<$Res> get mediaItem {
  
  return $MediaItemCopyWith<$Res>(_self.mediaItem, (value) {
    return _then(_self.copyWith(mediaItem: value));
  });
}
}


/// Adds pattern-matching-related methods to [DownloadTask].
extension DownloadTaskPatterns on DownloadTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadTask value)  $default,){
final _that = this;
switch (_that) {
case _DownloadTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadTask value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MediaItem mediaItem,  double progress,  DownloadState state,  String? savedPath,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
return $default(_that.id,_that.mediaItem,_that.progress,_that.state,_that.savedPath,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MediaItem mediaItem,  double progress,  DownloadState state,  String? savedPath,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _DownloadTask():
return $default(_that.id,_that.mediaItem,_that.progress,_that.state,_that.savedPath,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MediaItem mediaItem,  double progress,  DownloadState state,  String? savedPath,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
return $default(_that.id,_that.mediaItem,_that.progress,_that.state,_that.savedPath,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadTask implements DownloadTask {
  const _DownloadTask({required this.id, required this.mediaItem, this.progress = 0, this.state = DownloadState.queued, this.savedPath, this.errorMessage});
  factory _DownloadTask.fromJson(Map<String, dynamic> json) => _$DownloadTaskFromJson(json);

@override final  String id;
@override final  MediaItem mediaItem;
@override@JsonKey() final  double progress;
@override@JsonKey() final  DownloadState state;
@override final  String? savedPath;
@override final  String? errorMessage;

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadTaskCopyWith<_DownloadTask> get copyWith => __$DownloadTaskCopyWithImpl<_DownloadTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.savedPath, savedPath) || other.savedPath == savedPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaItem,progress,state,savedPath,errorMessage);

@override
String toString() {
  return 'DownloadTask(id: $id, mediaItem: $mediaItem, progress: $progress, state: $state, savedPath: $savedPath, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$DownloadTaskCopyWith<$Res> implements $DownloadTaskCopyWith<$Res> {
  factory _$DownloadTaskCopyWith(_DownloadTask value, $Res Function(_DownloadTask) _then) = __$DownloadTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, MediaItem mediaItem, double progress, DownloadState state, String? savedPath, String? errorMessage
});


@override $MediaItemCopyWith<$Res> get mediaItem;

}
/// @nodoc
class __$DownloadTaskCopyWithImpl<$Res>
    implements _$DownloadTaskCopyWith<$Res> {
  __$DownloadTaskCopyWithImpl(this._self, this._then);

  final _DownloadTask _self;
  final $Res Function(_DownloadTask) _then;

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaItem = null,Object? progress = null,Object? state = null,Object? savedPath = freezed,Object? errorMessage = freezed,}) {
  return _then(_DownloadTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaItem: null == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as DownloadState,savedPath: freezed == savedPath ? _self.savedPath : savedPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaItemCopyWith<$Res> get mediaItem {
  
  return $MediaItemCopyWith<$Res>(_self.mediaItem, (value) {
    return _then(_self.copyWith(mediaItem: value));
  });
}
}

// dart format on
