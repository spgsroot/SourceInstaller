// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadTask _$DownloadTaskFromJson(Map<String, dynamic> json) =>
    _DownloadTask(
      id: json['id'] as String,
      mediaItem: MediaItem.fromJson(json['mediaItem'] as Map<String, dynamic>),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      state:
          $enumDecodeNullable(_$DownloadStateEnumMap, json['state']) ??
          DownloadState.queued,
      savedPath: json['savedPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$DownloadTaskToJson(_DownloadTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaItem': instance.mediaItem,
      'progress': instance.progress,
      'state': _$DownloadStateEnumMap[instance.state]!,
      'savedPath': instance.savedPath,
      'errorMessage': instance.errorMessage,
    };

const _$DownloadStateEnumMap = {
  DownloadState.queued: 'queued',
  DownloadState.running: 'running',
  DownloadState.paused: 'paused',
  DownloadState.completed: 'completed',
  DownloadState.failed: 'failed',
  DownloadState.canceled: 'canceled',
};
