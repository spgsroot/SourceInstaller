package io.github.rustnomicon.sourceinstaller.data.model

enum class AppLogLevel { Debug, Info, Success, Warning, Error }

/**
 * Port of the Flutter `LogEntry` model. Timestamp is epoch milliseconds.
 */
data class LogEntry(
    val timestampMillis: Long,
    val level: AppLogLevel,
    val message: String,
    val source: String? = null,
) {
    val displayLevel: String get() = level.name.uppercase()
}
