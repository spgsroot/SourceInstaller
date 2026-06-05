import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../errors/scrape_exception.dart';
import '../models/filter_settings.dart';
import '../models/media_item.dart';
import '../services/logger_service.dart';
import 'base_scraper.dart';
import 'media_helpers.dart';

class DynamicWebViewScraper implements BaseScraper {
  DynamicWebViewScraper({LoggerService? logger})
    : _logger = logger ?? LoggerService.instance;

  static const _pageTimeout = Duration(seconds: 20);
  static const _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';
  static const _bunkrMediaExtensions = {
    'mp4',
    'webm',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  };

  static const _bunkrAlbumCandidatesScript = r'''
    (() => {
      const entries = [];
      const seen = new Set();
      const normalize = (value) => String(value || '')
        .replace(/\\u002F/g, '/')
        .replace(/\\\//g, '/')
        .trim();
      const extensionOf = (...values) => {
        for (const value of values) {
          const text = normalize(value).toLowerCase();
          const type = text.match(/video\/(mp4|webm)/);
          if (type) return type[1];
          const ext = text.match(/\.([a-z0-9]+)(?:[?#]|$)/);
          if (ext && ['mp4', 'webm', 'jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext[1])) {
            return ext[1];
          }
          if (text === 'video') return 'mp4';
          if (text === 'image') return 'jpg';
        }
        return null;
      };
      const add = (value, meta = {}) => {
        if (!value) return;
        try {
          const url = new URL(normalize(value), location.href);
          if (!/\/(f|i|v|d)\/[A-Za-z0-9_-]+/.test(url.pathname)) return;
          if (seen.has(url.href)) return;
          seen.add(url.href);
          entries.push({
            url: url.href,
            extension: meta.extension || null,
            name: meta.name || null,
            size: meta.size ?? null,
            directUrl: meta.directUrl || null,
          });
        } catch (_) {}
      };

      const directUrlFor = (file) => {
        const endpoint = normalize(file.cdnEndpoint || file.url || '');
        if (!/\.(mp4|webm)(?:[?#]|$)/i.test(endpoint)) return null;
        if (/^https?:\/\//i.test(endpoint)) return endpoint;
        try {
          const thumbnail = new URL(file.thumbnail || location.href);
          const host = thumbnail.host.replace(/^i-/, '');
          return `${thumbnail.protocol}//${host}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
        } catch (_) {
          return null;
        }
      };

      if (Array.isArray(window.albumFiles)) {
        for (const file of window.albumFiles) {
          const extension = extensionOf(
            file.type,
            file.extension,
            file.original,
            file.name,
            file.cdnEndpoint,
            file.url
          );
          const name = normalize(file.original || file.name || file.cdnEndpoint);
          add(`/f/${file.slug}`, {
            extension,
            name,
            size: file.size || file.filesize || file.fileSize || file.sizeBytes || file.size_bytes,
            directUrl: directUrlFor(file),
          });
        }
      }

      for (const anchor of document.querySelectorAll('a[href]')) {
        add(anchor.getAttribute('href'));
        add(anchor.href);
      }

      const html = document.documentElement.innerHTML;
      const albumFilesMatch = html.match(/window\.albumFiles\s*=\s*(\[[\s\S]*?\]);/);
      if (albumFilesMatch) {
        for (const match of albumFilesMatch[1].matchAll(/slug:\s*["']([^"']+)["']/g)) {
          add(`/f/${match[1]}`);
        }
      }

      return JSON.stringify(entries);
    })();
  ''';

  static const _bunkrFileMediaScript = r'''
    (async () => {
      const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
      const normalize = (value) => String(value || '')
        .replace(/\\u002F/g, '/')
        .replace(/\\\//g, '/')
        .trim();

      const collect = () => {
        const urls = new Set();
        const add = (value) => {
          const text = normalize(value);
          if (!text) return;
          try {
            const url = new URL(text, location.href).href;
            if (/\.(mp4|webm)(\?|$)/i.test(url)) urls.add(url);
          } catch (_) {}
        };
        const addFromSignUrl = (value, cdnValue) => {
          const text = normalize(value);
          if (!text || !/glb-apisign\.cdn\.cr\/sign/i.test(text)) return;
          try {
            const signUrl = new URL(text, location.href);
            const path = signUrl.searchParams.get('path');
            if (!path || !/\.(mp4|webm)$/i.test(path)) return;
            if (cdnValue) {
              const cdnUrl = new URL(cdnValue, location.href);
              add(`${cdnUrl.origin}${path}`);
              return;
            }
            const cover = normalize(window.videoCoverUrl || '');
            if (cover) {
              const coverUrl = new URL(cover, location.href);
              const host = coverUrl.host.replace(/^i-/, '');
              add(`${coverUrl.protocol}//${host}${path}`);
              return;
            }
            add(signUrl.href);
          } catch (_) {}
        };

        for (const element of document.querySelectorAll('video, source')) {
          add(element.currentSrc);
          add(element.src);
          add(element.getAttribute('src'));
        }

        for (const anchor of document.querySelectorAll('a[href]')) {
          add(anchor.href);
          add(anchor.getAttribute('href'));
        }

        const html = document.documentElement.innerHTML;
        for (const match of html.matchAll(/https?:\/\/[^"'<>\s]+\.(mp4|webm)[^"'<>\s]*/gi)) {
          add(match[0]);
        }

        const cdn = html.match(/var\s+jsCDN\s*=\s*["']([^"']+)["']/);
        const slug = html.match(/var\s+jsSlug\s*=\s*["']([^"']+)["']/);
        const cdnValue = normalize(window.jsCDN || (cdn && cdn[1]) || '');
        if (cdnValue) {
          if (/\.(mp4|webm)(\?|$)/i.test(cdnValue)) {
            add(cdnValue);
          } else if (slug) {
            add(`${cdnValue.replace(/\/$/, '')}/storage/media/${normalize(slug[1])}`);
          }
        }

        const signUrl = normalize(window.signUrl || '');
        if (signUrl && cdnValue) {
          try {
            const path = new URL(cdnValue, location.href).pathname;
            addFromSignUrl(`${signUrl}?path=${encodeURIComponent(path)}`, cdnValue);
          } catch (_) {}
        }
        for (const entry of performance.getEntriesByType('resource')) {
          add(entry.name);
          addFromSignUrl(entry.name, cdnValue);
        }
        for (const match of html.matchAll(/https?:\/\/glb-apisign\.cdn\.cr\/sign\?path=[^"'<>\s]+/gi)) {
          addFromSignUrl(match[0], cdnValue);
        }

        return Array.from(urls);
      };

      for (let attempt = 0; attempt < 40; attempt++) {
        const urls = collect();
        if (urls.length > 0) return urls;
        await sleep(500);
      }

      return collect();
    })();
  ''';

