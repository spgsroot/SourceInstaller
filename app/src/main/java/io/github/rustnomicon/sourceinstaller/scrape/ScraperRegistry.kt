package io.github.rustnomicon.sourceinstaller.scrape

import io.github.rustnomicon.sourceinstaller.service.LoggerService

class ScraperRegistry(
    logger: LoggerService = LoggerService.getInstance(),
    val scrapers: List<BaseScraper> = listOf(
        RedditScraper(logger = logger),
        StaticBoardScraper(logger = logger),
        DynamicWebViewScraper(logger = logger),
    ),
) {
    fun forUrl(url: String): BaseScraper = selectScraper(url, scrapers)
}
