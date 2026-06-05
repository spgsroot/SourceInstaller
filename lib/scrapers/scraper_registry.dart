import '../services/logger_service.dart';
import 'base_scraper.dart';
import 'dynamic_webview_scraper.dart';
import 'reddit_scraper.dart';
import 'static_board_scraper.dart';

class ScraperRegistry {
  ScraperRegistry({LoggerService? logger})
    : scrapers = [
        RedditScraper(logger: logger),
        StaticBoardScraper(logger: logger),
        DynamicWebViewScraper(logger: logger),
      ];

  final List<BaseScraper> scrapers;

  BaseScraper forUrl(String url) => selectScraper(url, scrapers);
}