  static const _redgifsMediaScript = r'''
    (() => {
      const normalize = (value) => String(value || '')
        .replace(/\\u002F/g, '/')
        .replace(/\\\//g, '/')
        .trim();
      const mediaPattern = /\.(mp4|webm)([?#]|$)/i;

      const collect = () => {
        const urls = new Set();
        const add = (value) => {
          const text = normalize(value);
          if (!text || text.startsWith('blob:')) return;
          try {
            const absoluteUrl = new URL(text, location.href).href;
            if (mediaPattern.test(absoluteUrl)) urls.add(absoluteUrl);
          } catch (_) {}
        };

        for (const element of document.querySelectorAll('video, source')) {
          for (const attr of [
            'currentSrc',
            'src',
            'data-src',
            'data-video-src',
            'data-hd',
            'data-sd',
          ]) {
            add(element[attr]);
            add(element.getAttribute(attr));
          }

          if (element.tagName.toLowerCase() === 'video') {
            try {
              element.muted = true;
              element.preload = 'auto';
              element.setAttribute('playsinline', '');
              element.load?.();
              const promise = element.play?.();
              if (promise && typeof promise.catch === 'function') {
                promise.catch(() => {});
              }
            } catch (_) {}
          }
        }

        for (const element of document.querySelectorAll('[src], [href]')) {
          add(element.getAttribute('src'));
          add(element.getAttribute('href'));
          add(element.src);
          add(element.href);
        }

        for (const entry of performance.getEntriesByType('resource')) {
          add(entry.name);
        }

        const html = document.documentElement.innerHTML;
        for (const match of html.matchAll(/https?:\/\/[^"'<>\s]+\.(mp4|webm)[^"'<>\s]*/gi)) {
          add(match[0]);
        }

        return Array.from(urls);
      };

      try { window.scrollBy(0, Math.max(1, window.innerHeight / 2)); } catch (_) {}
      return collect();
    })();
  ''';

  final LoggerService _logger;

  @override
  bool canHandle(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return _isBunkrRelatedHost(host) || host.contains('redgifs');
  }

