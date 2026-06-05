import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../errors/scrape_exception.dart';
import '../models/filter_settings.dart';
import '../models/media_item.dart';
import '../services/logger_service.dart';
import 'base_scraper.dart';
import 'media_helpers.dart';

class RedditScraper implements BaseScraper {
  RedditScraper({Dio? dio, LoggerService? logger})
    : _logger = logger ?? LoggerService.instance,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              followRedirects: true,
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                    'AppleWebKit/537.36 (KHTML, like Gecko) '
                    'Chrome/125.0.0.0 Safari/537.36',
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              },
            ),
          );

  final Dio _dio;
  final LoggerService _logger;

  static const _webViewTimeout = Duration(seconds: 30);

  @override
  bool canHandle(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'redd.it' ||
        host.endsWith('.reddit.com') ||
        host == 'reddit.com' ||
        host == 'i.redd.it' ||
        host == 'preview.redd.it' ||
        host == 'v.redd.it' ||
        host == 'packaged-media.redd.it';
  }

  @override
  Future<List<MediaItem>> extractMedia(
    String url, {
    FilterSettings? filters,
  }) async {
    final effectiveFilters = filters ?? const FilterSettings();
    await _logger.info('Reddit: начало парсинга', source: url);

    try {
      final direct = _directMediaItem(url, sourceUrl: url);
      if (direct != null) {
        final filtered = applyMediaFilters([direct], effectiveFilters);
        await _logger.success(
          'Reddit: прямое media URL найдено: ${filtered.length}',
          source: url,
        );
        return filtered;
      }

      if (_isRedditShareUrl(url)) {
        await _logger.warning(
          'Reddit: короткая /s/ ссылка требует видимый WebView',
          source: url,
        );
        throw CaptchaRequiredException(
          'Reddit /s/ ссылка открывается через видимый WebView.',
          source: url,
        );
      }

      final jsonItems = await _extractItemsFromJsonEndpoint(url);
      if (jsonItems.isNotEmpty) {
        final filtered = applyMediaFilters(jsonItems, effectiveFilters);
        await _logger.success(
          'Reddit: найдено медиа через JSON: ${filtered.length}',
          source: url,
        );
        return filtered;
      }

      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final sourceUrl = response.realUri.toString();
      final html = _normalizeEscapedHtml(response.data ?? '');

      final htmlItems = _extractItemsFromHtml(html, sourceUrl);
      final redirectedJsonItems = await _extractItemsFromJsonEndpoint(
        sourceUrl,
      );
      final items = _dedupeByFile([...htmlItems, ...redirectedJsonItems])
          .where((item) => effectiveFilters.acceptsExtension(item.extension))
          .where((item) => effectiveFilters.acceptsSize(item.sizeBytes))
          .toList(growable: false);

      await _logger.success(
        'Reddit: найдено медиа: ${items.length}',
        source: sourceUrl,
      );
      return items;
    } on DioException catch (error, stackTrace) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        await _logger.error(
          'Reddit: таймаут парсинга',
          source: url,
          error: error,
        );
        throw ScrapeTimeoutException(
          'Reddit не ответил вовремя',
          source: url,
          cause: error,
        );
      }

      await _logger.error(
        'Reddit: ошибка HTTP при парсинге',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
      if (error.response?.statusCode == 403 ||
          error.response?.statusCode == 429) {
        throw CaptchaRequiredException(
          'Reddit заблокировал статический запрос. Откройте видимый WebView.',
          source: url,
          cause: error,
        );
      }
      throw ScrapeException(
        'Не удалось загрузить Reddit HTML',
        source: url,
        cause: error,
      );
    } on ScrapeException {
      rethrow;
    } catch (error, stackTrace) {
      await _logger.error(
        'Reddit: ошибка парсинга',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
      throw ScrapeException(
        'Не удалось извлечь Reddit media',
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
    await _logger.info('Reddit: парсинг через видимый WebView', source: url);

    final currentUrl = (await controller.getUrl())?.toString();
    final sourceUrl = currentUrl == null || currentUrl.isEmpty
        ? url
        : currentUrl;
    final result = await controller
        .evaluateJavascript(source: _webViewCollectorScript)
        .timeout(_webViewTimeout);
    final html = await _readHtmlFromWebView(controller);
    final urls = {...capturedMediaUrls, ..._asStringList(result)};
    final directItems = urls
        .map((mediaUrl) => _directMediaItem(mediaUrl, sourceUrl: sourceUrl))
        .whereType<MediaItem>()
        .toList(growable: false);
    final htmlItems = _extractItemsFromHtml(
      _normalizeEscapedHtml(html),
      sourceUrl,
    );
    final jsonItems = await _extractItemsFromJsonEndpoint(sourceUrl);

    final items = _dedupeByFile([...directItems, ...htmlItems, ...jsonItems])
        .where((item) => effectiveFilters.acceptsExtension(item.extension))
        .where((item) => effectiveFilters.acceptsSize(item.sizeBytes))
        .toList(growable: false);

    await _logger.success(
      'Reddit: найдено медиа в видимом WebView: ${items.length}',
      source: url,
    );
    return items;
  }

  Future<String> _readHtmlFromWebView(InAppWebViewController controller) async {
    try {
      final result = await controller
          .evaluateJavascript(
            source: 'document.documentElement?.innerHTML || "";',
          )
          .timeout(_webViewTimeout);
      return result?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  List<MediaItem> _extractItemsFromHtml(String html, String sourceUrl) {
    final seen = <String>{};
    final items = <MediaItem>[];

    void add(String? rawUrl) {
      if (rawUrl == null || rawUrl.isEmpty) return;
      final cleaned = _cleanUrl(rawUrl);
      if (cleaned == null || !seen.add(cleaned)) return;

      final item = _directMediaItem(cleaned, sourceUrl: sourceUrl);
      if (item != null) items.add(item);
    }

    for (final pattern in _mediaUrlPatterns) {
      for (final match in pattern.allMatches(html)) {
        add(match.group(0));
      }
    }

    for (final pattern in _encodedMediaUrlPatterns) {
      for (final match in pattern.allMatches(html)) {
        final encoded = match.group(1) ?? match.group(0);
        if (encoded == null) continue;
        add(Uri.decodeFull(encoded));
      }
    }

    for (final videoId in _extractVRedditIds(html)) {
      // Best-effort fallback. If Reddit embedded JSON did not include
      // fallback_url, this commonly exists for uploaded videos. It is video-only
      // when Reddit stores audio separately in DASH/HLS.
      add('https://v.redd.it/$videoId/DASH_720.mp4?source=fallback');
    }

    items.sort(_compareRedditItems);
    return _dedupeByFile(items);
  }

  List<String> _asStringList(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList(growable: false);
        }
      } catch (_) {
        return [value];
      }
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }

  Future<List<MediaItem>> _extractItemsFromJsonEndpoint(
    String sourceUrl,
  ) async {
    final jsonUrl = _jsonEndpointFor(sourceUrl);
    if (jsonUrl == null) return const [];

    try {
      final response = await _dio.get<dynamic>(
        jsonUrl,
        options: Options(
          responseType: ResponseType.json,
          headers: const {'Accept': 'application/json,text/plain,*/*'},
        ),
      );
      final submission = _submissionFromListing(response.data);
      if (submission == null) return const [];

      final items = <MediaItem>[];
      items.addAll(_extractItemsFromSubmission(submission, sourceUrl));

      final crossposts = submission['crosspost_parent_list'];
      if (crossposts is List) {
        for (final crosspost in crossposts) {
          if (crosspost is Map) {
            items.addAll(_extractItemsFromSubmission(crosspost, sourceUrl));
          }
        }
      }

      return _dedupeByFile(items);
    } catch (error) {
      await _logger.debug(
        'Reddit: JSON fallback недоступен: $error',
        source: jsonUrl,
      );
      return const [];
    }
  }

  Map<String, dynamic>? _submissionFromListing(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    if (data is! List || data.isEmpty) return null;
    final listing = data.first;
    if (listing is! Map) return null;
    final listingData = listing['data'];
    if (listingData is! Map) return null;
    final children = listingData['children'];
    if (children is! List || children.isEmpty) return null;
    final child = children.first;
    if (child is! Map) return null;
    final submission = child['data'];
    if (submission is! Map) return null;
    return submission.cast<String, dynamic>();
  }

  List<MediaItem> _extractItemsFromSubmission(
    Map submission,
    String sourceUrl,
  ) {
    final items = <MediaItem>[];

    void add(String? value) {
      if (value == null || value.isEmpty) return;
      final item = _directMediaItem(value, sourceUrl: sourceUrl);
      if (item != null) items.add(item);
    }

    add(submission['url_overridden_by_dest']?.toString());
    add(submission['url']?.toString());

    _extractRedditVideoUrls(submission['secure_media']).forEach(add);
    _extractRedditVideoUrls(submission['media']).forEach(add);

    final preview = submission['preview'];
    if (preview is Map) {
      final images = preview['images'];
      if (images is List) {
        for (final image in images) {
          if (image is! Map) continue;
          final source = image['source'];
          if (source is Map) add(source['url']?.toString());
          final variants = image['variants'];
          if (variants is Map) {
            for (final variant in variants.values) {
              if (variant is! Map) continue;
              final variantSource = variant['source'];
              if (variantSource is Map) add(variantSource['url']?.toString());
            }
          }
        }
      }
    }

    final metadata = submission['media_metadata'];
    if (metadata is Map) {
      for (final entry in metadata.values) {
        if (entry is! Map) continue;
        if (entry['status'] != null && entry['status'] != 'valid') continue;

        final source = entry['s'];
        if (source is Map) {
          add(source['u']?.toString());
          add(source['gif']?.toString());
          add(source['mp4']?.toString());
        }
        add(entry['hlsUrl']?.toString());
        add(entry['dashUrl']?.toString());
      }
    }

    return _dedupeByFile(items);
  }

  Iterable<String> _extractRedditVideoUrls(dynamic media) sync* {
    if (media is! Map) return;
    final redditVideo = media['reddit_video'];
    if (redditVideo is! Map) return;

    final fallbackUrl = redditVideo['fallback_url']?.toString();
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      yield fallbackUrl;
      return;
    }

    final dashUrl = redditVideo['dash_url']?.toString();
    final videoId =
        _videoIdFromManifestUrl(dashUrl) ??
        _videoIdFromManifestUrl(redditVideo['hls_url']?.toString());
    final height = redditVideo['height']?.toString();
    if (videoId != null) {
      yield 'https://v.redd.it/$videoId/DASH_${height ?? '720'}.mp4?source=fallback';
    }
  }

  String? _videoIdFromManifestUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(_cleanUrl(value) ?? value);
    if (uri == null || uri.host.toLowerCase() != 'v.redd.it') return null;
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }

  String? _jsonEndpointFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();

    if (host == 'redd.it') {
      final shortSegments = uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .toList();
      final id = shortSegments.isEmpty ? null : shortSegments.first;
      if (id == null) return null;
      return _commentsJsonUrl(id);
    }

    if (host != 'reddit.com' && !host.endsWith('.reddit.com')) return null;

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    final commentsIndex = segments.indexOf('comments');
    if (commentsIndex != -1 && commentsIndex + 1 < segments.length) {
      final postId = segments[commentsIndex + 1];
      return _commentsJsonUrl(postId);
    }

    final galleryIndex = segments.indexOf('gallery');
    if (galleryIndex != -1 && galleryIndex + 1 < segments.length) {
      final postId = segments[galleryIndex + 1];
      return _commentsJsonUrl(postId);
    }

    return null;
  }

  String _commentsJsonUrl(String postId) {
    return Uri.https('www.reddit.com', '/comments/$postId/.json', {
      'raw_json': '1',
    }).toString();
  }

  bool _isRedditShareUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host != 'reddit.com' && !host.endsWith('.reddit.com')) return false;

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment.toLowerCase())
        .toList(growable: false);
    final shareIndex = segments.indexOf('s');
    return shareIndex != -1 && shareIndex + 1 < segments.length;
  }

  MediaItem? _directMediaItem(String rawUrl, {required String sourceUrl}) {
    final url = _normalizePreviewUrl(_cleanUrl(rawUrl) ?? rawUrl);
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final extension = mediaExtensionFromUrl(url);
    if (host == 'v.redd.it' && extension == null) {
      final videoId = _firstPathSegment(uri);
      if (videoId == null) return null;
      return _directMediaItem(
        'https://v.redd.it/$videoId/DASH_720.mp4?source=fallback',
        sourceUrl: sourceUrl,
      );
    }
    if (extension == null) return null;

    final isRedditMedia =
        host == 'i.redd.it' ||
        host == 'preview.redd.it' ||
        host == 'v.redd.it' ||
        host == 'packaged-media.redd.it';
    if (!isRedditMedia) return null;

    final fileName = fileNameFromUrl(url);
    return MediaItem(
      url: url,
      fileName: fileName,
      extension: extension,
      quality: qualityFromFileName(fileName) ?? _qualityFromRedditUrl(url),
      sourceUrl: sourceUrl,
    );
  }

  String? _firstPathSegment(Uri uri) {
    for (final segment in uri.pathSegments) {
      if (segment.isNotEmpty) return segment;
    }
    return null;
  }

  String _normalizeEscapedHtml(String html) {
    return html
        .replaceAll('&amp;', '&')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u003d', '=')
        .replaceAll(r'\u003D', '=')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\/', '/');
  }

  String? _cleanUrl(String rawUrl) {
    final normalized = rawUrl
        .replaceAll('&amp;', '&')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u003d', '=')
        .replaceAll(r'\u003D', '=')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\/', '/')
        .trim();
    final trimmed = normalized.replaceAll(RegExp(r'[),.;\]}]+$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri.toString();
  }

  String _normalizePreviewUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host.toLowerCase() != 'preview.redd.it') return url;

    // Reddit preview URLs often include transient resizing/query params. The
    // original image is usually available on i.redd.it with the same path.
    return uri.replace(host: 'i.redd.it', query: '').toString();
  }

  Set<String> _extractVRedditIds(String html) {
    return RegExp(
      r'https?://v\.redd\.it/([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).allMatches(html).map((match) => match.group(1)!).toSet();
  }

  String? _qualityFromRedditUrl(String url) {
    final match = RegExp(
      r'DASH_(\d{3,4})\.mp4',
      caseSensitive: false,
    ).firstMatch(url);
    final height = match?.group(1);
    return height == null ? null : '${height}p';
  }

  int _compareRedditItems(MediaItem left, MediaItem right) {
    final leftRank = _redditRank(left.url);
    final rightRank = _redditRank(right.url);
    if (leftRank != rightRank) return leftRank.compareTo(rightRank);
    return left.url.compareTo(right.url);
  }

  int _redditRank(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('dash_1080')) return 1;
    if (lower.contains('dash_720')) return 2;
    if (lower.contains('dash_480')) return 3;
    if (lower.contains('packaged-media.redd.it')) return 4;
    if (lower.contains('v.redd.it')) return 5;
    if (lower.contains('i.redd.it')) return 6;
    return 7;
  }

  List<MediaItem> _dedupeByFile(List<MediaItem> items) {
    final seen = <String>{};
    final result = <MediaItem>[];
    for (final item in items) {
      final key = item.url.contains('v.redd.it/')
          ? Uri.tryParse(item.url)?.pathSegments.take(1).join('/') ?? item.url
          : item.url;
      if (seen.add(key)) result.add(item);
    }
    return result;
  }

  static final _mediaUrlPatterns = <RegExp>[
    RegExp(
      r'''https?://(?:i|preview)\.redd\.it/[^\s"\'<>\\)]+''',
      caseSensitive: false,
    ),
    RegExp(
      r'''https?://v\.redd\.it/[A-Za-z0-9_-]+/DASH_\d+\.mp4[^\s"\'<>\\)]*''',
      caseSensitive: false,
    ),
    RegExp(
      r'''https?://packaged-media\.redd\.it/[^\s"\'<>\\)]+\.mp4[^\s"\'<>\\)]*''',
      caseSensitive: false,
    ),
  ];

  static final _encodedMediaUrlPatterns = <RegExp>[
    RegExp(
      r'''(https%3A%2F%2F(?:i|preview)\.redd\.it%2F[^\s"\'<>\\)]+)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''(https%3A%2F%2Fv\.redd\.it%2F[A-Za-z0-9_-]+%2FDASH_\d+\.mp4[^\s"\'<>\\)]*)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''url=(https%3A%2F%2F(?:i|preview|v|packaged-media)\.redd\.it[^\s"\'<>\\)&]+)''',
      caseSensitive: false,
    ),
  ];

  static const _webViewCollectorScript = r'''
    (() => {
      const urls = new Set();
      const normalize = (value) => String(value || '')
        .replace(/&amp;/g, '&')
        .replace(/\\u0026/g, '&')
        .replace(/\\u003[dD]/g, '=')
        .replace(/\\u002F/g, '/')
        .replace(/\\\//g, '/')
        .trim();
      const add = (value) => {
        const text = normalize(value);
        if (!text) return;
        try {
          const url = new URL(text, location.href).href;
          if (/https?:\/\/(i|preview|v|packaged-media)\.redd\.it\//i.test(url)) {
            urls.add(url);
          }
        } catch (_) {}
      };
      const scanRoot = (root) => {
        if (!root || !root.querySelectorAll) return;
        for (const el of root.querySelectorAll('video, source, img, a, shreddit-post, shreddit-player-2')) {
          for (const attr of ['src', 'href', 'currentSrc', 'poster', 'content', 'data-src']) {
            add(el[attr]);
            add(el.getAttribute?.(attr));
          }
          if (el.shadowRoot) scanRoot(el.shadowRoot);
        }
      };
      scanRoot(document);
      for (const entry of performance.getEntriesByType('resource')) add(entry.name);
      const html = document.documentElement?.innerHTML || '';
      for (const match of html.matchAll(/https?:\/\/(?:i|preview|v|packaged-media)\.redd\.it\/[^"'<>\\\s)]+/gi)) add(match[0]);
      for (const match of html.matchAll(/https%3A%2F%2F(?:i|preview|v|packaged-media)\.redd\.it%2F[^"'<>\\\s)]+/gi)) {
        try { add(decodeURIComponent(match[0])); } catch (_) {}
      }
      return JSON.stringify(Array.from(urls));
    })();
  ''';
}
