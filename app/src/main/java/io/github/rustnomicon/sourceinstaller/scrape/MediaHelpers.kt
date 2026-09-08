package io.github.rustnomicon.sourceinstaller.scrape

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import java.net.URI
import java.net.URLDecoder
import java.nio.charset.StandardCharsets

val VIDEO_EXTENSIONS: Set<String> = setOf("mp4", "webm")
val IMAGE_EXTENSIONS: Set<String> = setOf("jpg", "jpeg", "png", "gif", "webp")
val SUPPORTED_MEDIA_EXTENSIONS: Set<String> = VIDEO_EXTENSIONS + IMAGE_EXTENSIONS

private val EXTENSION_AT_END = Regex("""\.([a-z0-9]+)$""")
private val QUALITY_MARKER = Regex("""(?<!\d)(\d{3,4}p)(?!\d)""", RegexOption.IGNORE_CASE)

fun mediaExtensionFromUrl(url: String): String? {
    val path = try {
        URI(url).path?.lowercase() ?: url.lowercase()
    } catch (_: Exception) {
        url.lowercase()
    }
    val extension = EXTENSION_AT_END.find(path)?.groupValues?.get(1) ?: return null
    return if (extension in SUPPORTED_MEDIA_EXTENSIONS) extension else null
}

fun fileNameFromUrl(url: String, fallback: String = "media"): String {
    val segment = try {
        URI(url).rawPath
            ?.split('/')
            ?.lastOrNull { it.isNotEmpty() }
    } catch (_: Exception) {
        null
    } ?: return fallback

    return try {
        URLDecoder.decode(segment, StandardCharsets.UTF_8)
    } catch (_: Exception) {
        segment
    }
}

fun qualityFromFileName(fileName: String): String? =
    QUALITY_MARKER.find(fileName)?.groupValues?.get(1)?.lowercase()

fun applyMediaFilters(
    items: List<MediaItem>,
    filters: FilterSettings,
): List<MediaItem> = items.filter {
    filters.acceptsExtension(it.extension) && filters.acceptsSize(it.sizeBytes)
}
