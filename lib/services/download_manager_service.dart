import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as downloader;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/download_task.dart' as app;
import '../models/filter_settings.dart';
import '../models/media_item.dart';
import 'logger_service.dart';

typedef DownloadUpdate = void Function(app.DownloadTask task);

class DownloadManagerService {
  DownloadManagerService({
    LoggerService? logger,
    DownloadedFileRepository? downloadedFiles,
  }) : _logger = logger ?? LoggerService.instance,
       _downloadedFiles = downloadedFiles ?? InMemoryDownloadedFileRepository();

  static const _downloadGroup = 'sourceInstallerDownloads';
  static const _notificationGroup = 'sourceInstallerDownloadsNotification';
  static const _maxManualRetries = 3;
  static const _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';

  final LoggerService _logger;
  final DownloadedFileRepository _downloadedFiles;
  final downloader.FileDownloader _downloader = downloader.FileDownloader();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'user-agent': _desktopUserAgent},
    ),
  );
  final Map<String, downloader.DownloadTask> _activeTasks = {};
  Future<void>? _configurationFuture;

  Future<void> enqueue(
    MediaItem item, {
    FilterSettings filters = const FilterSettings(),
    required DownloadUpdate onUpdate,
  }) async {
    await _ensureConfigured();

    if (!filters.acceptsExtension(item.extension) ||
        !filters.acceptsSize(item.sizeBytes)) {
      await _logger.warning(
        'Файл отброшен фильтрами: ${item.fileName}',
        source: item.sourceUrl,
      );
      return;
    }

    final existingPath = await _existingDownloadPath(item);
    if (existingPath != null) {
      final skippedState = app.DownloadTask(
        id: 'existing-${item.fileName}',
        mediaItem: item,
        progress: 1,
        state: app.DownloadState.completed,
        savedPath: existingPath,
      );
      onUpdate(skippedState);
      await _logger.info(
        'Файл уже скачан, повторная загрузка пропущена: ${item.fileName}',
        source: existingPath,
      );
      return;
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}-${item.fileName}';
    final initialTask = await _createDownloadTask(id, item);
    _activeTasks[id] = initialTask;

    var state = app.DownloadTask(id: id, mediaItem: item);
    onUpdate(state);

    await _logger.info(
      'Добавление в очередь загрузки: ${item.fileName}',
      source: initialTask.url,
    );

    downloader.DownloadTask completedTask = initialTask;

    try {
      final attemptResult = await _downloadWithManualRetries(
        initialTask,
        item,
        onProgress: (progress) {
          state = state.copyWith(
            progress: progress,
            state: app.DownloadState.running,
          );
          onUpdate(state);
        },
        onStatus: (status) {
          state = state.copyWith(state: _mapStatus(status));
          onUpdate(state);
        },
      );
      final result = attemptResult.result;
      completedTask = attemptResult.task;

      final savedPath = result.status == downloader.TaskStatus.complete
          ? await _moveToDownloads(completedTask, item.extension)
          : null;

      state = state.copyWith(
        progress: result.status == downloader.TaskStatus.complete
            ? 1
            : state.progress,
        state: _mapStatus(result.status),
        savedPath: savedPath,
        errorMessage: result.exception?.toString(),
      );
      onUpdate(state);

      if (result.status == downloader.TaskStatus.complete) {
        if (savedPath != null) {
          await _downloadedFiles.add(
            DownloadedFileEntry(
              url: item.url,
              fileName: item.fileName,
              savedPath: savedPath,
              extension: item.extension,
              downloadedAt: DateTime.now(),
              sourceUrl: item.sourceUrl,
            ),
          );
        }
        await _logger.success(
          'Загрузка завершена: ${item.fileName}',
          source: item.url,
        );
      } else {
        await _logger.error(
          'Ошибка загрузки: ${item.fileName}',
          source: item.url,
          error: result.exception,
        );
      }
    } catch (error, stackTrace) {
      state = state.copyWith(
        state: app.DownloadState.failed,
        errorMessage: error.toString(),
      );
      onUpdate(state);
      await _logger.error(
        'Сбой загрузчика',
        source: item.url,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _activeTasks.remove(id);
    }
  }

  Future<bool> pause(String taskId) async {
    await _ensureConfigured();

    final task = _activeTasks[taskId];
    if (task == null) {
      await _logger.warning('Задача не найдена для паузы', source: taskId);
      return false;
    }

    final paused = await _downloader.pause(task);
    await _logger.info(
      paused ? 'Пауза запрошена' : 'Пауза недоступна для задачи',
      source: taskId,
    );
    return paused;
  }

  Future<bool> cancel(String taskId) async {
    await _ensureConfigured();

    final canceled = await _downloader.cancelTaskWithId(taskId);
    _activeTasks.remove(taskId);
    await _logger.info(
      canceled ? 'Отмена запрошена' : 'Не удалось отменить задачу',
      source: taskId,
    );
    return canceled;
  }

  Future<downloader.DownloadTask> _createDownloadTask(
    String id,
    MediaItem item,
  ) async {
    final url = _isBunkrItem(item)
        ? await _resolveBunkrDownloadUrl(item)
        : item.url;

    return downloader.DownloadTask(
      taskId: id,
      url: url,
      headers: _headersForItem(item, url),
      filename: item.fileName,
      displayName: item.fileName,
      directory: 'source_installer',
      group: _downloadGroup,
      updates: downloader.Updates.statusAndProgress,
      // Built-in retries repeat the same stale signed URL. We need manual
      // retries so Bunkr URLs can be re-signed between attempts.
      retries: _isBunkrItem(item) ? 0 : 3,
      allowPause: true,
    );
  }

  Future<_DownloaderAttemptResult> _downloadWithManualRetries(
    downloader.DownloadTask initialTask,
    MediaItem item, {
    required void Function(double progress) onProgress,
    required void Function(downloader.TaskStatus status) onStatus,
  }) async {
    var task = initialTask;

    for (var attempt = 0; attempt <= _maxManualRetries; attempt++) {
      _activeTasks[task.taskId] = task;

      final result = await _downloader.download(
        task,
        onProgress: onProgress,
        onStatus: onStatus,
      );

      if (!_shouldRetryDownload(item, result, attempt)) {
        return _DownloaderAttemptResult(task: task, result: result);
      }

      final code = _httpStatusCode(result);
      await _logger.warning(
        'Временная ошибка CDN ($code), повтор ${attempt + 1}/$_maxManualRetries с новой подписью URL',
        source: task.url,
      );

      await Future<void>.delayed(Duration(seconds: 1 << attempt));
      task = await _refreshTaskForRetry(task, item);
      onStatus(downloader.TaskStatus.enqueued);
    }

    final result = await _downloader.download(
      task,
      onProgress: onProgress,
      onStatus: onStatus,
    );
    return _DownloaderAttemptResult(task: task, result: result);
  }

  bool _shouldRetryDownload(
    MediaItem item,
    downloader.TaskStatusUpdate result,
    int attempt,
  ) {
    if (result.status == downloader.TaskStatus.complete) return false;
    if (attempt >= _maxManualRetries) return false;

    final code = _httpStatusCode(result);
    if (code == null) {
      return _isBunkrItem(item) &&
          result.exception is downloader.TaskConnectionException;
    }

    final retryable =
        code == 408 ||
        code == 403 ||
        code == 404 ||
        code == 425 ||
        code == 429 ||
        code == 500 ||
        code == 502 ||
        code == 503 ||
        code == 504 ||
        (code >= 520 && code <= 524);
    if (!retryable) return false;

    // For Bunkr/CDN 5xx often means a stale signature or a temporarily bad CDN
    // edge. Retrying after re-signing is useful. For other hosts, keep the
    // package's own retry behavior to avoid duplicating work.
    return _isBunkrItem(item);
  }

  int? _httpStatusCode(downloader.TaskStatusUpdate result) {
    final responseStatusCode = result.responseStatusCode;
    if (responseStatusCode != null) return responseStatusCode;

    final exception = result.exception;
    if (exception is downloader.TaskHttpException) {
      return exception.httpResponseCode;
    }

    return null;
  }

  Future<downloader.DownloadTask> _refreshTaskForRetry(
    downloader.DownloadTask task,
    MediaItem item,
  ) async {
    final url = _isBunkrItem(item)
        ? await _resolveBunkrDownloadUrl(item)
        : task.url;
    return task.copyWith(
      url: url,
      headers: _headersForItem(item, url),
      retries: 0,
      retriesRemaining: 0,
    );
  }

  Map<String, String>? _headersForItem(MediaItem item, String downloadUrl) {
    if (!_isBunkrItem(item)) return null;

    final sourceUri = Uri.tryParse(item.sourceUrl);
    final origin =
        sourceUri?.hasScheme == true && sourceUri?.host.isNotEmpty == true
        ? '${sourceUri!.scheme}://${sourceUri.host}'
        : 'https://bunkr.cr';

    return {
      'user-agent': _desktopUserAgent,
      'accept': '*/*',
      'referer': sourceUri == null ? '$origin/' : item.sourceUrl,
      'origin': origin,
    };
  }

  bool _isBunkrItem(MediaItem item) {
    return _isBunkrRelatedUrl(item.sourceUrl) || _isBunkrRelatedUrl(item.url);
  }

  bool _isBunkrRelatedUrl(String value) {
    final host = Uri.tryParse(value)?.host.toLowerCase() ?? '';
    return host.contains('bunkr') ||
        host.endsWith('.cdn.cr') ||
        host.contains('gigachad-cdn') ||
        host == 'bnkr.b-cdn.net';
  }

  Future<String> _resolveBunkrDownloadUrl(MediaItem item) async {
    final sourceUri = Uri.tryParse(item.sourceUrl);
    if (sourceUri != null && _isBunkrFilePageUrl(sourceUri)) {
      try {
        final response = await _dio.get<String>(
          item.sourceUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: _pageHeadersForItem(item),
          ),
        );
        final jsCdn = _extractBunkrJsCdn(response.data ?? '');
        if (jsCdn != null) {
          await _logger.debug(
            'Bunkr: свежий jsCDN получен со страницы файла',
            source: item.sourceUrl,
          );
          return _signBunkrUrl(jsCdn);
        }

        await _logger.warning(
          'Bunkr: jsCDN не найден на странице файла, использую найденный ранее URL',
          source: item.sourceUrl,
        );
      } catch (error) {
        await _logger.warning(
          'Bunkr: не удалось заново открыть страницу файла: $error',
          source: item.sourceUrl,
        );
      }
    }

    return _signBunkrUrl(item.url);
  }

  Map<String, String> _pageHeadersForItem(MediaItem item) {
    final sourceUri = Uri.tryParse(item.sourceUrl);
    final origin = sourceUri != null && sourceUri.hasScheme
        ? '${sourceUri.scheme}://${sourceUri.host}'
        : 'https://bunkr.cr';

    return {
      'user-agent': _desktopUserAgent,
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'referer': origin,
      'origin': origin,
    };
  }

  String? _extractBunkrJsCdn(String html) {
    final match = RegExp(
      r'''var\s+jsCDN\s*=\s*(["'])(.*?)\1''',
      dotAll: true,
    ).firstMatch(html);
    final raw = match?.group(2);
    if (raw == null || raw.isEmpty) return null;

    final normalized = _normalizeBunkrUrl(raw);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !_isBunkrMediaUrl(uri)) return null;
    return normalized;
  }

  String _normalizeBunkrUrl(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\/', '/')
        .trim();
  }

  bool _isBunkrFilePageUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!host.contains('bunkr')) return false;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return false;
    return {'f', 'v', 'i', 'd'}.contains(segments.first.toLowerCase());
  }

  Future<String> _signBunkrUrl(String rawUrl) async {
    final normalized = _normalizeBunkrUrl(rawUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !_isBunkrMediaUrl(uri)) return normalized;

    try {
      final response = await _dio.getUri<Map<String, dynamic>>(
        Uri.https('glb-apisign.cdn.cr', '/sign', {'path': uri.path}),
      );

      final token = response.data?['token']?.toString();
      final ex = response.data?['ex']?.toString();
      if (token == null || token.isEmpty || ex == null || ex.isEmpty) {
        return normalized;
      }

      final nextQuery = Map<String, String>.from(uri.queryParameters);
      nextQuery['token'] = token;
      nextQuery['ex'] = ex;
      return uri.replace(queryParameters: nextQuery).toString();
    } catch (error) {
      await _logger.warning(
        'Не удалось обновить подпись Bunkr URL: $error',
        source: normalized,
      );
      return normalized;
    }
  }

  bool _isBunkrMediaUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    final isBunkrHost =
        host.endsWith('.cdn.cr') ||
        host.contains('bunkr') ||
        host.contains('gigachad-cdn') ||
        host == 'bnkr.b-cdn.net';
    if (!isBunkrHost) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.webm');
  }

  Future<void> _ensureConfigured() {
    return _configurationFuture ??= _configureDownloader();
  }

  Future<void> _configureDownloader() async {
    await _ensureNotificationPermission();
    await _downloader.configure(
      globalConfig: (
        downloader.Config.skipExistingFiles,
        downloader.Config.always,
      ),
    );

    _downloader.configureNotificationForGroup(
      _downloadGroup,
      running: const downloader.TaskNotification(
        'SourceInstaller',
        'Идёт загрузка: {numFinished}/{numTotal} • {progress}',
      ),
      complete: const downloader.TaskNotification(
        'Все видео скачаны',
        'Скачано файлов: {numTotal}',
      ),
      error: const downloader.TaskNotification(
        'Ошибка загрузки',
        'Ошибок: {numFailed} из {numTotal}',
      ),
      paused: const downloader.TaskNotification(
        'Загрузка на паузе',
        'Файл приостановлен',
      ),
      canceled: const downloader.TaskNotification(
        'Загрузка отменена',
        'Файл отменён',
      ),
      progressBar: true,
      tapOpensFile: true,
      groupNotificationId: _notificationGroup,
    );
  }

  Future<void> _ensureNotificationPermission() async {
    final status = await _downloader.permissions.status(
      downloader.PermissionType.notifications,
    );
    if (status == downloader.PermissionStatus.granted) return;

    await _downloader.permissions.request(
      downloader.PermissionType.notifications,
    );
  }

  Future<String?> _existingDownloadPath(MediaItem item) async {
    try {
      await _ensureSharedStoragePermission();
      final sharedPath = await _downloader.pathInSharedStorage(
        item.fileName,
        downloader.SharedStorage.downloads,
      );
      if (sharedPath != null) return sharedPath;
    } catch (error) {
      await _logger.debug(
        'Проверка существующего файла в Downloads не выполнена: $error',
        source: item.fileName,
      );
    }

    final recorded = await _downloadedFiles.findExisting(item);
    if (recorded == null) return null;

    if (recorded.savedPath.startsWith('content://')) {
      return recorded.savedPath;
    }

    if (await File(recorded.savedPath).exists()) {
      return recorded.savedPath;
    }

    return null;
  }

  Future<String> _moveToDownloads(
    downloader.DownloadTask task,
    String extension,
  ) async {
    final privatePath = await task.filePath();

    try {
      await _ensureSharedStoragePermission();
      final publicPath = await _downloader.moveToSharedStorage(
        task,
        downloader.SharedStorage.downloads,
        mimeType: _mimeTypeForExtension(extension),
      );

      if (publicPath != null && publicPath.isNotEmpty) {
        await _logger.success('Файл перемещён в Downloads', source: publicPath);
        return publicPath;
      }
    } catch (error, stackTrace) {
      await _logger.warning(
        'Не удалось переместить файл в Downloads: $error',
        source: privatePath,
      );
      await _logger.debug(stackTrace.toString(), source: privatePath);
    }

    return privatePath;
  }

  Future<void> _ensureSharedStoragePermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final status = await _downloader.permissions.status(
      downloader.PermissionType.androidSharedStorage,
    );
    if (status == downloader.PermissionStatus.granted) return;

    await _downloader.permissions.request(
      downloader.PermissionType.androidSharedStorage,
    );
  }

  String? _mimeTypeForExtension(String extension) {
    return switch (extension.toLowerCase().replaceFirst('.', '')) {
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  app.DownloadState _mapStatus(downloader.TaskStatus status) {
    return switch (status) {
      downloader.TaskStatus.enqueued => app.DownloadState.queued,
      downloader.TaskStatus.running => app.DownloadState.running,
      downloader.TaskStatus.paused => app.DownloadState.paused,
      downloader.TaskStatus.complete => app.DownloadState.completed,
      downloader.TaskStatus.canceled => app.DownloadState.canceled,
      downloader.TaskStatus.failed => app.DownloadState.failed,
      downloader.TaskStatus.notFound => app.DownloadState.failed,
      downloader.TaskStatus.waitingToRetry => app.DownloadState.queued,
    };
  }
}

class _DownloaderAttemptResult {
  const _DownloaderAttemptResult({required this.task, required this.result});

  final downloader.DownloadTask task;
  final downloader.TaskStatusUpdate result;
}