  @override
  Future<List<MediaItem>> extractMedia(
    String url, {
    FilterSettings? filters,
  }) async {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (_requiresVisibleWebView(host)) {
      await _logger.info(
        'RedGifs/Bunkr: сразу открываю видимый WebView',
        source: url,
      );
      throw CaptchaRequiredException(
        'Для RedGifs и Bunkr используется видимый WebView.',
        source: url,
      );
    }

    final effectiveFilters = filters ?? const FilterSettings();
    await _logger.info(
      'Начало динамического парсинга через WebView',
      source: url,
    );

    try {
      final host = Uri.parse(url).host.toLowerCase();
      final items = _isBunkrRelatedHost(host)
          ? await _extractBunkr(url)
          : await _extractRedgifs(url);
      final filtered = applyMediaFilters(items, effectiveFilters);
      await _logger.success(
        'Динамический парсинг завершён: ${filtered.length}',
        source: url,
      );
      return filtered;
    } on TimeoutException catch (error) {
      await _logger.warning(
        'Headless WebView не загрузил страницу за 30 секунд; требуется ручная проверка',
        source: url,
      );
      throw CaptchaRequiredException(
        'WebView не загрузил страницу за 30 секунд. Откройте видимый WebView и пройдите проверку сайта.',
        source: url,
        cause: error,
      );
    } on ScrapeException {
      rethrow;
    } catch (error, stackTrace) {
      await _logger.error(
        'Ошибка динамического парсинга',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
      throw ScrapeException(
        'Не удалось извлечь динамическое медиа',
        source: url,
        cause: error,
      );
    }
  }

  Future<List<MediaItem>> extractMediaFromWebView(
    String url,
    InAppWebViewController controller, {
    FilterSettings? filters,
    Set<String> capturedMediaUrls = const <String>{},
  }) async {
    final effectiveFilters = filters ?? const FilterSettings();
    await _logger.info(
      'Динамический парсинг через видимый WebView',
      source: url,
    );

    try {
      final host = Uri.parse(url).host.toLowerCase();
      final items = _isBunkrRelatedHost(host)
          ? await _extractBunkrFromController(
              url,
              controller,
              filters: effectiveFilters,
              capturedMediaUrls: capturedMediaUrls,
            )
          : await _extractRedgifsFromController(
              url,
              controller,
              capturedMediaUrls: capturedMediaUrls,
            );
      final filtered = applyMediaFilters(items, effectiveFilters);
      await _logger.success(
        'Динамический парсинг из видимого WebView завершён: ${filtered.length}',
        source: url,
      );
      return filtered;
    } on TimeoutException catch (error) {
      await _logger.error(
        'Таймаут видимого WebView при извлечении медиа',
        source: url,
        error: error,
      );
      throw ScrapeTimeoutException(
        'Видимый WebView не успел извлечь медиа',
        source: url,
        cause: error,
      );
    } on ScrapeException {
      rethrow;
    } catch (error, stackTrace) {
      await _logger.error(
        'Ошибка парсинга из видимого WebView',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
      throw ScrapeException(
        'Не удалось извлечь медиа из видимого WebView',
        source: url,
        cause: error,
      );
    }
  }

  Future<List<MediaItem>> _extractBunkr(String albumUrl) async {
    final parsedUrl = Uri.parse(albumUrl);
    if (_isBunkrDirectMediaUrl(parsedUrl)) {
      await _logger.info(
        'Bunkr: обработка прямого media URL',
        source: albumUrl,
      );
      final item = await _mediaItemFromUrl(albumUrl, albumUrl);
      return item == null ? const [] : [item];
    }

    if (_isBunkrFilePage(parsedUrl)) {
      await _logger.info(
        'Bunkr: обработка одиночной страницы файла',
        source: albumUrl,
      );
      final item = await _extractBunkrFile(albumUrl);
      return item == null ? const [] : [item];
    }

    final advancedUrl = _bunkrAdvancedAlbumUrl(parsedUrl);
    await _logger.info(
      'Bunkr: загрузка album page с advanced=1',
      source: advancedUrl,
    );

    final linkResult = await _loadAndEvaluate(
      advancedUrl,
      source: r'''
        (async () => {
          const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              if (!value) return;
              try {
                const url = new URL(value, location.href);
                if (/\/(f|i|v|d)\/[A-Za-z0-9_-]+/.test(url.pathname)) {
                  urls.add(url.href);
                }
              } catch (_) {}
            };

            for (const anchor of document.querySelectorAll('a[href]')) {
              add(anchor.getAttribute('href'));
              add(anchor.href);
            }

            const html = document.documentElement.innerHTML;
            const albumFilesMatch = html.match(/window\.albumFiles\s*=\s*(\[[\s\S]*?\]);/);
            if (albumFilesMatch) {
              for (const match of albumFilesMatch[1].matchAll(/slug:\s*["']([^"']+)["']/g)) {
                add(`/f/${match[1]}`);
              }
            }

            return Array.from(urls);
          };

          for (let attempt = 0; attempt < 40; attempt++) {
            const urls = collect();
            if (urls.length > 0) return urls;
            await sleep(500);
          }

          return collect();
        })();
      ''',
    );
    final pageLinks = _asStringList(linkResult).toSet().toList(growable: false);
    await _logger.info(
      'Bunkr: найдено карточек: ${pageLinks.length}',
      source: albumUrl,
    );

    final items = <MediaItem>[];
    for (final pageUrl in pageLinks) {
      final item = await _extractBunkrFile(pageUrl);
      if (item != null) items.add(item);
    }

    await _logger.info(
      'Bunkr: прямых media URL извлечено: ${items.length}',
      source: albumUrl,
    );
    return items;
  }

  Future<List<MediaItem>> _extractBunkrFromController(
    String url,
    InAppWebViewController controller, {
    required FilterSettings filters,
    Set<String> capturedMediaUrls = const <String>{},
  }) async {
    final capturedItems = await _mediaItemsFromUrls(
      capturedMediaUrls,
      url,
      controller,
    );
    final parsedUrl = Uri.parse(url);
    if (_isBunkrDirectMediaUrl(parsedUrl)) {
      final item = await _mediaItemFromUrl(url, url);
      if (item != null) return [item];
      return capturedItems;
    }

    if (_isBunkrFilePage(parsedUrl)) {
      final item = await _extractBunkrFileFromController(
        url,
        controller,
        loadPage: false,
        capturedMediaUrls: capturedMediaUrls,
      );
      return _dedupeMediaItems([...capturedItems, ?item]);
    }

    final advancedUrl = _bunkrAdvancedAlbumUrl(parsedUrl);
    if (!await _controllerMatchesUrl(controller, advancedUrl)) {
      await _loadUrlInController(controller, advancedUrl);
    }

    final candidatesResult = await controller
        .evaluateJavascript(source: _bunkrAlbumCandidatesScript)
        .timeout(_pageTimeout);
    final candidates = _parseBunkrCandidates(candidatesResult, filters);

    await _logger.info(
      'Bunkr: найдено карточек в видимом WebView: ${candidates.length}',
      source: url,
    );

    final items = <MediaItem>[];
    final seenPageUrls = <String>{};
    for (final candidate in candidates) {
      if (!seenPageUrls.add(candidate.url)) continue;

      final item = await _extractBunkrFileFromController(
        candidate.url,
        controller,
        knownSizeBytes: candidate.sizeBytes,
      );
      if (item != null) {
        items.add(item);
        continue;
      }

      if (candidate.directMediaUrl == null) continue;

      final fallbackItem = await _mediaItemFromUrl(
        candidate.directMediaUrl!,
        candidate.url,
        sizeBytes: candidate.sizeBytes,
      );
      if (fallbackItem != null) items.add(fallbackItem);
    }

    await _logger.info(
      'Bunkr: прямых media URL извлечено из видимого WebView: ${items.length}',
      source: url,
    );
    return _dedupeMediaItems([...capturedItems, ...items]);
  }

  Future<MediaItem?> _extractBunkrFileFromController(
    String pageUrl,
    InAppWebViewController controller, {
    bool loadPage = true,
    Set<String> capturedMediaUrls = const <String>{},
    int? knownSizeBytes,
  }) async {
    await _logger.debug(
      'Bunkr: извлечение страницы файла в видимом WebView',
      source: pageUrl,
    );

    if (loadPage) {
      await _loadUrlInController(controller, pageUrl);
    }
    await _waitForBunkrPlayerReady(
      controller,
      pageUrl,
      capturedMediaUrls: capturedMediaUrls,
    );

    final videoResult = await controller
        .evaluateJavascript(source: _bunkrFileMediaScript)
        .timeout(_pageTimeout);
    final hints = await _readBunkrPageHints(controller);
    final mediaUrls = {...capturedMediaUrls, ..._asStringList(videoResult)}
        .map((value) => _bunkrMediaUrlFromCandidate(value, hints))
        .whereType<String>()
        .toSet()
        .toList(growable: false);

    if (mediaUrls.isEmpty) {
      await _logger.warning(
        'Bunkr: media URL не найден в видимом WebView',
        source: pageUrl,
      );
      return null;
    }

    final mediaUrl = await _signBunkrMediaUrl(mediaUrls.first);
    final extension = mediaExtensionFromUrl(mediaUrl);
    if (extension == null) {
      await _logger.warning(
        'Bunkr: неподдерживаемое расширение media URL',
        source: mediaUrl,
      );
      return null;
    }

    final fileName = fileNameFromUrl(mediaUrl);
    var sizeBytes = knownSizeBytes;
    sizeBytes ??= await _readBunkrFileSizeBytes(controller);
    sizeBytes ??= await _readBunkrMediaSizeBytes(mediaUrl, referer: pageUrl);
    return MediaItem(
      url: mediaUrl,
      fileName: fileName,
      extension: extension,
      quality: qualityFromFileName(fileName),
      sourceUrl: pageUrl,
      sizeBytes: sizeBytes,
    );
  }

  Future<MediaItem?> _extractBunkrFile(String pageUrl) async {
    await _logger.debug('Bunkr: открытие страницы файла', source: pageUrl);

    final videoResult = await _loadAndEvaluate(
      pageUrl,
      source: r'''
        (async () => {
          const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();

          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              const text = normalize(value);
              if (!text) return;
              try {
                const url = new URL(text, location.href).href;
                if (/\.(mp4|webm)(\?|$)/i.test(url)) urls.add(url);
              } catch (_) {}
            };

            for (const element of document.querySelectorAll('video, source')) {
              add(element.currentSrc);
              add(element.src);
              add(element.getAttribute('src'));
            }

            for (const anchor of document.querySelectorAll('a[href]')) {
              add(anchor.href);
              add(anchor.getAttribute('href'));
            }

            const html = document.documentElement.innerHTML;
            for (const match of html.matchAll(/https?:\\/\\/[^"'<>\\s]+\.(mp4|webm)[^"'<>\\s]*/gi)) {
              add(match[0]);
            }

            const cdn = html.match(/var\s+jsCDN\s*=\s*["']([^"']+)["']/);
            const slug = html.match(/var\s+jsSlug\s*=\s*["']([^"']+)["']/);
            if (cdn) {
              const cdnValue = normalize(cdn[1]);
              if (/\.(mp4|webm)(\?|$)/i.test(cdnValue)) {
                add(cdnValue);
              } else if (slug) {
                add(`${cdnValue.replace(/\/$/, '')}/storage/media/${normalize(slug[1])}`);
              }
            }

            return Array.from(urls);
          };

          for (let attempt = 0; attempt < 40; attempt++) {
            const urls = collect();
            if (urls.length > 0) return urls;
            await sleep(500);
          }

          return collect();
        })();
      ''',
    );

    final mediaUrls = _asStringList(
      videoResult,
    ).toSet().toList(growable: false);
    if (mediaUrls.isEmpty) {
      await _logger.warning(
        'Bunkr: media URL не найден на странице файла',
        source: pageUrl,
      );
      return null;
    }

    final mediaUrl = await _signBunkrMediaUrl(mediaUrls.first);
    final extension = mediaExtensionFromUrl(mediaUrl);
    if (extension == null) {
      await _logger.warning(
        'Bunkr: неподдерживаемое расширение media URL',
        source: mediaUrl,
      );
      return null;
    }

    final fileName = fileNameFromUrl(mediaUrl);
    final sizeBytes = await _readBunkrMediaSizeBytes(
      mediaUrl,
      referer: pageUrl,
    );
    return MediaItem(
      url: mediaUrl,
      fileName: fileName,
      extension: extension,
      quality: qualityFromFileName(fileName),
      sourceUrl: pageUrl,
      sizeBytes: sizeBytes,
    );
  }

  bool _isBunkrFilePage(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return false;
    return {'f', 'i', 'v', 'd'}.contains(segments.first.toLowerCase());
  }

  bool _isBunkrDirectMediaUrl(Uri uri) {
    if (!_isBunkrRelatedHost(uri.host)) return false;
    final extension = mediaExtensionFromUrl(uri.toString())?.toLowerCase();
    return extension != null && _bunkrMediaExtensions.contains(extension);
  }

  bool _requiresVisibleWebView(String host) {
    return _isBunkrRelatedHost(host) || host.contains('redgifs');
  }

  bool _isBunkrRelatedHost(String host) {
    final normalized = host.toLowerCase();
    return normalized.contains('bunkr') ||
        normalized.endsWith('.cdn.cr') ||
        normalized.contains('gigachad-cdn') ||
        normalized == 'bnkr.b-cdn.net';
  }

  String _bunkrAdvancedAlbumUrl(Uri uri) {
    final nextQuery = Map<String, String>.from(uri.queryParameters);
    nextQuery['advanced'] = '1';
    return uri.replace(queryParameters: nextQuery).toString();
  }

  Future<List<MediaItem>> _extractRedgifs(String url) async {
    final capturedUrls = <String>{};
    final result = await _loadAndEvaluate(
      url,
      onMediaUrl: capturedUrls.add,
      loadFallbackDelay: const Duration(seconds: 6),
      repeatUntilResult: true,
      pollAttempts: 40,
      shouldStopPolling: () => capturedUrls.isNotEmpty,
      source: r'''
        (() => {
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();
          const mediaPattern = /\.(mp4|webm)([?#]|$)/i;

          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              const text = normalize(value);
              if (!text || text.startsWith('blob:')) return;
              try {
                const absoluteUrl = new URL(text, location.href).href;
                if (mediaPattern.test(absoluteUrl)) urls.add(absoluteUrl);
              } catch (_) {}
            };

            for (const element of document.querySelectorAll('video, source')) {
              for (const attr of [
                'currentSrc',
                'src',
                'data-src',
                'data-video-src',
                'data-hd',
                'data-sd',
              ]) {
                add(element[attr]);
                add(element.getAttribute(attr));
              }

              if (element.tagName.toLowerCase() === 'video') {
                try {
                  element.muted = true;
                  element.preload = 'auto';
                  element.setAttribute('playsinline', '');
                  element.load?.();
                  const promise = element.play?.();
                  if (promise && typeof promise.catch === 'function') {
                    promise.catch(() => {});
                  }
                } catch (_) {}
              }
            }

            for (const element of document.querySelectorAll('[src], [href]')) {
              add(element.getAttribute('src'));
              add(element.getAttribute('href'));
              add(element.src);
              add(element.href);
            }

            for (const entry of performance.getEntriesByType('resource')) {
              add(entry.name);
            }

            const html = document.documentElement.innerHTML;
            for (const match of html.matchAll(/https?:\\/\\/[^"'<>\\s]+\.(mp4|webm)[^"'<>\\s]*/gi)) {
              add(match[0]);
            }

            return Array.from(urls);
          };

          try { window.scrollBy(0, Math.max(1, window.innerHeight / 2)); } catch (_) {}
          return collect();
        })();
      ''',
    );

    final mediaUrls = {
      ...capturedUrls,
      ..._asStringList(result).map(_normalizeEscapedUrl),
    }.where(_isSupportedVideoUrl).toList(growable: false);

    mediaUrls.sort(_compareRedgifsMediaUrls);

    await _logger.info(
      'RedGifs: прямых media URL найдено: ${mediaUrls.length}',
      source: url,
    );

    return mediaUrls
        .map((mediaUrl) {
          final extension = mediaExtensionFromUrl(mediaUrl) ?? 'mp4';
          final fileName = fileNameFromUrl(mediaUrl);
          return MediaItem(
            url: mediaUrl,
            fileName: fileName,
            extension: extension,
            quality: qualityFromFileName(fileName),
            sourceUrl: url,
          );
        })
        .toList(growable: false);
  }

  Future<List<MediaItem>> _extractRedgifsFromController(
    String url,
    InAppWebViewController controller, {
    required Set<String> capturedMediaUrls,
  }) async {
    if (!await _controllerMatchesUrl(controller, url)) {
      await _loadUrlInController(controller, url);
    }

    dynamic lastResult;
    final pollStartedAt = DateTime.now();
    for (var attempt = 0; attempt < 40; attempt++) {
      if (capturedMediaUrls.isNotEmpty) break;

      final remaining = _remainingPollTimeout(pollStartedAt);
      lastResult = await controller
          .evaluateJavascript(source: _redgifsMediaScript)
          .timeout(remaining);

      if (_asStringList(lastResult).isNotEmpty) break;

      if (attempt < 39) {
        final pause = _minDuration(
          const Duration(milliseconds: 500),
          _remainingPollTimeout(pollStartedAt),
        );
        await Future<void>.delayed(pause);
      }
    }

    final mediaUrls = {
      ...capturedMediaUrls,
      ..._asStringList(lastResult).map(_normalizeEscapedUrl),
    }.where(_isSupportedVideoUrl).toList(growable: false);

    mediaUrls.sort(_compareRedgifsMediaUrls);

    await _logger.info(
      'RedGifs: прямых media URL найдено в видимом WebView: ${mediaUrls.length}',
      source: url,
    );

    return mediaUrls
        .map((mediaUrl) {
          final extension = mediaExtensionFromUrl(mediaUrl) ?? 'mp4';
          final fileName = fileNameFromUrl(mediaUrl);
          return MediaItem(
            url: mediaUrl,
            fileName: fileName,
            extension: extension,
            quality: qualityFromFileName(fileName),
            sourceUrl: url,
          );
        })
        .toList(growable: false);
  }

  List<_BunkrPageCandidate> _parseBunkrCandidates(
    dynamic value,
    FilterSettings filters,
  ) {
    dynamic decoded = value;
    if (value is String && value.isNotEmpty) {
      decoded = jsonDecode(value);
    }
    if (decoded is! List) return const [];

    final candidates = <_BunkrPageCandidate>[];
    for (final entry in decoded) {
      String? url;
      String? extension;
      String? directMediaUrl;
      int? sizeBytes;

      if (entry is String) {
        url = entry;
      } else if (entry is Map) {
        url = entry['url']?.toString();
        extension = _extensionFromHint(entry['extension']?.toString());
        directMediaUrl = entry['directUrl']?.toString();
        sizeBytes = _parseSizeBytes(entry['size']);
      }

      if (url == null || url.isEmpty) continue;
      if (extension != null && !filters.acceptsExtension(extension)) continue;
      if (!filters.acceptsSize(sizeBytes)) continue;

      candidates.add(
        _BunkrPageCandidate(
          url: url,
          extension: extension,
          sizeBytes: sizeBytes,
          directMediaUrl:
              directMediaUrl != null && _isSupportedVideoUrl(directMediaUrl)
              ? directMediaUrl
              : null,
        ),
      );
    }

    return candidates;
  }

  String? _extensionFromHint(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.toLowerCase().replaceFirst('.', '').trim();
    if (normalized.contains('mp4')) return 'mp4';
    if (normalized.contains('webm')) return 'webm';
    if (normalized.contains('jpeg')) return 'jpeg';
    if (normalized.contains('jpg')) return 'jpg';
    if (normalized.contains('png')) return 'png';
    if (normalized.contains('gif')) return 'gif';
    if (normalized.contains('webp')) return 'webp';
    return null;
  }

  Future<int?> _readBunkrFileSizeBytes(
    InAppWebViewController controller,
  ) async {
    try {
      final result = await controller
          .evaluateJavascript(
            source: r'''
              (() => {
                const text = document.body?.innerText || '';
                const html = document.documentElement?.innerHTML || '';
                const source = `${text}\n${html}`;
                const patterns = [
                  /(?:size|file size|filesize)\s*[:\-]?\s*([0-9]+(?:[\.,][0-9]+)?\s*(?:b|kb|mb|gb|tb|kib|mib|gib|tib))/i,
                  /([0-9]+(?:[\.,][0-9]+)?\s*(?:kb|mb|gb|tb|kib|mib|gib|tib))/i
                ];
                for (const pattern of patterns) {
                  const match = source.match(pattern);
                  if (match) return match[1];
                }
                return '';
              })();
            ''',
          )
          .timeout(_pageTimeout);
      return _parseSizeBytes(result);
    } catch (_) {
      return null;
    }
  }

  int? _parseSizeBytes(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    final plainNumber = int.tryParse(text);
    if (plainNumber != null) return plainNumber;

    final match = RegExp(
      r'([0-9]+(?:[\.,][0-9]+)?)\s*(tb|tib|gb|gib|mb|mib|kb|kib|b)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;

    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (amount == null) return null;

    final unit = match.group(2)!.toLowerCase();
    final multiplier = switch (unit) {
      'tb' || 'tib' => 1024 * 1024 * 1024 * 1024,
      'gb' || 'gib' => 1024 * 1024 * 1024,
      'mb' || 'mib' => 1024 * 1024,
      'kb' || 'kib' => 1024,
      _ => 1,
    };
    return (amount * multiplier).round();
  }

  Future<int?> _readBunkrMediaSizeBytes(
    String mediaUrl, {
    String? referer,
  }) async {
    final normalized = _normalizeEscapedUrl(mediaUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !_isBunkrMediaUrl(uri)) return null;

    try {
      final response =
          await Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: _bunkrMediaHeaders(referer),
            ),
          ).headUri<void>(
            uri,
            options: Options(
              followRedirects: true,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
            ),
          );

      return _sizeBytesFromHeaders(response.headers);
    } catch (_) {
      return null;
    }
  }

  bool _isBunkrMediaUrl(Uri uri) {
    if (!_isBunkrRelatedHost(uri.host)) return false;
    final extension = mediaExtensionFromUrl(uri.toString())?.toLowerCase();
    return extension != null && _bunkrMediaExtensions.contains(extension);
  }

  Map<String, String> _bunkrMediaHeaders(String? referer) {
    final refererUri = referer == null ? null : Uri.tryParse(referer);
    final origin = refererUri != null && refererUri.hasScheme
        ? '${refererUri.scheme}://${refererUri.host}'
        : 'https://bunkr.cr';

    return {
      'user-agent': _desktopUserAgent,
      'accept': '*/*',
      'referer': referer ?? '$origin/',
      'origin': origin,
    };
  }

  int? _sizeBytesFromHeaders(Headers headers) {
    final contentLength = int.tryParse(
      headers.value('content-length')?.trim() ?? '',
    );
    if (contentLength != null && contentLength >= 0) return contentLength;

    final contentRange = headers.value('content-range');
    if (contentRange == null) return null;

    final match = RegExp(r'/(\d+)\s*$').firstMatch(contentRange);
    final sizeBytes = int.tryParse(match?.group(1) ?? '');
    return sizeBytes != null && sizeBytes >= 0 ? sizeBytes : null;
  }

  Future<MediaItem?> _mediaItemFromUrl(
    String mediaUrl,
    String sourceUrl, {
    int? sizeBytes,
  }) async {
    final signedUrl = await _signBunkrMediaUrl(mediaUrl);
    final extension = mediaExtensionFromUrl(signedUrl);
    if (extension == null) return null;

    final fileName = fileNameFromUrl(signedUrl);
    var resolvedSizeBytes = sizeBytes;
    resolvedSizeBytes ??= await _readBunkrMediaSizeBytes(
      signedUrl,
      referer: sourceUrl,
    );
    return MediaItem(
      url: signedUrl,
      fileName: fileName,
      extension: extension,
      quality: qualityFromFileName(fileName),
      sourceUrl: sourceUrl,
      sizeBytes: resolvedSizeBytes,
    );
  }

  Future<String> _signBunkrMediaUrl(String rawUrl) async {
    final normalized = _normalizeEscapedUrl(rawUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !_isSupportedVideoUrl(normalized)) return normalized;

    try {
      final response =
          await Dio(
            BaseOptions(
              connectTimeout: _pageTimeout,
              receiveTimeout: _pageTimeout,
              headers: {'user-agent': _desktopUserAgent},
            ),
          ).getUri<Map<String, dynamic>>(
            Uri.https('glb-apisign.cdn.cr', '/sign', {'path': uri.path}),
          );

      final data = response.data;
      final token = data?['token']?.toString();
      final ex = data?['ex']?.toString();
      if (token == null || token.isEmpty || ex == null || ex.isEmpty) {
        return normalized;
      }

      final nextQuery = Map<String, String>.from(uri.queryParameters);
      nextQuery['token'] = token;
      nextQuery['ex'] = ex;
      return uri.replace(queryParameters: nextQuery).toString();
    } catch (error) {
      await _logger.warning(
        'Bunkr: не удалось подписать media URL, использую исходный',
        source: normalized,
      );
      return normalized;
    }
  }

  Future<List<MediaItem>> _mediaItemsFromUrls(
    Iterable<String> urls,
    String sourceUrl,
    InAppWebViewController controller,
  ) async {
    final hints = await _readBunkrPageHints(controller);
    final items = <MediaItem>[];

    for (final rawUrl in urls) {
      final mediaUrl = _bunkrMediaUrlFromCandidate(rawUrl, hints);
      if (mediaUrl == null) continue;

      final item = await _mediaItemFromUrl(mediaUrl, sourceUrl);
      if (item != null) items.add(item);
    }

    return _dedupeMediaItems(items);
  }

  Future<_BunkrPageHints> _readBunkrPageHints(
    InAppWebViewController controller,
  ) async {
    try {
      final result = await controller
          .evaluateJavascript(
            source: r'''
              (() => {
                const normalize = (value) => String(value || '')
                  .replace(/\\u002F/g, '/')
                  .replace(/\\\//g, '/')
                  .trim();
                const html = document.documentElement?.innerHTML || '';
                const cdnMatch = html.match(/var\s+jsCDN\s*=\s*["']([^"']+)["']/);
                const coverMatch = html.match(/https?:\/\/i-[^"'<\s]+\/thumbs\/[^"'<\s]+/i);
                const poster = document.querySelector('video[poster], img[src*="/thumbs/"]');
                return JSON.stringify({
                  cdn: normalize(window.jsCDN || (cdnMatch && cdnMatch[1]) || ''),
                  cover: normalize(window.videoCoverUrl || poster?.poster || poster?.src || (coverMatch && coverMatch[0]) || ''),
                });
              })();
            ''',
          )
          .timeout(_pageTimeout);
      final hints = _asStringMap(result);
      return _BunkrPageHints(cdn: hints['cdn'], cover: hints['cover']);
    } catch (_) {
      return const _BunkrPageHints();
    }
  }

  String? _bunkrMediaUrlFromCandidate(String rawUrl, _BunkrPageHints hints) {
    final normalized = _normalizeEscapedUrl(rawUrl);
    if (_isSupportedVideoUrl(normalized)) return normalized;
    return _bunkrMediaUrlFromSignUrl(normalized, hints);
  }

  String? _bunkrMediaUrlFromSignUrl(String rawUrl, _BunkrPageHints hints) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host.toLowerCase() != 'glb-apisign.cdn.cr') {
      return null;
    }

