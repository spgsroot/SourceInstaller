package io.github.rustnomicon.sourceinstaller.scrape

import android.webkit.WebView
import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.errors.CaptchaRequiredException
import io.github.rustnomicon.sourceinstaller.errors.ScrapeException
import io.github.rustnomicon.sourceinstaller.errors.ScrapeTimeoutException
import io.github.rustnomicon.sourceinstaller.scrape.BunkrSupport.pathSegments
import io.github.rustnomicon.sourceinstaller.scrape.webview.MediaUrlCapture
import io.github.rustnomicon.sourceinstaller.scrape.webview.WEBVIEW_PAGE_TIMEOUT_MS
import io.github.rustnomicon.sourceinstaller.scrape.webview.decodeJsString
import io.github.rustnomicon.sourceinstaller.scrape.webview.evaluateJs
import io.github.rustnomicon.sourceinstaller.service.LoggerService
import java.util.concurrent.TimeoutException
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive

/**
 * Dynamic scraper for protected sources (Bunkr, Redgifs). These sites sit
 * behind anti-bot walls, so analysis always runs through a visible WebView
 * hosted by the challenge card in the UI.
 *
 * Port of the Flutter `DynamicWebViewScraper`. The dead headless flows from
 * the Dart version (unreachable because [extractMedia] always demanded a
 * visible WebView for every host it handles) were dropped during the port.
 */
