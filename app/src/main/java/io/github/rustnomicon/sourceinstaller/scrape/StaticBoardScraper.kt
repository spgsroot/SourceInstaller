package io.github.rustnomicon.sourceinstaller.scrape

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.errors.ScrapeException
import io.github.rustnomicon.sourceinstaller.errors.ScrapeTimeoutException
import io.github.rustnomicon.sourceinstaller.net.HTML_ACCEPT
import io.github.rustnomicon.sourceinstaller.net.HttpClients
import io.github.rustnomicon.sourceinstaller.service.LoggerService
import java.io.IOException
import java.net.URI
import java.net.SocketTimeoutException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.jsoup.Jsoup

/**
 * Parses anchors on static textboard/imageboard HTML pages
 * (2ch, 4chan/4channel, Lainchan, Endchan).
 *
 * Port of the Flutter `StaticBoardScraper`.
 */
class StaticBoardScraper(
    private val client: OkHttpClient = HttpClients.scraper,
    private val logger: LoggerService = LoggerService.getInstance(),
) : BaseScraper {

    override fun canHandle(url: String): Boolean {
        val host = BunkrSupport.hostOf(url)?.lowercase() ?: return false
        return host.contains("2ch") ||
            host.contains("4chan") ||
            host.contains("boards.4channel") ||
            host.contains("lainchan") ||
            host.contains("endchan")
    }

    override suspend fun extractMedia(
        url: String,
        filters: FilterSettings,
    ): List<MediaItem> = withContext(Dispatchers.IO) {
        logger.info("Начало статического парсинга", source = url)

        try {
            val request = Request.Builder()
                .url(url)
                .header("Accept", HTML_ACCEPT)
                .build()
            val html = client.newCall(request).execute().use { response ->
                response.body?.string().orEmpty()
            }
            val document = Jsoup.parse(html, url)
            val baseUri = URI(url)
            val seen = LinkedHashSet<String>()
            val items = mutableListOf<MediaItem>()

            for (anchor in document.select("a[href]")) {
                val rawHref = anchor.attr("href")
                if (rawHref.isEmpty()) continue

                val absoluteUrl = try {
                    baseUri.resolve(rawHref).toString()
                } catch (_: Exception) {
                    continue
                }
                if (!seen.add(absoluteUrl)) continue

                val extension = mediaExtensionFromUrl(absoluteUrl) ?: continue

                val fileName = fileNameFromUrl(absoluteUrl)
                items += MediaItem(
                    url = absoluteUrl,
                    fileName = fileName,
                    extension = extension,
                    quality = qualityFromFileName(fileName),
                    sourceUrl = url,
                )
            }

            val filtered = applyMediaFilters(items, filters)
            logger.success("Найдено медиа: ${filtered.size}", source = url)
            filtered
        } catch (error: SocketTimeoutException) {
            logger.error("Таймаут статического парсинга", source = url, error = error)
            throw ScrapeTimeoutException(
                "Статический парсинг превысил 15 секунд",
                source = url,
                cause = error,
            )
        } catch (error: IOException) {
            logger.error("Ошибка HTTP при статическом парсинге", source = url, error = error)
            throw ScrapeException("Не удалось загрузить HTML", source = url, cause = error)
        } catch (error: Exception) {
            if (error is ScrapeException) throw error
            logger.error("Ошибка статического парсинга", source = url, error = error)
            throw ScrapeException("Не удалось извлечь медиа из HTML", source = url, cause = error)
        }
    }
}
