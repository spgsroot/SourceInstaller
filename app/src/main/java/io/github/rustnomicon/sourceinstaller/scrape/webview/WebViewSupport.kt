package io.github.rustnomicon.sourceinstaller.scrape.webview

import android.webkit.WebView
import io.github.rustnomicon.sourceinstaller.scrape.BunkrSupport
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.coroutines.resume

const val WEBVIEW_PAGE_TIMEOUT_MS: Long = 20_000

/**
 * Runs [script] in this WebView and returns the raw JSON-encoded callback
 * value (WebView `evaluateJavascript` semantics).
 */
suspend fun WebView.evaluateJs(script: String, timeoutMs: Long = WEBVIEW_PAGE_TIMEOUT_MS): String? =
    withContext(Dispatchers.Main) {
        withTimeout(timeoutMs) {
            suspendCancellableCoroutine { continuation ->
                evaluateJavascript(script) { value -> continuation.resume(value) }
            }
        }
    }

/**
 * `evaluateJavascript` JSON-encodes its return value, so a JS string arrives
 * double-quoted. Decodes one level; returns null for JS null/undefined.
 */
fun decodeJsString(result: String?): String? {
    if (result == null || result == "null" || result == "undefined") return null
    return try {
        JSON.parseToJsonElement(result).jsonPrimitive.content
    } catch (_: Exception) {
        result
    }
}

/** Decode a JS-returned JSON string into a list of strings. */
fun decodeStringList(result: String?): List<String> {
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

/** Decode a JS-returned JSON string into a string map. */
fun decodeStringMap(result: String?): Map<String, String> {
    val decoded = decodeJsString(result) ?: return emptyMap()
    return try {
        when (val element = JSON.parseToJsonElement(decoded)) {
            is JsonObject -> element.mapValues { (_, v) -> v.jsonPrimitive.content }
            else -> emptyMap()
        }
    } catch (_: Exception) {
        emptyMap()
    }
}

private val JSON = Json { ignoreUnknownKeys = true }

/** Thread-safe media URL sink fed by WebView interception callbacks. */
class MediaUrlCapture(
    private val accept: (String) -> Boolean = { true },
) {
    private val urls: MutableSet<String> = ConcurrentHashMap.newKeySet()

    val snapshot: Set<String> get() = urls.toSet()

    fun capture(raw: String?) {
        if (raw.isNullOrEmpty()) return
        val normalized = BunkrSupport.normalizeEscapedUrl(raw)
        if (accept(normalized)) urls.add(normalized)
    }
}
