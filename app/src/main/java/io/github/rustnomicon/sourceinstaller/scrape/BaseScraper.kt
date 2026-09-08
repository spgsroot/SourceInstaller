package io.github.rustnomicon.sourceinstaller.scrape

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.errors.ScrapeException

interface BaseScraper {
    fun canHandle(url: String): Boolean

    suspend fun extractMedia(url: String, filters: FilterSettings = FilterSettings()): List<MediaItem>
}

fun selectScraper(url: String, scrapers: List<BaseScraper>): BaseScraper {
    for (scraper in scrapers) {
        if (scraper.canHandle(url)) return scraper
    }
    throw ScrapeException("Нет парсера для URL", source = url)
}
