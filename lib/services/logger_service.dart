import 'dart:async';

import 'package:logger/logger.dart' as console_logger;

import '../models/log_entry.dart';

abstract interface class LogRepository {
  Future<void> add(LogEntry entry);
  Future<List<LogEntry>> recent({int limit = 100});
}

class InMemoryLogRepository implements LogRepository {
  final List<LogEntry> _entries = [];

  @override
  Future<void> add(LogEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<LogEntry>> recent({int limit = 100}) async {
    final start = _entries.length > limit ? _entries.length - limit : 0;
    return List.unmodifiable(_entries.skip(start));
  }
}

class LoggerService {
  LoggerService._(this._repository);

  static LoggerService _instance = LoggerService._(InMemoryLogRepository());

  static LoggerService get instance => _instance;

  static void configure(LogRepository repository) {
    _instance = LoggerService._(repository);
  }

  final LogRepository _repository;
  final _streamController = StreamController<LogEntry>.broadcast();
  final _console = console_logger.Logger(
    printer: console_logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      printEmojis: false,
    ),
  );

  Stream<LogEntry> get stream => _streamController.stream;

  Future<List<LogEntry>> recent({int limit = 100}) =>
      _repository.recent(limit: limit);

  Future<void> debug(String message, {String? source}) =>
      _write(AppLogLevel.debug, message, source: source);

  Future<void> info(String message, {String? source}) =>
      _write(AppLogLevel.info, message, source: source);

  Future<void> success(String message, {String? source}) =>
      _write(AppLogLevel.success, message, source: source);

  Future<void> warning(String message, {String? source}) =>
      _write(AppLogLevel.warning, message, source: source);

  Future<void> error(
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _write(
      AppLogLevel.error,
      error == null ? message : '$message: $error',
      source: source,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _write(
    AppLogLevel level,
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
    );

    switch (level) {
      case AppLogLevel.debug:
        _console.d(message);
      case AppLogLevel.info:
        _console.i(message);
      case AppLogLevel.success:
        _console.i(message);
      case AppLogLevel.warning:
        _console.w(message);
      case AppLogLevel.error:
        _console.e(message, error: error, stackTrace: stackTrace);
    }

    await _repository.add(entry);
    if (!_streamController.isClosed) {
      _streamController.add(entry);
    }
  }
}
