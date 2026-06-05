import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

enum AppLogLevel { debug, info, success, warning, error }

@freezed
abstract class LogEntry with _$LogEntry {
  const LogEntry._();

  const factory LogEntry({
    required DateTime timestamp,
    required AppLogLevel level,
    required String message,
    String? source,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);

  String get displayLevel => level.name.toUpperCase();
}
