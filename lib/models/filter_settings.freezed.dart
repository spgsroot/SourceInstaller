// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FilterSettings {

 bool get onlyVideo; bool get ignoreSmallFiles; int? get minSizeBytes; int? get downloadLimit; Set<String> get allowedExtensions;
/// Create a copy of FilterSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterSettingsCopyWith<FilterSettings> get copyWith => _$FilterSettingsCopyWithImpl<FilterSettings>(this as FilterSettings, _$identity);

  /// Serializes this FilterSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterSettings&&(identical(other.onlyVideo, onlyVideo) || other.onlyVideo == onlyVideo)&&(identical(other.ignoreSmallFiles, ignoreSmallFiles) || other.ignoreSmallFiles == ignoreSmallFiles)&&(identical(other.minSizeBytes, minSizeBytes) || other.minSizeBytes == minSizeBytes)&&(identical(other.downloadLimit, downloadLimit) || other.downloadLimit == downloadLimit)&&const DeepCollectionEquality().equals(other.allowedExtensions, allowedExtensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,onlyVideo,ignoreSmallFiles,minSizeBytes,downloadLimit,const DeepCollectionEquality().hash(allowedExtensions));

@override
String toString() {
  return 'FilterSettings(onlyVideo: $onlyVideo, ignoreSmallFiles: $ignoreSmallFiles, minSizeBytes: $minSizeBytes, downloadLimit: $downloadLimit, allowedExtensions: $allowedExtensions)';
}


}

