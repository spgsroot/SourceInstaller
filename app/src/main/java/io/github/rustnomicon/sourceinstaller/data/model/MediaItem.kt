package io.github.rustnomicon.sourceinstaller.data.model

/**
 * A single downloadable media file discovered by a scraper.
 *
 * Port of the Flutter `MediaItem` freezed model.
 */
data class MediaItem(
    val url: String,
    val fileName: String,
    val extension: String,
    val sourceUrl: String,
    val sizeBytes: Long? = null,
    val quality: String? = null,
)
