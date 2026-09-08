package io.github.rustnomicon.sourceinstaller.scrape

import io.github.rustnomicon.sourceinstaller.net.DESKTOP_USER_AGENT
import io.github.rustnomicon.sourceinstaller.net.HttpClients
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.Request

/**
 * Shared Bunkr/Redgifs-style host helpers. In the Flutter version this logic
 * was copy-pasted between the WebView scraper, the download manager, and the
 * preview UI; here it lives in one place.
 */
object BunkrSupport {

    val BUNKR_MEDIA_EXTENSIONS = setOf("mp4", "webm", "jpg", "jpeg", "png", "gif", "webp")

    private val SIGN_HOST = "glb-apisign.cdn.cr"
    private val JS_CDN_REGEX = Regex("""var\s+jsCDN\s*=\s*(["'])(.*?)\1""", RegexOption.DOT_MATCHES_ALL)
    private val JSON = Json { ignoreUnknownKeys = true }

    fun isBunkrRelatedHost(host: String): Boolean {
        val normalized = host.lowercase()
        return normalized.contains("bunkr") ||
            normalized.endsWith(".cdn.cr") ||
            normalized.contains("gigachad-cdn") ||
            normalized == "bnkr.b-cdn.net"
    }

    fun isBunkrRelatedUrl(value: String): Boolean {
        val host = hostOf(value)?.lowercase() ?: return false
        return isBunkrRelatedHost(host)
    }

    fun hostOf(value: String): String? = try {
        URI(value).host
    } catch (_: Exception) {
        null
    }

    fun isBunkrFilePageUrl(uri: URI): Boolean {
        val host = (uri.host ?: return false).lowercase()
        if (!host.contains("bunkr")) return false
        val first = uri.pathSegments().firstOrNull() ?: return false
        return first.lowercase() in setOf("f", "v", "i", "d")
    }

    fun isBunkrMediaUrl(uri: URI): Boolean {
        val host = (uri.host ?: return false).lowercase()
        if (!isBunkrRelatedHost(host)) return false
        val extension = mediaExtensionFromUrl(uri.toString())?.lowercase() ?: return false
        return extension in BUNKR_MEDIA_EXTENSIONS
    }

    fun isSupportedVideoUrl(url: String): Boolean {
        val extension = mediaExtensionFromUrl(url)
        return extension == "mp4" || extension == "webm"
    }

    fun isSupportedVideoPath(path: String): Boolean {
        val lower = path.lowercase()
        return lower.endsWith(".mp4") || lower.endsWith(".webm")
    }

    fun bunkrSignPath(rawUrl: String): String? {
        val uri = parseUri(rawUrl) ?: return null
        if ((uri.host ?: "").lowercase() != SIGN_HOST) return null
        val path = queryParam(uri, "path") ?: return null
        return if (isSupportedVideoPath(path)) path else null
    }

    fun normalizeEscapedUrl(url: String): String =
        url.replace("\\u002F", "/").replace("\\/", "/").trim()

    fun normalizeUrlFully(url: String): String =
        normalizeEscapedUrl(url).replace("&amp;", "&")

    fun bunkrAdvancedAlbumUrl(url: String): String {
        val uri = parseUri(url) ?: return url
        val next = linkedMapOf<String, String>()
        uri.queryParams().forEach { (k, v) -> next[k] = v }
        next["advanced"] = "1"
        return replaceQuery(uri, next)
    }

    /** Visible challenge entry point: album links open the advanced view. */
    fun visibleChallengeUrlFor(url: String): String {
        val uri = parseUri(url) ?: return url
        val host = (uri.host ?: return url).lowercase()
        val segments = uri.pathSegments()
        if (host.contains("bunkr") && segments.firstOrNull()?.lowercase() == "a") {
            return bunkrAdvancedAlbumUrl(url)
        }
        return url
    }

    fun bunkrMediaHeaders(referer: String?): Map<String, String> {
        val refererUri = referer?.let(::parseUri)
        val origin = refererUri
            ?.takeIf { it.scheme != null && !it.host.isNullOrEmpty() }
            ?.let { "${it.scheme}://${it.host}" }
            ?: "https://bunkr.cr"
        return mapOf(
            "user-agent" to DESKTOP_USER_AGENT,
            "accept" to "*/*",
            "referer" to (referer ?: "$origin/"),
            "origin" to origin,
        )
    }

    fun bunkrPageHeaders(sourceUrl: String): Map<String, String> {
        val sourceUri = parseUri(sourceUrl)
        val origin = sourceUri
            ?.takeIf { it.scheme != null }
            ?.let { "${it.scheme}://${it.host}" }
            ?: "https://bunkr.cr"
        return mapOf(
            "user-agent" to DESKTOP_USER_AGENT,
            "accept" to "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "referer" to origin,
            "origin" to origin,
        )
    }

    fun extractBunkrJsCdn(html: String): String? {
        val raw = JS_CDN_REGEX.find(html)?.groupValues?.get(2)
        if (raw.isNullOrEmpty()) return null
        val normalized = normalizeUrlFully(raw)
        val uri = parseUri(normalized) ?: return null
        if (!isBunkrRelatedUrl(normalized)) return null
        val extension = previewExtensionFromUrl(uri) ?: return null
        return if (extension in BUNKR_MEDIA_EXTENSIONS) normalized else null
    }

