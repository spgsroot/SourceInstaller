package io.github.rustnomicon.sourceinstaller.util

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val UNITS = listOf("B", "KB", "MB", "GB", "TB")

fun formatBytes(bytes: Long?): String? {
    if (bytes == null || bytes < 0) return null
    var value = bytes.toDouble()
    var unitIndex = 0
    while (value >= 1024 && unitIndex < UNITS.size - 1) {
        value /= 1024
        unitIndex++
    }
    val decimals = if (value >= 10 || unitIndex == 0) 0 else 1
    return String.format(Locale.US, "%.${decimals}f %s", value, UNITS[unitIndex])
}

fun formatMediaSubtitle(sizeBytes: Long?, url: String): String {
    val size = formatBytes(sizeBytes)
    return if (size == null) url else "$size • $url"
}

private val LOG_TS_FORMAT = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)

fun formatLogTimestamp(epochMillis: Long): String =
    LOG_TS_FORMAT.format(Date(epochMillis))
