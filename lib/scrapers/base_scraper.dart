import '../errors/scrape_exception.dart';
import '../models/filter_settings.dart';
import '../models/media_item.dart';

abstract class BaseScraper {
  bool canHandle(String url);

  Future<List<MediaItem>> extractMedia(String url, {FilterSettings? filters});
}

BaseScraper selectScraper(String url, List<BaseScraper> scrapers) {
  for (final scraper in scrapers) {
    if (scraper.canHandle(url)) return scraper;
  }

  throw ScrapeException('Нет парсера для URL', source: url);
}
