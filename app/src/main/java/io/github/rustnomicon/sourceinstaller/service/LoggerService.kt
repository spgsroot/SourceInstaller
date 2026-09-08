package io.github.rustnomicon.sourceinstaller.service

import android.util.Log
import io.github.rustnomicon.sourceinstaller.data.db.LogDao
import io.github.rustnomicon.sourceinstaller.data.db.LogEntity
import io.github.rustnomicon.sourceinstaller.data.model.AppLogLevel
import io.github.rustnomicon.sourceinstaller.data.model.LogEntry
import java.util.Collections
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch

interface LogRepository {
    suspend fun add(entry: LogEntry)
    suspend fun recent(limit: Int = 100): List<LogEntry>
}

class InMemoryLogRepository : LogRepository {
    private val entries = Collections.synchronizedList(mutableListOf<LogEntry>())

    override suspend fun add(entry: LogEntry) {
        entries.add(entry)
    }

    override suspend fun recent(limit: Int): List<LogEntry> =
        synchronized(entries) { entries.takeLast(limit) }
}

class RoomLogRepository(private val dao: LogDao) : LogRepository {
    override suspend fun add(entry: LogEntry) {
        dao.insert(
            LogEntity(
                timestampMillis = entry.timestampMillis,
                level = entry.level.name,
                message = entry.message,
                source = entry.source,
            ),
        )
    }

    override suspend fun recent(limit: Int): List<LogEntry> =
        dao.recent(limit).asReversed().map { row ->
            LogEntry(
                timestampMillis = row.timestampMillis,
                level = AppLogLevel.entries.firstOrNull { it.name.equals(row.level, true) }
                    ?: AppLogLevel.Info,
                message = row.message,
                source = row.source,
            )
        }
}

/**
 * App-wide logger: persists entries via a [LogRepository], mirrors them to
 * logcat, and broadcasts them to the UI over [stream].
 *
 * Port of the Flutter `LoggerService` singleton.
 */
class LoggerService private constructor(
    private var repository: LogRepository,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _stream = MutableSharedFlow<LogEntry>(extraBufferCapacity = 256)

    val stream: SharedFlow<LogEntry> = _stream.asSharedFlow()

    suspend fun recent(limit: Int = 100): List<LogEntry> = repository.recent(limit)

    fun debug(message: String, source: String? = null) =
        write(AppLogLevel.Debug, message, source)

    fun info(message: String, source: String? = null) =
        write(AppLogLevel.Info, message, source)

    fun success(message: String, source: String? = null) =
        write(AppLogLevel.Success, message, source)

    fun warning(message: String, source: String? = null) =
        write(AppLogLevel.Warning, message, source)

    fun error(
        message: String,
        source: String? = null,
        error: Throwable? = null,
    ) = write(AppLogLevel.Error, message, source, error)

    private fun write(
        level: AppLogLevel,
        message: String,
        source: String? = null,
        error: Throwable? = null,
    ) {
        val fullMessage = buildString {
            append(message)
            if (error != null) {
                append(" | ")
                append(Log.getStackTraceString(error))
            }
        }
        val entry = LogEntry(
            timestampMillis = System.currentTimeMillis(),
            level = level,
            message = fullMessage,
            source = source,
        )
        logToConsole(level, entry)
        if (!_stream.tryEmit(entry)) {
            scope.launch { _stream.emit(entry) }
        }
        scope.launch {
            try {
                repository.add(entry)
            } catch (dbError: Throwable) {
                Log.w(TAG, "Failed to persist log entry", dbError)
            }
        }
    }

    private fun logToConsole(level: AppLogLevel, entry: LogEntry) {
        val text = buildString {
            append(entry.message)
            entry.source?.let { append(" (").append(it).append(')') }
        }
        runCatching {
            when (level) {
                AppLogLevel.Debug -> Log.d(TAG, text)
                AppLogLevel.Info -> Log.i(TAG, text)
                AppLogLevel.Success -> Log.i(TAG, text)
                AppLogLevel.Warning -> Log.w(TAG, text)
                AppLogLevel.Error -> Log.e(TAG, text)
            }
        }
    }

    companion object {
        private const val TAG = "SourceInstaller"

        @Volatile
        private var instance = LoggerService(InMemoryLogRepository())

        fun getInstance(): LoggerService = instance

        fun configure(repository: LogRepository) {
            instance = LoggerService(repository)
        }
    }
}
