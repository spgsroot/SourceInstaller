package io.github.rustnomicon.sourceinstaller.ui.analyze

import android.webkit.WebView
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import coil3.compose.AsyncImage
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.net.DESKTOP_USER_AGENT
import io.github.rustnomicon.sourceinstaller.net.HttpClients
import io.github.rustnomicon.sourceinstaller.scrape.BunkrSupport
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Request

private val IMAGE_EXTENSIONS = setOf("jpg", "jpeg", "png", "gif", "webp")

@Composable
fun MediaPreviewDialog(item: MediaItem, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.preview_title)) },
        text = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(420.dp),
            ) {
                MediaPreview(item)
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.close_button))
            }
        },
    )
}

@Composable
private fun MediaPreview(item: MediaItem) {
    val isBunkr = BunkrSupport.isBunkrRelatedUrl(item.url) ||
        BunkrSupport.isBunkrRelatedUrl(item.sourceUrl)

    if (isBunkr) {
        BunkrMediaPreview(item)
        return
    }

    if (item.extension.lowercase() in IMAGE_EXTENSIONS) {
        ZoomableImage(item.url)
        return
    }

    VideoPreviewWebView(url = item.url, baseUrl = item.sourceUrl)
}

@Composable
private fun BunkrMediaPreview(item: MediaItem) {
    val previewUrl by produceState<String?>(initialValue = null, item) {
        value = freshBunkrPreviewUrl(item)
    }

    val url = previewUrl
    if (url == null) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    if (item.extension.lowercase() in IMAGE_EXTENSIONS) {
        ZoomableImage(url)
    } else {
        VideoPreviewWebView(url = url, baseUrl = previewBaseUrlFor(item))
    }
}

@Composable
private fun ZoomableImage(url: String) {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }

    Box(
        Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTransformGestures { _, pan, zoom, _ ->
                    scale = (scale * zoom).coerceIn(1f, 6f)
                    offset = if (scale > 1f) {
                        Offset(
                            (offset.x + pan.x),
                            (offset.y + pan.y),
                        )
                    } else {
                        Offset.Zero
                    }
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        AsyncImage(
            model = url,
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    scaleX = scale
                    scaleY = scale
                    translationX = offset.x
                    translationY = offset.y
                },
        )
    }
}

@Composable
private fun VideoPreviewWebView(url: String, baseUrl: String?) {
    AndroidView(
        modifier = Modifier.fillMaxSize(),
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.mediaPlaybackRequiresUserGesture = false
                settings.userAgentString = DESKTOP_USER_AGENT
                settings.domStorageEnabled = true
                loadDataWithBaseURL(
                    baseUrl?.takeIf { it.isNotEmpty() },
                    videoPreviewHtml(url),
                    "text/html",
                    "UTF-8",
                    baseUrl?.takeIf { it.isNotEmpty() },
                )
            }
        },
    )
}

internal fun videoPreviewHtml(url: String): String {
    val safeUrl = url
        .replace("&", "&amp;")
        .replace("\"", "&quot;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    return """
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      html, body { margin: 0; height: 100%; background: #000; }
      video { width: 100%; height: 100%; object-fit: contain; }
      #error { display: none; color: #fff; padding: 16px; font: 14px sans-serif; word-break: break-all; }
    </style>
  </head>
  <body>
    <video id="preview" controls playsinline preload="metadata" src="$safeUrl"></video>
    <div id="error">Preview failed: $safeUrl</div>
    <script>
      const video = document.getElementById('preview');
      const error = document.getElementById('error');
      video.addEventListener('error', () => {
        error.style.display = 'block';
      });
    </script>
  </body>
</html>
""".trimIndent()
}

private fun previewBaseUrlFor(item: MediaItem): String? {
    val sourceUri = BunkrSupport.parseUri(item.sourceUrl)
    if (sourceUri?.scheme != null && !sourceUri.host.isNullOrEmpty()) {
        return item.sourceUrl
    }
    val itemUri = BunkrSupport.parseUri(item.url)
    if (itemUri?.scheme != null && !itemUri.host.isNullOrEmpty()) {
        return "${itemUri.scheme}://${itemUri.host}/"
    }
    return null
}

/**
 * Returns a freshly signed Bunkr preview URL, preferring the current jsCDN
 * from the source file page (port of `_freshBunkrPreviewUrl`).
 */
internal suspend fun freshBunkrPreviewUrl(item: MediaItem): String {
    val normalized = BunkrSupport.normalizeEscapedUrl(item.url)
    val uri = BunkrSupport.parseUri(normalized)
    val extension = item.extension.lowercase()
    if (uri == null ||
        !BunkrSupport.isBunkrRelatedUrl(normalized) ||
        extension !in BunkrSupport.BUNKR_MEDIA_EXTENSIONS
    ) {
        return normalized
    }

    val fromSourcePage = freshBunkrPreviewUrlFromSourcePage(item)
    if (fromSourcePage != null) return fromSourcePage

    return BunkrSupport.signBunkrMediaUrl(normalized)
}

private suspend fun freshBunkrPreviewUrlFromSourcePage(item: MediaItem): String? =
    withContext(Dispatchers.IO) {
        val sourceUri = BunkrSupport.parseUri(item.sourceUrl)
        if (sourceUri == null || !BunkrSupport.isBunkrFilePageUrl(sourceUri)) return@withContext null

        try {
            val builder = Request.Builder().url(item.sourceUrl)
            BunkrSupport.bunkrPageHeaders(item.sourceUrl).forEach { (k, v) -> builder.header(k, v) }
            HttpClients.scraper.newBuilder()
                .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
                .build()
                .newCall(builder.build())
                .execute()
                .use { response ->
                    if (response.code !in 200..399) return@withContext null
                    val html = response.body?.string().orEmpty()
                    val jsCdn = BunkrSupport.extractBunkrJsCdn(html) ?: return@withContext null
                    val signedJsCdn = BunkrSupport.signBunkrMediaUrl(jsCdn)
                    if (BunkrSupport.hasBunkrSignature(jsCdn) ||
                        BunkrSupport.hasBunkrSignature(signedJsCdn)
                    ) {
                        signedJsCdn
                    } else {
                        null
                    }
                }
        } catch (_: Exception) {
            null
        }
    }