class DynamicWebViewScraper(
    private val logger: LoggerService = LoggerService.getInstance(),
) : BaseScraper {

    override fun canHandle(url: String): Boolean {
        val host = BunkrSupport.hostOf(url)?.lowercase() ?: return false
        return BunkrSupport.isBunkrRelatedHost(host) || host.contains("redgifs")
    }

    override suspend fun extractMedia(
        url: String,
        filters: FilterSettings,
    ): List<MediaItem> {
        logger.info("RedGifs/Bunkr: сразу открываю видимый WebView", source = url)
        throw CaptchaRequiredException(
            "Для RedGifs и Bunkr используется видимый WebView.",
            source = url,
        )
    }

    /** Extraction using the already-loaded visible WebView from the challenge card. */
    suspend fun extractMediaFromWebView(
        url: String,
        webView: WebView,
        filters: FilterSettings = FilterSettings(),
        capturedMediaUrls: Set<String> = emptySet(),
    ): List<MediaItem> {
        logger.info("Динамический парсинг через видимый WebView", source = url)

        try {
            val host = BunkrSupport.hostOf(url)?.lowercase().orEmpty()
            val items = if (BunkrSupport.isBunkrRelatedHost(host)) {
                extractBunkrFromController(
                    url,
                    webView,
                    filters = filters,
                    capturedMediaUrls = capturedMediaUrls,
                )
            } else {
                extractRedgifsFromController(
                    url,
                    webView,
                    capturedMediaUrls = capturedMediaUrls,
                )
            }
            val filtered = applyMediaFilters(items, filters)
            logger.success(
                "Динамический парсинг из видимого WebView завершён: ${filtered.size}",
                source = url,
            )
            return filtered
        } catch (error: ScrapeException) {
            throw error
        } catch (error: TimeoutException) {
            logger.error("Таймаут видимого WebView при извлечении медиа", source = url, error = error)
            throw ScrapeTimeoutException(
                "Видимый WebView не успел извлечь медиа",
                source = url,
                cause = error,
            )
        } catch (error: TimeoutCancellationException) {
            logger.error("Таймаут видимого WebView при извлечении медиа", source = url, error = error)
            throw ScrapeTimeoutException(
                "Видимый WebView не успел извлечь медиа",
                source = url,
                cause = error,
            )
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            logger.error("Ошибка парсинга из видимого WebView", source = url, error = error)
            throw ScrapeException(
                "Не удалось извлечь медиа из видимого WebView",
                source = url,
                cause = error,
            )
        }
    }

    private suspend fun extractBunkrFromController(
        url: String,
        webView: WebView,
        filters: FilterSettings,
        capturedMediaUrls: Set<String> = emptySet(),
    ): List<MediaItem> {
        val hints = readBunkrPageHints(webView)
        val capturedItems = mediaItemsFromUrls(capturedMediaUrls, url, hints)
        val parsedUrl = BunkrSupport.parseUri(url)

        if (parsedUrl != null && BunkrSupport.isBunkrMediaUrl(parsedUrl)) {
            logger.info("Bunkr: обработка прямого media URL", source = url)
            val item = mediaItemFromUrl(url, url)
            return if (item != null) listOf(item) else capturedItems
        }

        if (parsedUrl != null && isBunkrFilePage(parsedUrl)) {
            val item = extractBunkrFileFromController(
                url,
                webView,
                loadPage = false,
                capturedMediaUrls = capturedMediaUrls,
            )
            return dedupeMediaItems(capturedItems + listOfNotNull(item))
        }

        logger.info("Bunkr: загрузка album page с advanced=1", source = url)
        val advancedUrl = BunkrSupport.bunkrAdvancedAlbumUrl(url)
        if (!controllerMatchesUrl(webView, advancedUrl)) {
            loadUrlInController(webView, advancedUrl)
        }

        val candidatesResult = webView.evaluateJs(ScraperScripts.BUNKR_ALBUM_CANDIDATES)
        val candidates = parseBunkrCandidates(candidatesResult, filters)

        logger.info(
            "Bunkr: найдено карточек в видимом WebView: ${candidates.size}",
            source = url,
        )

        val items = mutableListOf<MediaItem>()
        val seenPageUrls = LinkedHashSet<String>()
        for (candidate in candidates) {
            if (!seenPageUrls.add(candidate.url)) continue

            val item = extractBunkrFileFromController(
                candidate.url,
                webView,
                knownSizeBytes = candidate.sizeBytes,
            )
            if (item != null) {
                items += item
                continue
            }

            val directMediaUrl = candidate.directMediaUrl ?: continue
            val fallbackItem = mediaItemFromUrl(
                directMediaUrl,
                candidate.url,
                sizeBytes = candidate.sizeBytes,
            )
            if (fallbackItem != null) items += fallbackItem
        }

        logger.info(
            "Bunkr: прямых media URL извлечено из видимого WebView: ${items.size}",
            source = url,
        )
        return dedupeMediaItems(capturedItems + items)
    }

    private suspend fun extractBunkrFileFromController(
        pageUrl: String,
        webView: WebView,
        loadPage: Boolean = true,
        capturedMediaUrls: Set<String> = emptySet(),
        knownSizeBytes: Long? = null,
    ): MediaItem? {
        logger.debug("Bunkr: извлечение страницы файла в видимом WebView", source = pageUrl)

        if (loadPage) {
            loadUrlInController(webView, pageUrl)
        }
        waitForBunkrPlayerReady(webView, pageUrl, capturedMediaUrls)

        val videoResult = webView.evaluateJs(ScraperScripts.BUNKR_FILE_MEDIA)
        val hints = readBunkrPageHints(webView)
        val mediaUrls = (capturedMediaUrls + asStringList(videoResult))
            .mapNotNull { bunkrMediaUrlFromCandidate(it, hints) }
            .distinct()

        if (mediaUrls.isEmpty()) {
            logger.warning("Bunkr: media URL не найден в видимом WebView", source = pageUrl)
            return null
        }

        val mediaUrl = BunkrSupport.signBunkrMediaUrl(mediaUrls.first())
        val extension = mediaExtensionFromUrl(mediaUrl)
        if (extension == null) {
            logger.warning("Bunkr: неподдерживаемое расширение media URL", source = mediaUrl)
            return null
        }

        val fileName = fileNameFromUrl(mediaUrl)
        var sizeBytes = knownSizeBytes
        if (sizeBytes == null) sizeBytes = readBunkrFileSizeBytes(webView)
        if (sizeBytes == null) sizeBytes = BunkrSupport.readBunkrMediaSizeBytes(mediaUrl, referer = pageUrl)
        return MediaItem(
            url = mediaUrl,
            fileName = fileName,
            extension = extension,
            quality = qualityFromFileName(fileName),
            sourceUrl = pageUrl,
            sizeBytes = sizeBytes,
        )
    }

    private suspend fun extractRedgifsFromController(
        url: String,
        webView: WebView,
        capturedMediaUrls: Set<String>,
    ): List<MediaItem> {
        // The challenge card may have navigated mid-check; reload if the
        // WebView no longer shows the requested page.
        if (!controllerMatchesUrl(webView, url)) {
            loadUrlInController(webView, url)
        }

        var lastResult: String? = null
        val pollStartedAt = System.currentTimeMillis()
        for (attempt in 0 until 40) {
            if (capturedMediaUrls.isNotEmpty()) break

            val remaining = remainingPollTimeout(pollStartedAt)
            lastResult = webView.evaluateJs(ScraperScripts.REDGIFS_MEDIA, timeoutMs = remaining)
            if (asStringList(lastResult).isNotEmpty()) break

            if (attempt < 39) {
                delay(minOf(500L, remainingPollTimeout(pollStartedAt)))
            }
        }

        val mediaUrls = (
            capturedMediaUrls +
                asStringList(lastResult).map(BunkrSupport::normalizeEscapedUrl)
            )
            .filter(BunkrSupport::isSupportedVideoUrl)
            .sortedWith(::compareRedgifsMediaUrls)

        logger.info(
            "RedGifs: прямых media URL найдено в видимом WebView: ${mediaUrls.size}",
            source = url,
        )

        return mediaUrls.map { mediaUrl ->
            val extension = mediaExtensionFromUrl(mediaUrl) ?: "mp4"
            val fileName = fileNameFromUrl(mediaUrl)
            MediaItem(
                url = mediaUrl,
                fileName = fileName,
                extension = extension,
                quality = qualityFromFileName(fileName),
                sourceUrl = url,
            )
        }
    }

    internal fun parseBunkrCandidates(
        value: String?,
        filters: FilterSettings,
    ): List<BunkrPageCandidate> {
        val decoded = decodeJsString(value) ?: return emptyList()
        if (decoded.isEmpty()) return emptyList()

        val list = try {
            JSON.parseToJsonElement(decoded) as? JsonArray
        } catch (_: Exception) {
            null
        } ?: return emptyList()

        val candidates = mutableListOf<BunkrPageCandidate>()
        for (entry in list) {
            var url: String? = null
            var extension: String? = null
            var directMediaUrl: String? = null
            var sizeBytes: Long? = null

            when (entry) {
                is JsonPrimitive -> url = entry.content
                is JsonObject -> {
                    url = entry.primitiveContent("url")
                    extension = extensionFromHint(entry.primitiveContent("extension"))
                    directMediaUrl = entry.primitiveContent("directUrl")
                    sizeBytes = parseSizeBytes(entry["size"])
                }
                else -> Unit
            }

            if (url.isNullOrEmpty()) continue
            if (extension != null && !filters.acceptsExtension(extension)) continue
            if (!filters.acceptsSize(sizeBytes)) continue

            candidates += BunkrPageCandidate(
                url = url,
                extension = extension,
                sizeBytes = sizeBytes,
                directMediaUrl = directMediaUrl?.takeIf(BunkrSupport::isSupportedVideoUrl),
            )
        }

        return candidates
    }

    internal fun extensionFromHint(value: String?): String? {
        if (value.isNullOrBlank()) return null
        val normalized = value.lowercase().removePrefix(".").trim()
        return when {
            normalized.contains("mp4") -> "mp4"
            normalized.contains("webm") -> "webm"
            normalized.contains("jpeg") -> "jpg"
            normalized.contains("jpg") -> "jpg"
            normalized.contains("png") -> "png"
            normalized.contains("gif") -> "gif"
            normalized.contains("webp") -> "webp"
            else -> null
        }
    }

    private suspend fun readBunkrFileSizeBytes(webView: WebView): Long? {
        return try {
            val result = webView.evaluateJs(ScraperScripts.BUNKR_FILE_SIZE_TEXT)
            parseSizeBytes(decodeJsString(result))
        } catch (_: TimeoutCancellationException) {
            // Not a user cancellation: treat a slow page as "size unknown".
            null
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            null
        }
    }

    internal fun parseSizeBytes(value: Any?): Long? {
        if (value == null) return null
        if (value is Number) return value.toLong()
        if (value is JsonPrimitive) {
            if (value.isString) return parseSizeBytes(value.content)
            return value.content.toLongOrNull()
        }

        val text = value.toString().trim().lowercase()
        if (text.isEmpty()) return null
        text.toLongOrNull()?.let { return it }

        val match = SIZE_WITH_UNIT.find(text) ?: return null
        val amount = match.groupValues[1].replace(',', '.').toDoubleOrNull() ?: return null
        val multiplier = when (match.groupValues[2].lowercase()) {
            "tb", "tib" -> 1024.0 * 1024 * 1024 * 1024
            "gb", "gib" -> 1024.0 * 1024 * 1024
            "mb", "mib" -> 1024.0 * 1024
            "kb", "kib" -> 1024.0
            else -> 1.0
        }
        return (amount * multiplier).toLong()
    }

    private suspend fun mediaItemFromUrl(
        mediaUrl: String,
        sourceUrl: String,
        sizeBytes: Long? = null,
    ): MediaItem? {
        val signedUrl = BunkrSupport.signBunkrMediaUrl(mediaUrl)
        val extension = mediaExtensionFromUrl(signedUrl) ?: return null

        val fileName = fileNameFromUrl(signedUrl)
        var resolvedSizeBytes = sizeBytes
        if (resolvedSizeBytes == null) {
            resolvedSizeBytes = BunkrSupport.readBunkrMediaSizeBytes(signedUrl, referer = sourceUrl)
        }
        return MediaItem(
            url = signedUrl,
            fileName = fileName,
            extension = extension,
            quality = qualityFromFileName(fileName),
            sourceUrl = sourceUrl,
            sizeBytes = resolvedSizeBytes,
        )
    }

    private suspend fun mediaItemsFromUrls(
        urls: Collection<String>,
        sourceUrl: String,
        hints: BunkrPageHints,
    ): List<MediaItem> {
        val items = mutableListOf<MediaItem>()
        for (rawUrl in urls) {
            val mediaUrl = bunkrMediaUrlFromCandidate(rawUrl, hints) ?: continue
            val item = mediaItemFromUrl(mediaUrl, sourceUrl)
            if (item != null) items += item
        }
        return dedupeMediaItems(items)
    }

    private suspend fun readBunkrPageHints(webView: WebView): BunkrPageHints {
        return try {
            val result = webView.evaluateJs(ScraperScripts.BUNKR_PAGE_HINTS)
            val decoded = decodeJsString(result) ?: return BunkrPageHints()
            val map = try {
                JSON.parseToJsonElement(decoded) as? JsonObject
            } catch (_: Exception) {
                null
            } ?: return BunkrPageHints()
            BunkrPageHints(
                cdn = map.primitiveContent("cdn")?.ifEmpty { null },
                cover = map.primitiveContent("cover")?.ifEmpty { null },
            )
        } catch (error: CancellationException) {
            if (error is TimeoutCancellationException) BunkrPageHints() else throw error
        } catch (_: Exception) {
            BunkrPageHints()
        }
    }

    internal fun bunkrMediaUrlFromCandidate(rawUrl: String, hints: BunkrPageHints): String? {
        val normalized = BunkrSupport.normalizeEscapedUrl(rawUrl)
        if (BunkrSupport.isSupportedVideoUrl(normalized)) return normalized
        return bunkrMediaUrlFromSignUrl(normalized, hints)
    }

    private fun bunkrMediaUrlFromSignUrl(rawUrl: String, hints: BunkrPageHints): String? {
        val uri = BunkrSupport.parseUri(rawUrl) ?: return null
        if ((uri.host ?: "").lowercase() != "glb-apisign.cdn.cr") return null

        val mediaPath = BunkrSupport.bunkrSignPath(rawUrl) ?: return null

        val cdn = BunkrSupport.normalizeEscapedUrl(hints.cdn.orEmpty())
        val cdnUri = BunkrSupport.parseUri(cdn)
        if (cdnUri != null && cdnUri.scheme != null && !cdnUri.host.isNullOrEmpty()) {
            if (BunkrSupport.isSupportedVideoUrl(cdnUri.toString())) return cdnUri.toString()
            return urlWithPath(cdnUri, mediaPath)
        }

        val cover = BunkrSupport.normalizeEscapedUrl(hints.cover.orEmpty())
        val coverUri = BunkrSupport.parseUri(cover)
        if (coverUri != null && coverUri.scheme != null && !coverUri.host.isNullOrEmpty()) {
            val host = coverUri.host.replace(Regex("^i-"), "")
            val destUri = try {
                java.net.URI(coverUri.scheme, coverUri.userInfo, host, coverUri.port, null, null, null)
            } catch (_: Exception) {
                return null
            }
            return urlWithPath(destUri, mediaPath)
        }

        return null
    }

    private fun urlWithPath(baseUri: java.net.URI, path: String): String = try {
        java.net.URI(
            baseUri.scheme, baseUri.userInfo, baseUri.host, baseUri.port, path, null, null,
        ).toString()
    } catch (_: Exception) {
        baseUri.toString()
    }

    private fun isBunkrFilePage(uri: java.net.URI): Boolean {
        val first = uri.pathSegments().firstOrNull() ?: return false
        return first.lowercase() in setOf("f", "i", "v", "d")
    }

    internal fun isBunkrMediaCandidate(rawUrl: String): Boolean {
        val normalized = BunkrSupport.normalizeEscapedUrl(rawUrl)
        return BunkrSupport.isSupportedVideoUrl(normalized) ||
            BunkrSupport.bunkrSignPath(normalized) != null
    }

    private fun dedupeMediaItems(items: List<MediaItem>): List<MediaItem> {
        val seen = LinkedHashSet<String>()
        val result = mutableListOf<MediaItem>()
        for (item in items) {
            if (seen.add(BunkrSupport.mediaItemDedupeKey(item.url))) result += item
        }
        return result
    }

    private suspend fun controllerMatchesUrl(webView: WebView, expectedUrl: String): Boolean {
        val currentUrl = withContext(Dispatchers.Main) { webView.url } ?: return false
        return sameWebViewPage(currentUrl, expectedUrl)
    }

    private suspend fun loadUrlInController(webView: WebView, url: String) {
        withContext(Dispatchers.Main) { webView.loadUrl(url) }
        waitForControllerReady(webView, url)
    }

    private suspend fun waitForControllerReady(webView: WebView, expectedUrl: String) {
        val startedAt = System.currentTimeMillis()

        while (true) {
            val currentUrl = withContext(Dispatchers.Main) { webView.url }
            val reached = currentUrl != null && sameWebViewPage(currentUrl, expectedUrl)

            if (reached) {
                val readyState = decodeJsString(
                    webView.evaluateJs("document.readyState"),
                )
                if (readyState == "interactive" || readyState == "complete") {
                    delay(500)
                    return
                }
            }

            if (System.currentTimeMillis() - startedAt >= WEBVIEW_PAGE_TIMEOUT_MS) {
                throw TimeoutException("Visible WebView did not load $expectedUrl")
            }

            delay(250)
        }
    }

    private suspend fun waitForBunkrPlayerReady(
        webView: WebView,
        pageUrl: String,
        capturedMediaUrls: Set<String> = emptySet(),
    ) {
        val startedAt = System.currentTimeMillis()
        val hasCapturedMedia = capturedMediaUrls.any(::isBunkrMediaCandidate)

        while (true) {
            try {
                val result = webView.evaluateJs(ScraperScripts.BUNKR_PLAYER_READY_PROBE)
                val state = decodeJsString(result)
                    ?.let {
                        try {
                            JSON.parseToJsonElement(it) as? JsonObject
                        } catch (_: Exception) {
                            null
                        }
                    }
                val ready = state?.primitiveContent("ready") == "true"
                val hasMediaUrl = state?.primitiveContent("hasMediaUrl") == "true"
                val hasHints = state?.primitiveContent("hasHints") == "true"
                if (ready && (hasMediaUrl || (hasCapturedMedia && hasHints))) {
                    delay(800)
                    return
                }
            } catch (error: CancellationException) {
                if (error is TimeoutCancellationException) {
                    // JS eval ran past the polling budget; the wall-clock check
                    // below will exit the loop on the next iteration.
                } else {
                    throw error
                }
            } catch (_: Exception) {
                // During redirect/challenge the WebView may briefly refuse to
                // run JS; keep waiting until the overall page timeout.
            }

            if (System.currentTimeMillis() - startedAt >= WEBVIEW_PAGE_TIMEOUT_MS) {
                logger.warning(
                    "Bunkr: плеер не загрузился за ${WEBVIEW_PAGE_TIMEOUT_MS / 1000} секунд, пробую извлечь media URL как есть",
                    source = pageUrl,
                )
                return
            }

            delay(250)
        }
    }

    internal fun sameWebViewPage(currentUrl: String, expectedUrl: String): Boolean {
        val current = BunkrSupport.parseUri(currentUrl)
        val expected = BunkrSupport.parseUri(expectedUrl)
        if (current == null || expected == null) return currentUrl == expectedUrl
        if (!(current.host ?: "").equals(expected.host ?: "", ignoreCase = true)) return false
        if (current.path != expected.path) return false
        if (BunkrSupport.queryParam(expected, "advanced") == "1") {
            return BunkrSupport.queryParam(current, "advanced") == "1"
        }
        return true
    }

    internal fun compareRedgifsMediaUrls(left: String, right: String): Int {
        val leftRank = redgifsMediaRank(left)
        val rightRank = redgifsMediaRank(right)
        if (leftRank != rightRank) return leftRank.compareTo(rightRank)
        return left.compareTo(right)
    }

    internal fun redgifsMediaRank(url: String): Int {
        val lower = url.lowercase()
        if (lower.contains("-mobile.")) return 3
        if (lower.contains("sd.")) return 2
        return 1
    }

    internal fun asStringList(value: String?): List<String> = decodeStringListHelper(value)

    private fun remainingPollTimeout(startedAtMillis: Long): Long {
        val elapsed = System.currentTimeMillis() - startedAtMillis
        val remaining = WEBVIEW_PAGE_TIMEOUT_MS - elapsed
        if (remaining <= 0) throw TimeoutException("WebView polling timed out")
        return remaining
    }

    private fun JsonObject.primitiveContent(key: String): String? =
        (this[key] as? JsonPrimitive)
            ?.takeUnless { it is kotlinx.serialization.json.JsonNull }
            ?.content

    companion object {
        private val JSON = Json { ignoreUnknownKeys = true }
        private val SIZE_WITH_UNIT = Regex(
            """([0-9]+(?:[\.,][0-9]+)?)\s*(tb|tib|gb|gib|mb|mib|kb|kib|b)""",
            RegexOption.IGNORE_CASE,
        )

        internal fun decodeStringListHelper(result: String?): List<String> {
            val decoded = decodeJsString(result) ?: return emptyList()
            if (decoded.isEmpty()) return emptyList()
            return try {
                when (val element = JSON.parseToJsonElement(decoded)) {
                    is JsonArray -> element.map { it.jsonPrimitive.content }.filter { it.isNotEmpty() }
                    else -> listOf(decoded)
                }
            } catch (_: Exception) {
                listOf(decoded)
            }
        }
    }
}

data class BunkrPageCandidate(
    val url: String,
    val extension: String? = null,
    val sizeBytes: Long? = null,
    val directMediaUrl: String? = null,
)

data class BunkrPageHints(
    val cdn: String? = null,
    val cover: String? = null,
)
