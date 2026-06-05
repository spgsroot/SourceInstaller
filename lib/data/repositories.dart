import 'package:isar_community/isar.dart';

import '../models/filter_settings.dart';
import '../models/log_entry.dart';
import '../models/media_item.dart';
import '../services/logger_service.dart';
import 'isar_schemas.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.sourceUrl,
    required this.foundCount,
    required this.createdAt,
  });

  final String sourceUrl;
  final int foundCount;
  final DateTime createdAt;
}

abstract interface class HistoryRepository {
  Future<void> add(HistoryEntry entry);
  Future<List<HistoryEntry>> recent({int limit = 20});
}

class InMemoryHistoryRepository implements HistoryRepository {
  final List<HistoryEntry> _entries = [];

  @override
  Future<void> add(HistoryEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<HistoryEntry>> recent({int limit = 20}) async {
    final start = _entries.length > limit ? _entries.length - limit : 0;
    return List.unmodifiable(_entries.skip(start));
  }
}

class IsarHistoryRepository implements HistoryRepository {
  const IsarHistoryRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> add(HistoryEntry entry) async {
    final schema = HistorySchema()
      ..sourceUrl = entry.sourceUrl
      ..foundCount = entry.foundCount
      ..createdAt = entry.createdAt;

    await _isar.writeTxn(() => _isar.historySchemas.put(schema));
  }

  @override
  Future<List<HistoryEntry>> recent({int limit = 20}) async {
    final rows = await _isar.historySchemas
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();

    return rows.reversed
        .map(
          (row) => HistoryEntry(
            sourceUrl: row.sourceUrl,
            foundCount: row.foundCount,
            createdAt: row.createdAt,
          ),
        )
        .toList(growable: false);
  }
}

abstract interface class FilterSettingsRepository {
  Future<FilterSettings?> load();
  Future<void> save(FilterSettings settings);
}

class InMemoryFilterSettingsRepository implements FilterSettingsRepository {
  FilterSettings? _settings;

  @override
  Future<FilterSettings?> load() async => _settings;

  @override
  Future<void> save(FilterSettings settings) async {
    _settings = settings;
  }
}

class IsarFilterSettingsRepository implements FilterSettingsRepository {
  const IsarFilterSettingsRepository(this._isar);

  static const _settingsId = 1;

  final Isar _isar;

  @override
  Future<FilterSettings?> load() async {
    final row = await _isar.filterSettingsSchemas.get(_settingsId);
    if (row == null) return null;

    return FilterSettings(
      onlyVideo: row.onlyVideo,
      ignoreSmallFiles: row.ignoreSmallFiles,
      minSizeBytes: row.minSizeBytes,
      downloadLimit: row.downloadLimit,
      allowedExtensions: row.allowedExtensions.toSet(),
    );
  }

  @override
  Future<void> save(FilterSettings settings) async {
    final row = FilterSettingsSchema()
      ..id = _settingsId
      ..onlyVideo = settings.onlyVideo
      ..ignoreSmallFiles = settings.ignoreSmallFiles
      ..minSizeBytes = settings.minSizeBytes
      ..downloadLimit = settings.downloadLimit
      ..allowedExtensions = settings.allowedExtensions.toList(growable: false);

    await _isar.writeTxn(() => _isar.filterSettingsSchemas.put(row));
  }
}

class IsarLogRepository implements LogRepository {
  const IsarLogRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> add(LogEntry entry) async {
    final row = LogSchema()
      ..timestamp = entry.timestamp
      ..level = entry.level.name
      ..message = entry.message
      ..source = entry.source;

    await _isar.writeTxn(() => _isar.logSchemas.put(row));
  }

  @override
  Future<List<LogEntry>> recent({int limit = 100}) async {
    final rows = await _isar.logSchemas
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();

    return rows.reversed
        .map(
          (row) => LogEntry(
            timestamp: row.timestamp,
            level: AppLogLevel.values.byName(row.level),
            message: row.message,
            source: row.source,
          ),
        )
        .toList(growable: false);
  }
}

class DownloadedFileEntry {
  const DownloadedFileEntry({
    required this.url,
    required this.fileName,
    required this.savedPath,
    required this.extension,
    required this.downloadedAt,
    this.sourceUrl,
  });

  final String url;
  final String fileName;
  final String savedPath;
  final String extension;
  final DateTime downloadedAt;
  final String? sourceUrl;
}

abstract interface class DownloadedFileRepository {
  Future<DownloadedFileEntry?> findExisting(MediaItem item);
  Future<void> add(DownloadedFileEntry entry);
}

class InMemoryDownloadedFileRepository implements DownloadedFileRepository {
  final List<DownloadedFileEntry> _entries = [];

  @override
  Future<DownloadedFileEntry?> findExisting(MediaItem item) async {
    for (final entry in _entries.reversed) {
      if (entry.url == item.url || entry.fileName == item.fileName) {
        return entry;
      }
    }
    return null;
  }

  @override
  Future<void> add(DownloadedFileEntry entry) async {
    _entries.removeWhere(
      (current) =>
          current.url == entry.url || current.fileName == entry.fileName,
    );
    _entries.add(entry);
  }
}

class IsarDownloadedFileRepository implements DownloadedFileRepository {
  const IsarDownloadedFileRepository(this._isar);

  final Isar _isar;

  @override
  Future<DownloadedFileEntry?> findExisting(MediaItem item) async {
    final rows = await _isar.downloadedFileSchemas.where().findAll();
    for (final row in rows.reversed) {
      if (row.url == item.url || row.fileName == item.fileName) {
        return DownloadedFileEntry(
          url: row.url,
          fileName: row.fileName,
          savedPath: row.savedPath,
          extension: row.extension,
          downloadedAt: row.downloadedAt,
          sourceUrl: row.sourceUrl,
        );
      }
    }
    return null;
  }

  @override
  Future<void> add(DownloadedFileEntry entry) async {
    final rows = await _isar.downloadedFileSchemas.where().findAll();
    final duplicateIds = rows
        .where((row) => row.url == entry.url || row.fileName == entry.fileName)
        .map((row) => row.id)
        .toList(growable: false);

    final row = DownloadedFileSchema()
      ..url = entry.url
      ..fileName = entry.fileName
      ..savedPath = entry.savedPath
      ..extension = entry.extension
      ..downloadedAt = entry.downloadedAt
      ..sourceUrl = entry.sourceUrl;

    await _isar.writeTxn(() async {
      if (duplicateIds.isNotEmpty) {
        await _isar.downloadedFileSchemas.deleteAll(duplicateIds);
      }
      await _isar.downloadedFileSchemas.put(row);
    });
  }
}