/// @nodoc
abstract mixin class $FilterSettingsCopyWith<$Res>  {
  factory $FilterSettingsCopyWith(FilterSettings value, $Res Function(FilterSettings) _then) = _$FilterSettingsCopyWithImpl;
@useResult
$Res call({
 bool onlyVideo, bool ignoreSmallFiles, int? minSizeBytes, int? downloadLimit, Set<String> allowedExtensions
});




}
/// @nodoc
class _$FilterSettingsCopyWithImpl<$Res>
    implements $FilterSettingsCopyWith<$Res> {
  _$FilterSettingsCopyWithImpl(this._self, this._then);

  final FilterSettings _self;
  final $Res Function(FilterSettings) _then;

/// Create a copy of FilterSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? onlyVideo = null,Object? ignoreSmallFiles = null,Object? minSizeBytes = freezed,Object? downloadLimit = freezed,Object? allowedExtensions = null,}) {
  return _then(_self.copyWith(
onlyVideo: null == onlyVideo ? _self.onlyVideo : onlyVideo // ignore: cast_nullable_to_non_nullable
as bool,ignoreSmallFiles: null == ignoreSmallFiles ? _self.ignoreSmallFiles : ignoreSmallFiles // ignore: cast_nullable_to_non_nullable
as bool,minSizeBytes: freezed == minSizeBytes ? _self.minSizeBytes : minSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,downloadLimit: freezed == downloadLimit ? _self.downloadLimit : downloadLimit // ignore: cast_nullable_to_non_nullable
as int?,allowedExtensions: null == allowedExtensions ? _self.allowedExtensions : allowedExtensions // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [FilterSettings].
extension FilterSettingsPatterns on FilterSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FilterSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FilterSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FilterSettings value)  $default,){
final _that = this;
switch (_that) {
case _FilterSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FilterSettings value)?  $default,){
final _that = this;
switch (_that) {
case _FilterSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool onlyVideo,  bool ignoreSmallFiles,  int? minSizeBytes,  int? downloadLimit,  Set<String> allowedExtensions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FilterSettings() when $default != null:
return $default(_that.onlyVideo,_that.ignoreSmallFiles,_that.minSizeBytes,_that.downloadLimit,_that.allowedExtensions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool onlyVideo,  bool ignoreSmallFiles,  int? minSizeBytes,  int? downloadLimit,  Set<String> allowedExtensions)  $default,) {final _that = this;
switch (_that) {
case _FilterSettings():
return $default(_that.onlyVideo,_that.ignoreSmallFiles,_that.minSizeBytes,_that.downloadLimit,_that.allowedExtensions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool onlyVideo,  bool ignoreSmallFiles,  int? minSizeBytes,  int? downloadLimit,  Set<String> allowedExtensions)?  $default,) {final _that = this;
switch (_that) {
case _FilterSettings() when $default != null:
return $default(_that.onlyVideo,_that.ignoreSmallFiles,_that.minSizeBytes,_that.downloadLimit,_that.allowedExtensions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FilterSettings extends FilterSettings {
  const _FilterSettings({this.onlyVideo = true, this.ignoreSmallFiles = false, this.minSizeBytes, this.downloadLimit, final  Set<String> allowedExtensions = const <String>{'mp4', 'webm'}}): _allowedExtensions = allowedExtensions,super._();
  factory _FilterSettings.fromJson(Map<String, dynamic> json) => _$FilterSettingsFromJson(json);

@override@JsonKey() final  bool onlyVideo;
@override@JsonKey() final  bool ignoreSmallFiles;
@override final  int? minSizeBytes;
@override final  int? downloadLimit;
 final  Set<String> _allowedExtensions;
@override@JsonKey() Set<String> get allowedExtensions {
  if (_allowedExtensions is EqualUnmodifiableSetView) return _allowedExtensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_allowedExtensions);
}


/// Create a copy of FilterSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilterSettingsCopyWith<_FilterSettings> get copyWith => __$FilterSettingsCopyWithImpl<_FilterSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilterSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FilterSettings&&(identical(other.onlyVideo, onlyVideo) || other.onlyVideo == onlyVideo)&&(identical(other.ignoreSmallFiles, ignoreSmallFiles) || other.ignoreSmallFiles == ignoreSmallFiles)&&(identical(other.minSizeBytes, minSizeBytes) || other.minSizeBytes == minSizeBytes)&&(identical(other.downloadLimit, downloadLimit) || other.downloadLimit == downloadLimit)&&const DeepCollectionEquality().equals(other._allowedExtensions, _allowedExtensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,onlyVideo,ignoreSmallFiles,minSizeBytes,downloadLimit,const DeepCollectionEquality().hash(_allowedExtensions));

@override
String toString() {
  return 'FilterSettings(onlyVideo: $onlyVideo, ignoreSmallFiles: $ignoreSmallFiles, minSizeBytes: $minSizeBytes, downloadLimit: $downloadLimit, allowedExtensions: $allowedExtensions)';
}


}

/// @nodoc
abstract mixin class _$FilterSettingsCopyWith<$Res> implements $FilterSettingsCopyWith<$Res> {
  factory _$FilterSettingsCopyWith(_FilterSettings value, $Res Function(_FilterSettings) _then) = __$FilterSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool onlyVideo, bool ignoreSmallFiles, int? minSizeBytes, int? downloadLimit, Set<String> allowedExtensions
});




}
/// @nodoc
class __$FilterSettingsCopyWithImpl<$Res>
    implements _$FilterSettingsCopyWith<$Res> {
  __$FilterSettingsCopyWithImpl(this._self, this._then);

  final _FilterSettings _self;
  final $Res Function(_FilterSettings) _then;

/// Create a copy of FilterSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? onlyVideo = null,Object? ignoreSmallFiles = null,Object? minSizeBytes = freezed,Object? downloadLimit = freezed,Object? allowedExtensions = null,}) {
  return _then(_FilterSettings(
onlyVideo: null == onlyVideo ? _self.onlyVideo : onlyVideo // ignore: cast_nullable_to_non_nullable
as bool,ignoreSmallFiles: null == ignoreSmallFiles ? _self.ignoreSmallFiles : ignoreSmallFiles // ignore: cast_nullable_to_non_nullable
as bool,minSizeBytes: freezed == minSizeBytes ? _self.minSizeBytes : minSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,downloadLimit: freezed == downloadLimit ? _self.downloadLimit : downloadLimit // ignore: cast_nullable_to_non_nullable
as int?,allowedExtensions: null == allowedExtensions ? _self._allowedExtensions : allowedExtensions // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