    fun previewExtensionFromUrl(uri: URI): String? =
        Regex("""\.([a-z0-9]+)$""", RegexOption.IGNORE_CASE)
            .find(uri.path ?: "")
            ?.groupValues?.get(1)
            ?.lowercase()

    fun hasBunkrSignature(url: String): Boolean {
        val uri = parseUri(url) ?: return false
        val token = queryParam(uri, "token")
        val ex = queryParam(uri, "ex")
        return !token.isNullOrEmpty() && !ex.isNullOrEmpty()
    }

    fun mediaItemDedupeKey(url: String): String {
        val uri = parseUri(url) ?: return url
        if (!isBunkrRelatedHost(uri.host ?: return url)) return url
        return stripQuery(uri)
    }

    /**
     * Signs a Bunkr CDN URL via the public `glb-apisign.cdn.cr/sign` endpoint.
     * Returns the input when the URL is not signable or signing fails.
     */
    suspend fun signBunkrMediaUrl(rawUrl: String): String = withContext(Dispatchers.IO) {
        val normalized = normalizeEscapedUrl(rawUrl)
        val uri = parseUri(normalized)
        if (uri == null || !isSupportedVideoUrl(normalized)) return@withContext normalized

        try {
            val signUrl = "https://$SIGN_HOST/sign?path=" +
                URLEncoder.encode(uri.path ?: "/", StandardCharsets.UTF_8)
            val request = Request.Builder()
                .url(signUrl)
                .header("User-Agent", DESKTOP_USER_AGENT)
                .build()
            HttpClients.scraper.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return@withContext normalized
                val body = response.body?.string() ?: return@withContext normalized
                val json = JSON.parseToJsonElement(body).jsonObject
                val token = json["token"]?.jsonPrimitive?.content
                val ex = json["ex"]?.jsonPrimitive?.content
                if (token.isNullOrEmpty() || ex.isNullOrEmpty()) {
                    return@withContext normalized
                }
                val next = linkedMapOf<String, String>()
                uri.queryParams().forEach { (k, v) -> next[k] = v }
                next["token"] = token
                next["ex"] = ex
                replaceQuery(uri, next)
            }
        } catch (_: Exception) {
            normalized
        }
    }

    /** Best-effort HEAD request for the size of a Bunkr media URL. */
    suspend fun readBunkrMediaSizeBytes(mediaUrl: String, referer: String? = null): Long? =
        withContext(Dispatchers.IO) {
            val normalized = normalizeEscapedUrl(mediaUrl)
            val uri = parseUri(normalized) ?: return@withContext null
            if (!isBunkrMediaUrl(uri)) return@withContext null

            try {
                val builder = Request.Builder()
                    .url(normalized)
                    .head()
                bunkrMediaHeaders(referer).forEach { (k, v) -> builder.header(k, v) }
                HttpClients.scraper.newBuilder()
                    .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
                    .readTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
                    .build()
                    .newCall(builder.build())
                    .execute()
                    .use { response ->
                        if (response.code !in 200..399) return@withContext null
                        response.body?.close()
                        sizeBytesFromHeaders(
                            contentLength = response.header("content-length"),
                            contentRange = response.header("content-range"),
                        )
                    }
            } catch (_: Exception) {
                null
            }
        }

    fun sizeBytesFromHeaders(contentLength: String?, contentRange: String?): Long? {
        contentLength?.trim()?.toLongOrNull()?.let { if (it >= 0) return it }
        if (contentRange == null) return null
        val match = Regex("""/(\d+)\s*$""").find(contentRange) ?: return null
        return match.groupValues[1].toLongOrNull()?.takeIf { it >= 0 }
    }

    fun parseUri(url: String): URI? = try {
        URI(url)
    } catch (_: Exception) {
        null
    }

    fun queryParam(uri: URI, name: String): String? =
        uri.queryParams()[name]

    fun stripQuery(uri: URI): String = URI(
        uri.scheme, uri.authority, uri.path, null, uri.fragment,
    ).toString()

    fun replaceQuery(uri: URI, params: Map<String, String>): String {
        val query = params.entries.joinToString("&") { (k, v) ->
            URLEncoder.encode(k, StandardCharsets.UTF_8) + "=" +
                URLEncoder.encode(v, StandardCharsets.UTF_8)
        }
        return URI(uri.scheme, uri.authority, uri.path, null, null)
            .toString() + if (query.isEmpty()) "" else "?$query"
    }

    /** Decoded query parameters of a URI as a map (last value wins). */
    fun URI.queryParams(): Map<String, String> {
        val raw = rawQuery ?: return emptyMap()
        val result = LinkedHashMap<String, String>()
        for (pair in raw.split('&')) {
            if (pair.isEmpty()) continue
            val idx = pair.indexOf('=')
            val keyRaw = if (idx >= 0) pair.substring(0, idx) else pair
            val valueRaw = if (idx >= 0) pair.substring(idx + 1) else ""
            try {
                result[urlDecode(keyRaw)] = urlDecode(valueRaw)
            } catch (_: Exception) {
                // skip malformed pairs
            }
        }
        return result
    }

    fun URI.pathSegments(): List<String> =
        (path ?: "").split('/').filter { it.isNotEmpty() }

    private fun urlDecode(value: String): String =
        URLDecoderCompat.decode(value)

    private object URLDecoderCompat {
        fun decode(value: String): String =
            java.net.URLDecoder.decode(value, StandardCharsets.UTF_8)
    }
}
