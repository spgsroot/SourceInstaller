package io.github.rustnomicon.sourceinstaller.errors

open class ScrapeException(
    message: String,
    val source: String? = null,
    cause: Throwable? = null,
) : Exception(message, cause) {

    override fun toString(): String {
        val prefix = if (source == null) "ScrapeException" else "ScrapeException[$source]"
        return "$prefix: $message"
    }
}

class CaptchaRequiredException(
    message: String,
    source: String? = null,
    cause: Throwable? = null,
) : ScrapeException(message, source, cause)

class ScrapeTimeoutException(
    message: String,
    source: String? = null,
    cause: Throwable? = null,
) : ScrapeException(message, source, cause)
