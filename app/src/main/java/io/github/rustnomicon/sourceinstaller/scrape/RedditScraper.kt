package io.github.rustnomicon.sourceinstaller.scrape

import android.webkit.WebView
import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.errors.CaptchaRequiredException
import io.github.rustnomicon.sourceinstaller.errors.ScrapeException
import io.github.rustnomicon.sourceinstaller.errors.ScrapeTimeoutException
import io.github.rustnomicon.sourceinstaller.net.HttpClients
import io.github.rustnomicon.sourceinstaller.scrape.webview.evaluateJs
import io.github.rustnomicon.sourceinstaller.service.LoggerService
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.URI
import java.net.URLDecoder
import java.nio.charset.StandardCharsets
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.OkHttpClient
import okhttp3.Request

/**
 * Extracts media from Reddit posts via the JSON API and HTML scanning,
 * with a visible-WebView fallback for protection walls and /s/ links.
 *
 * Port of the Flutter `RedditScraper`.
 */
class RedditScraper(
    private val client: OkHttpClient = HttpClients.scraper,
    private val logger: LoggerService = LoggerService.getInstance(),
) : BaseScraper {

    override fun canHandle(url: String): Boolean {
        val host = BunkrSupport.hostOf(url)?.lowercase() ?: return false
        return host == "redd.it" ||
            host.endsWith(".reddit.com") ||
            host == "reddit.com" ||
            host == "i.redd.it" ||
            host == "preview.redd.it" ||
            host == "v.redd.it" ||
            host == "packaged-media.redd.it"
    }

    override suspend fun extractMedia(
        url: String,
        filters: FilterSettings,
    ): List<MediaItem> {
        logger.info("Reddit: начало парсинга", source = url)

        try {
            val direct = directMediaItem(url, sourceUrl = url)
            if (direct != null) {
                val filtered = applyMediaFilters(listOf(direct), filters)
                logger.success(
                    "Reddit: прямое media URL найдено: ${filtered.size}",
                    source = url,
                )
                return filtered
            }

            if (isRedditShareUrl(url)) {
                logger.warning(
                    "Reddit: короткая /s/ ссылка требует видимый WebView",
                    source = url,
                )
                throw CaptchaRequiredException(
                    "Reddit /s/ ссылка открывается через видимый WebView.",
                    source = url,
                )
            }

            val jsonItems = extractItemsFromJsonEndpoint(url)
            if (jsonItems.isNotEmpty()) {
                val filtered = applyMediaFilters(jsonItems, filters)
                logger.success(
                    "Reddit: найдено медиа через JSON: ${filtered.size}",
                    source = url,
                )
                return filtered
            }

            val request = Request.Builder().url(url).build()
            val (html, sourceUrl) = withContext(Dispatchers.IO) {
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) throw HttpFailureException(response.code)
                    val body = response.body?.string().orEmpty()
                    body to response.request.url.toString()
                }
            }
            val normalizedHtml = normalizeEscapedHtml(html)

            val htmlItems = extractItemsFromHtml(normalizedHtml, sourceUrl)
            val redirectedJsonItems = extractItemsFromJsonEndpoint(sourceUrl)
            val items = dedupeByFile(htmlItems + redirectedJsonItems)
                .filter { filters.acceptsExtension(it.extension) }
                .filter { filters.acceptsSize(it.sizeBytes) }

            logger.success("Reddit: найдено медиа: ${items.size}", source = sourceUrl)
            return items
        } catch (error: SocketTimeoutException) {
            logger.error("Reddit: таймаут парсинга", source = url, error = error)
            throw ScrapeTimeoutException("Reddit не ответил вовремя", source = url, cause = error)
        } catch (error: ScrapeException) {
            throw error
        } catch (error: HttpFailureException) {
            logger.error("Reddit: ошибка HTTP при парсинге", source = url, error = error)
            if (error.code == 403 || error.code == 429) {
                throw CaptchaRequiredException(
                    "Reddit заблокировал статический запрос. Откройте видимый WebView.",
                    source = url,
                    cause = error,
                )
            }
            throw ScrapeException("Не удалось загрузить Reddit HTML", source = url, cause = error)
        } catch (error: IOException) {
            logger.error("Reddit: ошибка HTTP при парсинге", source = url, error = error)
            throw ScrapeException("Не удалось загрузить Reddit HTML", source = url, cause = error)
        } catch (error: Exception) {
            logger.error("Reddit: ошибка парсинга", source = url, error = error)
            throw ScrapeException("Не удалось извлечь Reddit media", source = url, cause = error)
        }
    }

    /** Extraction using an already-loaded visible WebView. */
    suspend fun extractMediaFromWebView(
        url: String,
        webView: WebView,
        filters: FilterSettings = FilterSettings(),
        capturedMediaUrls: Set<String> = emptySet(),
    ): List<MediaItem> {
        logger.info("Reddit: парсинг через видимый WebView", source = url)

        val currentUrl = withContext(Dispatchers.Main) { webView.url }
        val sourceUrl = if (currentUrl.isNullOrEmpty()) url else currentUrl
        val result = webView.evaluateJs(ScraperScripts.REDDIT_WEBVIEW_COLLECTOR)
        val html = readHtmlFromWebView(webView)
        val urls: Set<String> = capturedMediaUrls + asStringList(result)

        val directItems = urls.mapNotNull { directMediaItem(it, sourceUrl = sourceUrl) }
        val htmlItems = extractItemsFromHtml(normalizeEscapedHtml(html), sourceUrl)
        val jsonItems = extractItemsFromJsonEndpoint(sourceUrl)

        val items = dedupeByFile(directItems + htmlItems + jsonItems)
            .filter { filters.acceptsExtension(it.extension) }
            .filter { filters.acceptsSize(it.sizeBytes) }

        logger.success(
            "Reddit: найдено медиа в видимом WebView: ${items.size}",
            source = url,
        )
        return items
    }

    private suspend fun readHtmlFromWebView(webView: WebView): String = try {
        val result = webView.evaluateJs(ScraperScripts.REDDIT_HTML_READER)
        io.github.rustnomicon.sourceinstaller.scrape.webview.decodeJsString(result) ?: ""
    } catch (_: Exception) {
        ""
    }

    internal fun extractItemsFromHtml(html: String, sourceUrl: String): List<MediaItem> {
        val seen = LinkedHashSet<String>()
        val items = mutableListOf<MediaItem>()

        fun add(rawUrl: String?) {
            if (rawUrl.isNullOrEmpty()) return
            val cleaned = cleanUrl(rawUrl) ?: return
            if (!seen.add(cleaned)) return
            val item = directMediaItem(cleaned, sourceUrl = sourceUrl)
            if (item != null) items += item
        }

        for (pattern in MEDIA_URL_PATTERNS) {
            for (match in pattern.findAll(html)) {
                add(match.value)
            }
        }

        for (pattern in ENCODED_MEDIA_URL_PATTERNS) {
            for (match in pattern.findAll(html)) {
                val encoded = match.groups[1]?.value ?: match.value
                add(urlDecodeFull(encoded))
            }
        }

        for (videoId in extractVRedditIds(html)) {
            // Best-effort fallback for uploaded Reddit videos.
            add("https://v.redd.it/$videoId/DASH_720.mp4?source=fallback")
        }

        items.sortWith(::compareRedditItems)
        return dedupeByFile(items)
    }

    internal fun asStringList(value: String?): List<String> {
        val decodedString = io.github.rustnomicon.sourceinstaller.scrape.webview.decodeJsString(value)
            ?: return emptyList()
        if (decodedString.isEmpty()) return emptyList()
        return try {
            when (val element = JSON.parseToJsonElement(decodedString)) {
                is JsonArray -> element.map { it.jsonPrimitive.content }
                else -> listOf(decodedString)
            }
        } catch (_: Exception) {
            listOf(decodedString)
        }
    }

    private suspend fun extractItemsFromJsonEndpoint(sourceUrl: String): List<MediaItem> {
        val jsonUrl = jsonEndpointFor(sourceUrl) ?: return emptyList()

        return try {
            val request = Request.Builder()
                .url(jsonUrl)
                .header("Accept", "application/json,text/plain,*/*")
                .build()
            val body = withContext(Dispatchers.IO) {
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        throw HttpFailureException(response.code)
                    }
                    response.body?.string().orEmpty()
                }
            }
            val submission = submissionFromListing(body) ?: return emptyList()

            val items = mutableListOf<MediaItem>()
            items += extractItemsFromSubmission(submission, sourceUrl)

            val crossposts = submission["crosspost_parent_list"]
            if (crossposts is JsonArray) {
                for (crosspost in crossposts) {
                    if (crosspost is JsonObject) {
                        items += extractItemsFromSubmission(crosspost, sourceUrl)
                    }
                }
            }

            dedupeByFile(items)
        } catch (error: Exception) {
            // The JSON endpoint is a best-effort fallback; any failure simply
            // means we continue with HTML parsing (matches the Dart version).
            logger.debug("Reddit: JSON fallback недоступен: $error", source = jsonUrl)
            emptyList()
        }
    }

    internal fun submissionFromListing(data: String): JsonObject? {
        val parsed = try {
            JSON.parseToJsonElement(data)
        } catch (_: Exception) {
            return null
        }
        val listing = (parsed as? JsonArray)?.firstOrNull() as? JsonObject ?: return null
        val listingData = listing["data"] as? JsonObject ?: return null
        val children = listingData["children"] as? JsonArray ?: return null
        val child = children.firstOrNull() as? JsonObject ?: return null
        return child["data"] as? JsonObject
    }

    private fun extractItemsFromSubmission(
        submission: JsonObject,
        sourceUrl: String,
    ): List<MediaItem> {
        val items = mutableListOf<MediaItem>()

        fun add(value: String?) {
            if (value.isNullOrEmpty()) return
            val item = directMediaItem(value, sourceUrl = sourceUrl)
            if (item != null) items += item
        }

        add(submission.stringValue("url_overridden_by_dest"))
        add(submission.stringValue("url"))

        extractRedditVideoUrls(submission["secure_media"]).forEach(::add)
        extractRedditVideoUrls(submission["media"]).forEach(::add)

        val preview = submission["preview"] as? JsonObject
        val images = preview?.get("images") as? JsonArray
        if (images != null) {
            for (image in images) {
                if (image !is JsonObject) continue
                (image["source"] as? JsonObject)?.let { add(it.stringValue("url")) }
                val variants = image["variants"] as? JsonObject
                if (variants != null) {
                    for ((_, variant) in variants) {
                        if (variant !is JsonObject) continue
                        (variant["source"] as? JsonObject)?.let { add(it.stringValue("url")) }
                    }
                }
            }
        }

        val metadata = submission["media_metadata"] as? JsonObject
        if (metadata != null) {
            for ((_, entry) in metadata) {
                if (entry !is JsonObject) continue
                val status = entry.stringValue("status")
                if (status != null && status != "valid") continue

                val source = entry["s"] as? JsonObject
                if (source != null) {
                    add(source.stringValue("u"))
                    add(source.stringValue("gif"))
                    add(source.stringValue("mp4"))
                }
                add(entry.stringValue("hlsUrl"))
                add(entry.stringValue("dashUrl"))
            }
        }

        return dedupeByFile(items)
    }

    private fun extractRedditVideoUrls(media: JsonElement?): Sequence<String> = sequence {
        if (media !is JsonObject) return@sequence
        val redditVideo = media["reddit_video"] as? JsonObject ?: return@sequence

        val fallbackUrl = redditVideo.stringValue("fallback_url")
        if (!fallbackUrl.isNullOrEmpty()) {
            yield(fallbackUrl)
            return@sequence
        }

        val dashUrl = redditVideo.stringValue("dash_url")
        val videoId = videoIdFromManifestUrl(dashUrl)
            ?: videoIdFromManifestUrl(redditVideo.stringValue("hls_url"))
        val height = redditVideo.stringValue("height")
        if (videoId != null) {
            yield("https://v.redd.it/$videoId/DASH_${height ?: "720"}.mp4?source=fallback")
        }
    }

    private fun videoIdFromManifestUrl(value: String?): String? {
        if (value.isNullOrEmpty()) return null
        val uri = BunkrSupport.parseUri(cleanUrl(value) ?: value) ?: return null
        if ((uri.host ?: "").lowercase() != "v.redd.it") return null
        return BunkrSupport.run { uri.pathSegments().firstOrNull() }
    }

    internal fun jsonEndpointFor(url: String): String? {
        val uri = BunkrSupport.parseUri(url) ?: return null
        val host = (uri.host ?: return null).lowercase()

        if (host == "redd.it") {
            val id = BunkrSupport.run { uri.pathSegments().firstOrNull() } ?: return null
            return commentsJsonUrl(id)
        }

        if (host != "reddit.com" && !host.endsWith(".reddit.com")) return null

        val segments = BunkrSupport.run { uri.pathSegments() }
        val commentsIndex = segments.indexOf("comments")
        if (commentsIndex != -1 && commentsIndex + 1 < segments.size) {
            return commentsJsonUrl(segments[commentsIndex + 1])
        }
        val galleryIndex = segments.indexOf("gallery")
        if (galleryIndex != -1 && galleryIndex + 1 < segments.size) {
            return commentsJsonUrl(segments[galleryIndex + 1])
        }
        return null
    }

    private fun commentsJsonUrl(postId: String): String {
        val encoded = try {
            java.net.URLEncoder.encode(postId, StandardCharsets.UTF_8)
        } catch (_: Exception) {
            postId
        }
        return "https://www.reddit.com/comments/$encoded/.json?raw_json=1"
    }

    internal fun isRedditShareUrl(url: String): Boolean {
        val uri = BunkrSupport.parseUri(url) ?: return false
        val host = (uri.host ?: return false).lowercase()
        if (host != "reddit.com" && !host.endsWith(".reddit.com")) return false
        val segments = BunkrSupport.run { uri.pathSegments() }.map { it.lowercase() }
        val shareIndex = segments.indexOf("s")
        return shareIndex != -1 && shareIndex + 1 < segments.size
    }

    internal fun directMediaItem(rawUrl: String, sourceUrl: String): MediaItem? {
        val url = normalizePreviewUrl(cleanUrl(rawUrl) ?: rawUrl)
        val uri = BunkrSupport.parseUri(url) ?: return null

        val host = (uri.host ?: "").lowercase()
        val extension = mediaExtensionFromUrl(url)
        if (host == "v.redd.it" && extension == null) {
            val videoId = BunkrSupport.run { uri.pathSegments().firstOrNull() } ?: return null
            return directMediaItem(
                "https://v.redd.it/$videoId/DASH_720.mp4?source=fallback",
                sourceUrl = sourceUrl,
            )
        }
        if (extension == null) return null

        val isRedditMedia = host == "i.redd.it" ||
            host == "preview.redd.it" ||
            host == "v.redd.it" ||
            host == "packaged-media.redd.it"
        if (!isRedditMedia) return null

        val fileName = fileNameFromUrl(url)
        return MediaItem(
            url = url,
            fileName = fileName,
            extension = extension,
            quality = qualityFromFileName(fileName) ?: qualityFromRedditUrl(url),
            sourceUrl = sourceUrl,
        )
    }

    internal fun normalizeEscapedHtml(html: String): String =
        html.replace("&amp;", "&")
            .replace("\\u0026", "&")
            .replace("\\u003d", "=")
            .replace("\\u003D", "=")
            .replace("\\u002F", "/")
            .replace("\\/", "/")

    private val TRAILING_PUNCT = Regex("""[),.;\]}]+$""")

    internal fun cleanUrl(rawUrl: String): String? {
        val normalized = rawUrl
            .replace("&amp;", "&")
            .replace("\\u0026", "&")
            .replace("\\u003d", "=")
            .replace("\\u003D", "=")
            .replace("\\u002F", "/")
            .replace("\\/", "/")
            .trim()
        val trimmed = normalized.replace(TRAILING_PUNCT, "")
        val uri = try {
            URI(trimmed)
        } catch (_: Exception) {
            return null
        }
        if (uri.scheme == null || uri.host.isNullOrEmpty()) return null
        return uri.toString()
    }

    private fun normalizePreviewUrl(url: String): String {
        val uri = BunkrSupport.parseUri(url) ?: return url
        if ((uri.host ?: "").lowercase() != "preview.redd.it") return url
        // Reddit preview URLs include transient resize params; the original
        // lives on i.redd.it with the same path.
        return try {
            URI(uri.scheme, uri.authority.replace("preview.redd.it", "i.redd.it"), uri.path, null, null)
                .toString()
        } catch (_: Exception) {
            url
        }
    }

    internal fun extractVRedditIds(html: String): Set<String> =
        Regex("""https?://v\.redd\.it/([A-Za-z0-9_-]+)""", RegexOption.IGNORE_CASE)
            .findAll(html)
            .mapNotNull { it.groups[1]?.value }
            .toSet()

    internal fun qualityFromRedditUrl(url: String): String? {
        val match = Regex("""DASH_(\d{3,4})\.mp4""", RegexOption.IGNORE_CASE).find(url)
        val height = match?.groups?.get(1)?.value
        return height?.let { "${it}p" }
    }

    private fun compareRedditItems(left: MediaItem, right: MediaItem): Int {
        val leftRank = redditRank(left.url)
        val rightRank = redditRank(right.url)
        if (leftRank != rightRank) return leftRank.compareTo(rightRank)
        return left.url.compareTo(right.url)
    }

    internal fun redditRank(url: String): Int {
        val lower = url.lowercase()
        if (lower.contains("dash_1080")) return 1
        if (lower.contains("dash_720")) return 2
        if (lower.contains("dash_480")) return 3
        if (lower.contains("packaged-media.redd.it")) return 4
        if (lower.contains("v.redd.it")) return 5
        if (lower.contains("i.redd.it")) return 6
        return 7
    }

    internal fun dedupeByFile(items: List<MediaItem>): List<MediaItem> {
        val seen = LinkedHashSet<String>()
        val result = mutableListOf<MediaItem>()
        for (item in items) {
            val key = if (item.url.contains("v.redd.it/")) {
                BunkrSupport.parseUri(item.url)
                    ?.let { BunkrSupport.run { it.pathSegments().take(1).joinToString("/") } }
                    ?: item.url
            } else {
                item.url
            }
            if (seen.add(key)) result += item
        }
        return result
    }

    private fun urlDecodeFull(value: String): String = try {
        URLDecoder.decode(value, StandardCharsets.UTF_8)
    } catch (_: Exception) {
        value
    }

    private fun JsonObject.stringValue(key: String): String? =
        (this[key] as? JsonPrimitive)?.takeUnless { it is kotlinx.serialization.json.JsonNull }?.content

    class HttpFailureException(val code: Int) : IOException("HTTP $code")

    companion object {
        internal val JSON = Json { ignoreUnknownKeys = true }

        private val MEDIA_URL_PATTERNS = listOf(
            Regex("""https?://(?:i|preview)\.redd\.it/[^\s"'<>\\)]+""", RegexOption.IGNORE_CASE),
            Regex("""https?://v\.redd\.it/[A-Za-z0-9_-]+/DASH_\d+\.mp4[^\s"'<>\\)]*""", RegexOption.IGNORE_CASE),
            Regex("""https?://packaged-media\.redd\.it/[^\s"'<>\\)]+\.mp4[^\s"'<>\\)]*""", RegexOption.IGNORE_CASE),
        )

        private val ENCODED_MEDIA_URL_PATTERNS = listOf(
            Regex("""(https%3A%2F%2F(?:i|preview)\.redd\.it%2F[^\s"'<>\\)]+)""", RegexOption.IGNORE_CASE),
            Regex("""(https%3A%2F%2Fv\.redd\.it%2F[A-Za-z0-9_-]+%2FDASH_\d+\.mp4[^\s"'<>\\)]*)""", RegexOption.IGNORE_CASE),
            Regex("""url=(https%3A%2F%2F(?:i|preview|v|packaged-media)\.redd\.it[^\s"'<>\\)&]+)""", RegexOption.IGNORE_CASE),
        )
    }
}