    final mediaPath = uri.queryParameters['path'];
    if (mediaPath == null || !_isSupportedVideoPath(mediaPath)) return null;

    final cdn = _normalizeEscapedUrl(hints.cdn ?? '');
    final cdnUri = Uri.tryParse(cdn);
    if (cdnUri != null && cdnUri.hasScheme && cdnUri.host.isNotEmpty) {
      if (_isSupportedVideoUrl(cdnUri.toString())) return cdnUri.toString();
      return _urlWithPath(cdnUri, mediaPath);
    }

    final cover = _normalizeEscapedUrl(hints.cover ?? '');
    final coverUri = Uri.tryParse(cover);
    if (coverUri != null && coverUri.hasScheme && coverUri.host.isNotEmpty) {
      final host = coverUri.host.replaceFirst(RegExp(r'^i-'), '');
      return _urlWithPath(coverUri.replace(host: host), mediaPath);
    }

    return null;
  }

  String _urlWithPath(Uri baseUri, String path) {
    return Uri(
      scheme: baseUri.scheme,
      userInfo: baseUri.userInfo,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: path,
    ).toString();
  }

  bool _isSupportedVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.webm');
  }

  bool _isBunkrMediaCandidate(String rawUrl) {
    final normalized = _normalizeEscapedUrl(rawUrl);
    return _isSupportedVideoUrl(normalized) ||
        _bunkrSignPath(normalized) != null;
  }

  String? _bunkrSignPath(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host.toLowerCase() != 'glb-apisign.cdn.cr') {
      return null;
    }
    final path = uri.queryParameters['path'];
    return path != null && _isSupportedVideoPath(path) ? path : null;
  }

  List<MediaItem> _dedupeMediaItems(Iterable<MediaItem> items) {
    final seen = <String>{};
    final result = <MediaItem>[];
    for (final item in items) {
      if (seen.add(_mediaItemDedupeKey(item))) result.add(item);
    }
    return result;
  }

  String _mediaItemDedupeKey(MediaItem item) {
    final uri = Uri.tryParse(item.url);
    if (uri == null || !_isBunkrRelatedHost(uri.host)) return item.url;
    return uri.replace(query: '').toString();
  }

  Future<bool> _controllerMatchesUrl(
    InAppWebViewController controller,
    String expectedUrl,
  ) async {
    final currentUrl = await controller.getUrl();
    if (currentUrl == null) return false;
    return _sameWebViewPage(currentUrl.toString(), expectedUrl);
  }

  Future<void> _loadUrlInController(
    InAppWebViewController controller,
    String url,
  ) async {
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    await _waitForControllerReady(controller, url);
  }

  Future<void> _waitForControllerReady(
    InAppWebViewController controller,
    String expectedUrl,
  ) async {
    final startedAt = DateTime.now();

    while (true) {
      final currentUrl = await controller.getUrl();
      final reached =
          currentUrl != null &&
          _sameWebViewPage(currentUrl.toString(), expectedUrl);

      if (reached) {
        final readyState = await controller.evaluateJavascript(
          source: 'document.readyState',
        );
        if (readyState == 'interactive' || readyState == 'complete') {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return;
        }
      }

      if (DateTime.now().difference(startedAt) >= _pageTimeout) {
        throw TimeoutException(
          'Visible WebView did not load $expectedUrl',
          _pageTimeout,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _waitForBunkrPlayerReady(
    InAppWebViewController controller,
    String pageUrl, {
    Set<String> capturedMediaUrls = const <String>{},
  }) async {
    final startedAt = DateTime.now();
    final hasCapturedMedia = capturedMediaUrls.any(_isBunkrMediaCandidate);

    while (true) {
      try {
        final result = await controller
            .evaluateJavascript(
              source: r'''
                (() => {
                  const html = document.documentElement?.innerHTML || '';
                  const resources = performance.getEntriesByType('resource')
                    .map((entry) => String(entry.name || ''));
                  const hasMediaUrl = Boolean(
                    document.querySelector('video[src], source[src]') ||
                    /glb-apisign\.cdn\.cr\/sign\?path=/i.test(html) ||
                    /\.(mp4|webm)(\?|["'\s<]|$)/i.test(html) ||
                    resources.some((url) =>
                      /glb-apisign\.cdn\.cr\/sign\?path=/i.test(url) ||
                      /\.(mp4|webm)(\?|$)/i.test(url)
                    )
                  );
                  const hasHints = Boolean(
                    window.jsCDN ||
                    window.videoCoverUrl ||
                    /var\s+jsCDN\s*=/.test(html) ||
                    /https?:\/\/i-[^"'<\s]+\/thumbs\//i.test(html)
                  );

                  return JSON.stringify({
                    ready: document.readyState === 'complete' || document.readyState === 'interactive',
                    hasMediaUrl,
                    hasHints,
                  });
                })();
              ''',
            )
            .timeout(_remainingPollTimeout(startedAt));

        final state = _asStringMap(result);
        final ready = state['ready'] == 'true';
        final hasMediaUrl = state['hasMediaUrl'] == 'true';
        final hasHints = state['hasHints'] == 'true';
        if (ready && (hasMediaUrl || (hasCapturedMedia && hasHints))) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return;
        }
      } catch (_) {
        // Во время редиректа/challenge WebView может временно не выполнять JS.
        // Продолжаем ждать до общего таймаута страницы.
      }

      if (DateTime.now().difference(startedAt) >= _pageTimeout) {
        await _logger.warning(
          'Bunkr: плеер не загрузился за ${_pageTimeout.inSeconds} секунд, пробую извлечь media URL как есть',
          source: pageUrl,
        );
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  bool _sameWebViewPage(String currentUrl, String expectedUrl) {
    final current = Uri.tryParse(currentUrl);
    final expected = Uri.tryParse(expectedUrl);
    if (current == null || expected == null) return currentUrl == expectedUrl;
    if (current.host.toLowerCase() != expected.host.toLowerCase()) return false;
    if (current.path != expected.path) return false;
    if (expected.queryParameters['advanced'] == '1') {
      return current.queryParameters['advanced'] == '1';
    }
    return true;
  }

  Future<dynamic> _loadAndEvaluate(
    String url, {
    required String source,
    void Function(String url)? onMediaUrl,
    Duration? loadFallbackDelay,
    bool repeatUntilResult = false,
    int pollAttempts = 1,
    Duration pollInterval = const Duration(milliseconds: 500),
    bool Function()? shouldStopPolling,
  }) async {
    HeadlessInAppWebView? webView;
    final loaded = Completer<void>();

    void captureMediaUrl(String? value) {
      if (onMediaUrl == null || value == null) return;

      final normalized = _normalizeEscapedUrl(value);
      if (_isSupportedVideoUrl(normalized)) {
        onMediaUrl(normalized);
      }
    }

    webView = HeadlessInAppWebView(
      initialSize: const Size(1280, 720),
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        isInspectable: kDebugMode,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        userAgent: _desktopUserAgent,
        useOnLoadResource: onMediaUrl != null,
        useOnDownloadStart: onMediaUrl != null,
        useShouldInterceptRequest: onMediaUrl != null,
        useShouldInterceptAjaxRequest: onMediaUrl != null,
        useShouldInterceptFetchRequest: onMediaUrl != null,
      ),
      onLoadStop: (controller, loadedUrl) async {
        if (!loaded.isCompleted) loaded.complete();
      },
      onLoadResource: onMediaUrl == null
          ? null
          : (controller, resource) {
              captureMediaUrl(resource.url?.toString());
            },
      onDownloadStarting: onMediaUrl == null
          ? null
          : (controller, downloadStartRequest) async {
              captureMediaUrl(downloadStartRequest.url.toString());
              return null;
            },
      shouldInterceptRequest: onMediaUrl == null
          ? null
          : (controller, request) async {
              captureMediaUrl(request.url.toString());
              return null;
            },
      shouldInterceptAjaxRequest: onMediaUrl == null
          ? null
          : (controller, ajaxRequest) async {
              captureMediaUrl(ajaxRequest.url?.toString());
              captureMediaUrl(ajaxRequest.responseURL?.toString());
              return ajaxRequest;
            },
      shouldInterceptFetchRequest: onMediaUrl == null
          ? null
          : (controller, fetchRequest) async {
              captureMediaUrl(fetchRequest.url?.toString());
              return fetchRequest;
            },
      onReceivedError: (controller, request, error) async {
        if (request.isForMainFrame == false) {
          return;
        }
        if (!loaded.isCompleted) {
          loaded.completeError(
            CaptchaRequiredException(
              'WebView получил ошибку загрузки. Требуется ручная проверка сайта.',
              source: request.url.toString(),
              cause: ScrapeException(
                error.description,
                source: request.url.toString(),
              ),
            ),
          );
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) async {
        if (request.isForMainFrame == false) {
          return;
        }

        if (_isProtectionStatusCode(errorResponse.statusCode) &&
            !loaded.isCompleted) {
          loaded.completeError(
            CaptchaRequiredException(
              'WebView получил HTTP ${errorResponse.statusCode}. Требуется ручная проверка сайта.',
              source: request.url.toString(),
            ),
          );
        }
      },
    );

    try {
      await webView.run();
      final loadFuture = loaded.future.timeout(_pageTimeout);
      if (loadFallbackDelay == null) {
        await loadFuture;
      } else {
        await Future.any<void>([
          loadFuture,
          Future<void>.delayed(loadFallbackDelay),
        ]);
      }

      final controller = webView.webViewController;
      if (controller == null) {
        throw ScrapeException('WebView controller недоступен', source: url);
      }

      final captchaMarker = await controller.evaluateJavascript(
        source: r'''
          (() => /captcha|cf-challenge|turnstile/i.test(document.body?.innerText || document.documentElement.innerHTML))();
        ''',
      );
      if (captchaMarker == true || captchaMarker == 'true') {
        throw CaptchaRequiredException(
          'Требуется ручное решение капчи',
          source: url,
        );
      }

      if (!repeatUntilResult) {
        return controller
            .evaluateJavascript(source: source)
            .timeout(_pageTimeout);
      }

      dynamic lastResult;
      final pollStartedAt = DateTime.now();
      for (var attempt = 0; attempt < pollAttempts; attempt++) {
        if (shouldStopPolling?.call() == true) {
          return lastResult ?? const <String>[];
        }

        final remaining = _remainingPollTimeout(pollStartedAt);
        lastResult = await controller
            .evaluateJavascript(source: source)
            .timeout(remaining);

        if (_asStringList(lastResult).isNotEmpty) {
          return lastResult;
        }

        if (attempt < pollAttempts - 1) {
          final pause = _minDuration(
            pollInterval,
            _remainingPollTimeout(pollStartedAt),
          );
          await Future<void>.delayed(pause);
        }
      }

      return lastResult;
    } finally {
      await webView.dispose();
    }
  }

  String _normalizeEscapedUrl(String url) {
    return url.replaceAll(r'\u002F', '/').replaceAll(r'\/', '/').trim();
  }

  bool _isSupportedVideoUrl(String url) {
    final extension = mediaExtensionFromUrl(url);
    return extension == 'mp4' || extension == 'webm';
  }

  bool _isProtectionStatusCode(int? statusCode) {
    final code = statusCode ?? 0;
    return code == 403 ||
        code == 429 ||
        code == 503 ||
        (code >= 520 && code <= 524);
  }

  Duration _remainingPollTimeout(DateTime startedAt) {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _pageTimeout - elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('WebView polling timed out', _pageTimeout);
    }
    return remaining;
  }

  Duration _minDuration(Duration left, Duration right) {
    return left <= right ? left : right;
  }

  int _compareRedgifsMediaUrls(String left, String right) {
    final leftRank = _redgifsMediaRank(left);
    final rightRank = _redgifsMediaRank(right);
    if (leftRank != rightRank) return leftRank.compareTo(rightRank);
    return left.compareTo(right);
  }

  int _redgifsMediaRank(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('-mobile.')) return 3;
    if (lower.contains('sd.')) return 2;
    return 1;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.isNotEmpty) return [value];
    return const [];
  }

  Map<String, String> _asStringMap(dynamic value) {
    dynamic decoded = value;
    if (value is String && value.isNotEmpty) {
      try {
        decoded = jsonDecode(value);
      } catch (_) {
        return const {};
      }
    }

    if (decoded is! Map) return const {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
}

class _BunkrPageCandidate {
  const _BunkrPageCandidate({
    required this.url,
    this.extension,
    this.sizeBytes,
    this.directMediaUrl,
  });

  final String url;
  final String? extension;
  final int? sizeBytes;
  final String? directMediaUrl;
}

class _BunkrPageHints {
  const _BunkrPageHints({this.cdn, this.cover});

  final String? cdn;
  final String? cover;
}
