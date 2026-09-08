package io.github.rustnomicon.sourceinstaller.data.model

/**
 * User-adjustable media filters. Port of the Flutter `FilterSettings` model.
 */
data class FilterSettings(
    val onlyVideo: Boolean = true,
    val ignoreSmallFiles: Boolean = false,
    val minSizeBytes: Long? = null,
    val downloadLimit: Int? = null,
    val allowedExtensions: Set<String> = setOf("mp4", "webm"),
) {
    val effectiveMinSizeBytes: Long?
        get() = minSizeBytes
            ?: (if (ignoreSmallFiles) DEFAULT_SMALL_FILE_THRESHOLD_BYTES else null)

    fun acceptsExtension(extension: String): Boolean {
        val normalized = extension.lowercase().removePrefix(".")
        if (onlyVideo && normalized !in VIDEO_EXTENSIONS) return false
        return normalized in allowedExtensions
    }

    fun acceptsSize(sizeBytes: Long?): Boolean {
        val minimum = effectiveMinSizeBytes ?: return true
        if (sizeBytes == null) return true
        return sizeBytes >= minimum
    }

    companion object {
        const val DEFAULT_SMALL_FILE_THRESHOLD_BYTES: Long = 2L * 1024 * 1024
        val VIDEO_EXTENSIONS = setOf("mp4", "webm")
        val ALL_EXTENSIONS = setOf("mp4", "webm", "jpg", "jpeg", "png", "gif", "webp")
    }
}
