// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => _MediaItem(
  url: json['url'] as String,
  fileName: json['fileName'] as String,
  extension: json['extension'] as String,
  sourceUrl: json['sourceUrl'] as String,
  sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
  quality: json['quality'] as String?,
);

Map<String, dynamic> _$MediaItemToJson(_MediaItem instance) =>
    <String, dynamic>{
      'url': instance.url,
      'fileName': instance.fileName,
      'extension': instance.extension,
      'sourceUrl': instance.sourceUrl,
      'sizeBytes': instance.sizeBytes,
      'quality': instance.quality,
    };
