import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/app_database.dart';
import '../data/repositories.dart';
import '../errors/scrape_exception.dart';
import '../models/download_task.dart';
import '../models/filter_settings.dart';
import '../models/media_item.dart';
import '../scrapers/base_scraper.dart';
import '../scrapers/dynamic_webview_scraper.dart';
import '../scrapers/reddit_scraper.dart';
import '../scrapers/scraper_registry.dart';
import '../services/download_manager_service.dart';
import '../services/logger_service.dart';

final loggerServiceProvider = Provider<LoggerService>(
  (ref) => LoggerService.instance,
);

final appDatabaseProvider = Provider<AppDatabase?>((ref) => null);

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  if (database == null) return InMemoryHistoryRepository();
  return IsarHistoryRepository(database.isar);
});

final filterSettingsRepositoryProvider = Provider<FilterSettingsRepository>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);
  if (database == null) return InMemoryFilterSettingsRepository();
  return IsarFilterSettingsRepository(database.isar);
});

final downloadedFileRepositoryProvider = Provider<DownloadedFileRepository>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);
  if (database == null) return InMemoryDownloadedFileRepository();
  return IsarDownloadedFileRepository(database.isar);
});

final filterSettingsProvider =
    NotifierProvider<FilterSettingsNotifier, FilterSettings>(
      FilterSettingsNotifier.new,
    );

class FilterSettingsNotifier extends Notifier<FilterSettings> {
  late final FilterSettingsRepository _repository;

  @override
  FilterSettings build() {
    _repository = ref.watch(filterSettingsRepositoryProvider);
    Future.microtask(_load);
    return const FilterSettings();
  }

  void setOnlyVideo(bool value) {
    _save(
      state.copyWith(
        onlyVideo: value,
        allowedExtensions: value
            ? const {'mp4', 'webm'}
            : const {'mp4', 'webm', 'jpg', 'jpeg', 'png', 'gif', 'webp'},
      ),
    );
  }

  void setIgnoreSmallFiles(bool value) {
    _save(state.copyWith(ignoreSmallFiles: value));
  }

  void setDownloadLimit(int? value) {
    _save(state.copyWith(downloadLimit: value));
  }

  Future<void> _load() async {
    final saved = await _repository.load();
    if (saved != null) state = saved;
  }

  void _save(FilterSettings settings) {
    state = settings;
    Future<void>.microtask(() => _repository.save(settings));
  }
}

final scraperRegistryProvider = Provider<ScraperRegistry>((ref) {
  return ScraperRegistry(logger: ref.watch(loggerServiceProvider));
});

final downloadManagerProvider = Provider<DownloadManagerService>((ref) {
  return DownloadManagerService(
    logger: ref.watch(loggerServiceProvider),
    downloadedFiles: ref.watch(downloadedFileRepositoryProvider),
  );
});

final analysisControllerProvider =
    NotifierProvider<AnalysisController, AsyncValue<List<MediaItem>>>(
      AnalysisController.new,
    );

class AnalysisController extends Notifier<AsyncValue<List<MediaItem>>> {
  @override
  AsyncValue<List<MediaItem>> build() => const AsyncValue.data([]);

  Future<void> analyze(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return;

    state = const AsyncValue.loading();
    final logger = ref.read(loggerServiceProvider);

    await _runAnalysis(
      url,
      logger: logger,
      extract: (scraper, filters) =>
          scraper.extractMedia(url, filters: filters),
    );
  }

  Future<void> analyzeWithWebView(
    String rawUrl,
    InAppWebViewController controller, {
    Set<String> capturedMediaUrls = const <String>{},
  }) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return;

    final logger = ref.read(loggerServiceProvider);
    await logger.info(
      'Продолжение анализа в уже открытом WebView',
      source: url,
    );

    await _runAnalysis(
      url,
      logger: logger,
      extract: (scraper, filters) {
        if (scraper is DynamicWebViewScraper) {
          return scraper.extractMediaFromWebView(
            url,
            controller,
            filters: filters,
            capturedMediaUrls: capturedMediaUrls,
          );
        }
        if (scraper is RedditScraper) {
          return scraper.extractMediaFromWebView(
            url,
            controller,
            filters: filters,
            capturedMediaUrls: capturedMediaUrls,
          );
        }
        return scraper.extractMedia(url, filters: filters);
      },
    );
  }

  Future<void> _runAnalysis(
    String url, {
    required LoggerService logger,
    required Future<List<MediaItem>> Function(
      BaseScraper scraper,
      FilterSettings filters,
    )
    extract,
  }) async {
    try {
      final registry = ref.read(scraperRegistryProvider);
      final scraper = registry.forUrl(url);
      final filters = ref.read(filterSettingsProvider);
      final items = await extract(scraper, filters);
      await ref
          .read(historyRepositoryProvider)
          .add(
            HistoryEntry(
              sourceUrl: url,
              foundCount: items.length,
              createdAt: DateTime.now(),
            ),
          );
      state = AsyncValue.data(items);
      await logger.success(
        'Анализ завершён: ${items.length} файлов',
        source: url,
      );
    } on CaptchaRequiredException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      await logger.warning(error.message, source: url);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      await logger.error(
        'Анализ не выполнен',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final downloadQueueProvider =
    NotifierProvider<DownloadQueueNotifier, List<DownloadTask>>(
      DownloadQueueNotifier.new,
    );

class DownloadQueueNotifier extends Notifier<List<DownloadTask>> {
  @override
  List<DownloadTask> build() => const [];

  Future<void> enqueue(MediaItem item) async {
    final existingTask = _findExistingTask(item);
    if (existingTask != null) return;

    final manager = ref.read(downloadManagerProvider);
    final filters = ref.read(filterSettingsProvider);
    await manager.enqueue(item, filters: filters, onUpdate: _upsert);
  }

  Future<void> enqueueAll(List<MediaItem> items) async {
    final limit = ref.read(filterSettingsProvider).downloadLimit;
    final limitedItems = limit == null ? items : items.take(limit).toList();
    await Future.wait(limitedItems.map(enqueue));
  }

  Future<void> pause(String taskId) async {
    final manager = ref.read(downloadManagerProvider);
    final paused = await manager.pause(taskId);
    if (paused) {
      _replaceState(taskId, DownloadState.paused);
    }
  }

  Future<void> cancel(String taskId) async {
    final manager = ref.read(downloadManagerProvider);
    final canceled = await manager.cancel(taskId);
    if (canceled) {
      _replaceState(taskId, DownloadState.canceled);
    }
  }

  void clearCompleted() {
    state = state
        .where((task) => task.state != DownloadState.completed)
        .toList(growable: false);
  }

  void _upsert(DownloadTask task) {
    final existingIndex = state.indexWhere((entry) => entry.id == task.id);
    if (existingIndex == -1) {
      state = [...state, task];
      return;
    }

    state = [
      for (var index = 0; index < state.length; index++)
        if (index == existingIndex) task else state[index],
    ];
  }

  void _replaceState(String taskId, DownloadState nextState) {
    state = [
      for (final task in state)
        if (task.id == taskId) task.copyWith(state: nextState) else task,
    ];
  }

  DownloadTask? _findExistingTask(MediaItem item) {
    for (final task in state.reversed) {
      if (task.mediaItem.url == item.url ||
          task.mediaItem.fileName == item.fileName) {
        return task;
      }
    }
    return null;
  }
}
