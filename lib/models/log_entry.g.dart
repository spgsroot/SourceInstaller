// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => _LogEntry(
  timestamp: DateTime.parse(json['timestamp'] as String),
  level: $enumDecode(_$AppLogLevelEnumMap, json['level']),
  message: json['message'] as String,
  source: json['source'] as String?,
);

Map<String, dynamic> _$LogEntryToJson(_LogEntry instance) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'level': _$AppLogLevelEnumMap[instance.level]!,
  'message': instance.message,
  'source': instance.source,
};

const _$AppLogLevelEnumMap = {
  AppLogLevel.debug: 'debug',
  AppLogLevel.info: 'info',
  AppLogLevel.success: 'success',
  AppLogLevel.warning: 'warning',
  AppLogLevel.error: 'error',
};
