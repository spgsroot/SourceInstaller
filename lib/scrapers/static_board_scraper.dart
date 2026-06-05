import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../errors/scrape_exception.dart';
import '../models/filter_settings.dart';
import '../models/media_item.dart';
import '../services/logger_service.dart';
import 'base_scraper.dart';
import 'media_helpers.dart';

class StaticBoardScraper implements BaseScraper {
  StaticBoardScraper({Dio? dio, LoggerService? logger})
    : _logger = logger ?? LoggerService.instance,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              followRedirects: true,
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                    'AppleWebKit/537.36 (KHTML, like Gecko) '
                    'Chrome/125.0.0.0 Safari/537.36',
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              },
            ),
          );

  final Dio _dio;
  final LoggerService _logger;

  @override
  bool canHandle(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('2ch') ||
        host.contains('4chan') ||
        host.contains('boards.4channel') ||
        host.contains('lainchan') ||
        host.contains('endchan');
  }

  @override
  Future<List<MediaItem>> extractMedia(
    String url, {
    FilterSettings? filters,
  }) async {
    final effectiveFilters = filters ?? const FilterSettings();
    await _logger.info('Начало статического парсинга', source: url);

    try {
      final response = await _dio.get<String>(url);
      final document = html_parser.parse(response.data ?? '');
      final baseUri = Uri.parse(url);
      final seen = <String>{};
      final items = <MediaItem>[];

      for (final anchor in document.querySelectorAll('a[href]')) {
        final rawHref = anchor.attributes['href'];
        if (rawHref == null || rawHref.isEmpty) continue;

        final absoluteUrl = baseUri.resolve(rawHref).toString();
        if (!seen.add(absoluteUrl)) continue;

        final extension = mediaExtensionFromUrl(absoluteUrl);
        if (extension == null || !videoExtensions.contains(extension)) continue;

        final fileName = fileNameFromUrl(absoluteUrl);
        items.add(
          MediaItem(
            url: absoluteUrl,
            fileName: fileName,
            extension: extension,
            quality: qualityFromFileName(fileName),
            sourceUrl: url,
          ),
        );
      }

      final filtered = applyMediaFilters(items, effectiveFilters);
      await _logger.success('Найдено медиа: ${filtered.length}', source: url);
      return filtered;
    } on DioException catch (error, stackTrace) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        await _logger.error(
          'Таймаут статического парсинга',
          source: url,
          error: error,
        );
        throw ScrapeTimeoutException(
          'Статический парсинг превысил 15 секунд',
          source: url,
          cause: error,
        );
      }

      await _logger.error(
        'Ошибка HTTP при статическом парсинге',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
      throw ScrapeException(
        'Не удалось загрузить HTML',
        source: url,
        cause: error,
      );
    } catch (error, stackTrace) {
      await _logger.error(
        'Ошибка статического парсинга',
        source: url,
        error: error,
        stackTrace: stackTrace,
      );
      throw ScrapeException(
        'Не удалось извлечь медиа из HTML',
        source: url,
        cause: error,
      );
    }
  }
}
