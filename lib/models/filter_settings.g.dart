// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FilterSettings _$FilterSettingsFromJson(Map<String, dynamic> json) =>
    _FilterSettings(
      onlyVideo: json['onlyVideo'] as bool? ?? true,
      ignoreSmallFiles: json['ignoreSmallFiles'] as bool? ?? false,
      minSizeBytes: (json['minSizeBytes'] as num?)?.toInt(),
      downloadLimit: (json['downloadLimit'] as num?)?.toInt(),
      allowedExtensions:
          (json['allowedExtensions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{'mp4', 'webm'},
    );

Map<String, dynamic> _$FilterSettingsToJson(_FilterSettings instance) =>
    <String, dynamic>{
      'onlyVideo': instance.onlyVideo,
      'ignoreSmallFiles': instance.ignoreSmallFiles,
      'minSizeBytes': instance.minSizeBytes,
      'downloadLimit': instance.downloadLimit,
      'allowedExtensions': instance.allowedExtensions.toList(),
    };
