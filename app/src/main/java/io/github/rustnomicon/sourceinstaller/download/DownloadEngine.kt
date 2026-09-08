package io.github.rustnomicon.sourceinstaller.download

import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import io.github.rustnomicon.sourceinstaller.data.DownloadedFileEntry
import io.github.rustnomicon.sourceinstaller.data.DownloadedFileRepository
import io.github.rustnomicon.sourceinstaller.data.model.DownloadState
import io.github.rustnomicon.sourceinstaller.data.model.DownloadTask
import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.net.HttpClients
import io.github.rustnomicon.sourceinstaller.scrape.BunkrSupport
import io.github.rustnomicon.sourceinstaller.service.LoggerService
import java.io.File
import java.io.IOException
import java.net.SocketTimeoutException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request

/**
 * Coroutine-based download engine (replaces the Flutter `background_downloader`
 * integration). Features of the original retained: per-item progress/state
 * updates, pause/cancel, Bunkr URL re-signing between retries, dedupe against
 * the public Downloads store, group notification.
 *
 * Improvements over the Dart version:
 *  - pause keeps partial data; resume continues with an HTTP Range request;
 *  - bounded concurrency (3 concurrent transfers) instead of unbounded fan-out;
 *  - failed/canceled tasks can be re-enqueued.
 */
class DownloadEngine(
    private val context: Context,
    private val logger: LoggerService = LoggerService.getInstance(),
    private val downloadedFiles: DownloadedFileRepository,
    private val client: OkHttpClient = HttpClients.downloader,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _tasks = MutableStateFlow<List<DownloadTask>>(emptyList())
    val tasks: StateFlow<List<DownloadTask>> = _tasks.asStateFlow()

    private val jobs = ConcurrentHashMap<String, Job>()
    private val controls = ConcurrentHashMap<String, TaskControl>()
    private val slots = Semaphore(MAX_CONCURRENT_DOWNLOADS)

    private val notifier = DownloadNotifier(context)

    /** One-shot callback fired when active downloads start/stop (drives the FGS). */
    var onActiveDownloadsChanged: ((Boolean) -> Unit)? = null

    private var foregroundActive = false

    private val downloadsDir: File by lazy {
        File(context.filesDir, "downloads").apply { mkdirs() }
    }

    init {
        scope.launch {
            tasks.collectLatest { taskList ->
                val hasActive = taskList.any {
                    it.state == DownloadState.Running || it.state == DownloadState.Queued
                }
                if (hasActive != foregroundActive) {
                    foregroundActive = hasActive
                    onActiveDownloadsChanged?.invoke(hasActive)
                }
                notifier.update(taskList)
            }
        }
    }

    // region Public API

    fun enqueue(item: MediaItem, filters: FilterSettings = FilterSettings()) {
        scope.launch { enqueueInternal(item, filters) }
    }

    fun enqueueAll(items: List<MediaItem>, filters: FilterSettings = FilterSettings()) {
        val limited = filters.downloadLimit?.let { items.take(it) } ?: items
        limited.forEach { enqueue(it, filters) }
    }

    fun pause(taskId: String) {
        val control = controls[taskId] ?: run {
            scope.launch { logger.warning("Задача не найдена для паузы", source = taskId) }
            return
        }
        control.pauseRequested.set(true)
        control.activeCall?.cancel()
        jobs[taskId]?.cancel()
        updateTask(taskId) { it.copy(state = DownloadState.Paused) }
        scope.launch { logger.info("Пауза запрошена", source = taskId) }
    }

    fun resume(taskId: String) {
        val task = _tasks.value.firstOrNull { it.id == taskId } ?: return
        if (task.state != DownloadState.Paused) return
        scope.launch { logger.info("Продолжение загрузки", source = taskId) }
        startDownloadTask(task)
    }

    fun cancel(taskId: String) {
        val control = controls[taskId]
        control?.cancelRequested?.set(true)
        control?.activeCall?.cancel()
        jobs[taskId]?.cancel()
        tempFileFor(taskId).delete()
        controls.remove(taskId)
        jobs.remove(taskId)
        updateTask(taskId) { it.copy(state = DownloadState.Canceled) }
        scope.launch {
            logger.info(
                if (control != null) "Отмена запрошена" else "Не удалось отменить задачу",
                source = taskId,
            )
        }
    }

    fun clearCompleted() {
        _tasks.value = _tasks.value.filterNot { it.state == DownloadState.Completed }
    }

    /** Cancels the engine scope; the singleton container never calls this. */
    fun shutdown() {
        scope.cancel()
    }

    // endregion

    // region Queue management

    private suspend fun enqueueInternal(item: MediaItem, filters: FilterSettings) {
        if (!filters.acceptsExtension(item.extension) || !filters.acceptsSize(item.sizeBytes)) {
            logger.warning(
                "Файл отброшен фильтрами: ${item.fileName}",
                source = item.sourceUrl,
            )
            return
        }

        val existingTask = findExistingTask(item)
        if (existingTask != null &&
            existingTask.state != DownloadState.Failed &&
            existingTask.state != DownloadState.Canceled
        ) {
            // Already queued/running/paused/completed for this media.
            return
        }
        if (existingTask != null) {
            _tasks.value = _tasks.value.filterNot { it.id == existingTask.id }
        }

        val existingPath = existingDownloadPath(item)
        if (existingPath != null) {
            upsert(
                DownloadTask(
                    id = "existing-${item.fileName}",
                    mediaItem = item,
                    progress = 1f,
                    state = DownloadState.Completed,
                    savedPath = existingPath,
                ),
            )
            logger.info(
                "Файл уже скачан, повторная загрузка пропущена: ${item.fileName}",
                source = existingPath,
            )
            return
        }

        val id = "${System.currentTimeMillis() * 1000}-${item.fileName}"
        val task = DownloadTask(id = id, mediaItem = item)
        upsert(task)
        logger.info("Добавление в очередь загрузки: ${item.fileName}", source = item.url)
        startDownloadTask(task)
    }

    private fun findExistingTask(item: MediaItem): DownloadTask? =
        _tasks.value.asReversed().firstOrNull {
            it.mediaItem.url == item.url || it.mediaItem.fileName == item.fileName
        }

    private fun startDownloadTask(task: DownloadTask) {
        controls[task.id] = TaskControl()
        jobs[task.id] = scope.launch { runDownload(task) }
    }

    private suspend fun runDownload(task: DownloadTask) {
        val control = controls[task.id] ?: TaskControl().also { controls[task.id] = it }
        val tempFile = tempFileFor(task.id)

        slots.withPermit {
            try {
                resolveAndDownload(task, control, tempFile)

                val savedPath = moveToPublicDownloads(task, tempFile)
                if (savedPath != null) {
                    downloadedFiles.add(
                        DownloadedFileEntry(
                            url = task.mediaItem.url,
                            fileName = task.mediaItem.fileName,
                            savedPath = savedPath,
                            extension = task.mediaItem.extension,
                            downloadedAtMillis = System.currentTimeMillis(),
                            sourceUrl = task.mediaItem.sourceUrl,
                        ),
                    )
                }
                updateTask(task.id) {
                    it.copy(
                        progress = 1f,
                        state = DownloadState.Completed,
                        savedPath = savedPath,
                        errorMessage = null,
                    )
                }
                logger.success("Загрузка завершена: ${task.mediaItem.fileName}", source = task.mediaItem.url)
            } catch (error: PauseException) {
                // State already flipped by pause(); keep the partial file.
            } catch (error: CancellationException) {
                if (control.cancelRequested.get()) {
                    tempFile.delete()
                }
                // State already flipped by cancel(); nothing else to do.
            } catch (error: Throwable) {
                tempFileSafeCleanupOnFailure(task, tempFile)
                updateTask(task.id) {
                    it.copy(
                        state = DownloadState.Failed,
                        errorMessage = error.message ?: error.toString(),
                    )
                }
                logger.error(
                    "Ошибка загрузки: ${task.mediaItem.fileName}",
                    source = task.mediaItem.url,
                    error = error,
                )
            } finally {
                jobs.remove(task.id)
                controls.remove(task.id)
            }
        }
    }

    private suspend fun tempFileSafeCleanupOnFailure(task: DownloadTask, tempFile: File) {
        // Keep partial files only for paused state; failures clean up so a
        // manual retry starts fresh.
        if (_tasks.value.firstOrNull { it.id == task.id }?.state != DownloadState.Paused) {
            tempFile.delete()
        }
    }

    // endregion

    // region Transfer attempts

    private suspend fun resolveAndDownload(
        task: DownloadTask,
        control: TaskControl,
        tempFile: File,
    ) {
        val item = task.mediaItem
        val isBunkr = BunkrSupport.isBunkrRelatedUrl(item.sourceUrl) ||
            BunkrSupport.isBunkrRelatedUrl(item.url)
        var attempt = 0
        var lastError: Throwable? = null

        while (attempt <= MAX_ATTEMPTS) {
            try {
                val url = if (isBunkr) resolveBunkrDownloadUrl(item) else item.url
                downloadOnce(task, control, tempFile, url, isBunkr)
                return
            } catch (error: PauseException) {
                throw error
            } catch (error: CancellationException) {
                throw error
            } catch (error: Throwable) {
                // A cancelled OkHttp call surfaces as IOException; check the
                // control flags before treating it as a retryable failure.
                if (control.pauseRequested.get()) throw PauseException()
                if (control.cancelRequested.get()) throw CancellationException("canceled")
                lastError = error
                val retryable = if (isBunkr) {
                    when {
                        error is SocketTimeoutException || error.isConnectionError() -> true
                        error is HttpStatusException -> error.code in RETRYABLE_CODES
                        else -> false
                    }
                } else {
                    error is IOException || error is HttpStatusException
                }
                if (!retryable || attempt >= MAX_ATTEMPTS) throw error

                val code = (error as? HttpStatusException)?.code?.toString() ?: "network"
                logger.warning(
                    "Временная ошибка CDN ($code), повтор ${attempt + 1}/$MAX_ATTEMPTS" +
                        if (isBunkr) " с новой подписью URL" else "",
                    source = item.url,
                )
                tempFile.delete()
                updateTask(task.id) { it.copy(progress = 0f) }
                delay((1L shl attempt) * 1000)
                attempt++
            }
        }
        throw lastError ?: IOException("Download failed")
    }

    private fun downloadOnce(
        task: DownloadTask,
        control: TaskControl,
        tempFile: File,
        url: String,
        isBunkr: Boolean,
    ) {
        updateTask(task.id) { it.copy(state = DownloadState.Running, errorMessage = null) }

        val existingBytes = if (tempFile.exists()) tempFile.length() else 0L
        if (task.state == DownloadState.Paused || existingBytes > 0) {
            logger.debug("Продолжение с позиции $existingBytes", source = url)
        }
        val requestBuilder = Request.Builder().url(url)
        if (isBunkr) {
            bunkrHeadersFor(task.mediaItem, url).forEach { (k, v) -> requestBuilder.header(k, v) }
        }
        if (existingBytes > 0) {
            requestBuilder.header("Range", "bytes=$existingBytes-")
        }

        val call = client.newCall(requestBuilder.build())
        control.activeCall = call
        try {
            call.execute().use { response ->
                if (response.code !in 200..299) throw HttpStatusException(response.code)
                val body = response.body ?: throw IOException("Empty response body")

                val resumed = existingBytes > 0 && response.code == 206
                val startOffset = if (resumed) existingBytes else 0L
                val totalBytes = body.contentLength().let { length ->
                    if (length > 0) length + startOffset else task.mediaItem.sizeBytes ?: -1L
                }

                tempFile.parentFile?.mkdirs()
                java.io.RandomAccessFile(tempFile, "rw").use { output ->
                    if (resumed) {
                        output.seek(startOffset)
                    } else {
                        // Server ignored the Range request (or a fresh attempt):
                        // restart the file from scratch.
                        output.setLength(0)
                    }

                    body.byteStream().use { input ->
                        val buffer = ByteArray(16 * 1024)
                        var written = startOffset
                        var lastProgressAt = 0L
                        while (true) {
                            if (control.pauseRequested.get()) throw PauseException()
                            if (control.cancelRequested.get()) throw CancellationException("canceled")
                            val read = input.read(buffer)
                            if (read == -1) break
                            output.write(buffer, 0, read)
                            written += read

                            val now = System.nanoTime()
                            if (now - lastProgressAt >= PROGRESS_UPDATE_INTERVAL_NS && totalBytes > 0) {
                                lastProgressAt = now
                                val progress =
                                    (written.toFloat() / totalBytes.toFloat()).coerceIn(0f, 1f)
                                updateTask(task.id) { it.copy(progress = progress) }
                            }
                        }
                    }
                }
            }
        } finally {
            control.activeCall = null
        }
    }

    // endregion

    // region Bunkr URL resolution

    private suspend fun resolveBunkrDownloadUrl(item: MediaItem): String =
        withContext(Dispatchers.IO) {
            val sourceUri = BunkrSupport.parseUri(item.sourceUrl)
            if (sourceUri != null && BunkrSupport.isBunkrFilePageUrl(sourceUri)) {
                try {
                    val requestBuilder = Request.Builder().url(item.sourceUrl)
                    BunkrSupport.bunkrPageHeaders(item.sourceUrl)
                        .forEach { (k, v) -> requestBuilder.header(k, v) }
                    val html = HttpClients.scraper.newCall(requestBuilder.build()).execute()
                        .use { response -> response.body?.string().orEmpty() }
                    val jsCdn = BunkrSupport.extractBunkrJsCdn(html)
                    if (jsCdn != null) {
                        logger.debug(
                            "Bunkr: свежий jsCDN получен со страницы файла",
                            source = item.sourceUrl,
                        )
                        return@withContext BunkrSupport.signBunkrMediaUrl(jsCdn)
                    }
                    logger.warning(
                        "Bunkr: jsCDN не найден на странице файла, использую найденный ранее URL",
                        source = item.sourceUrl,
                    )
                } catch (error: Exception) {
                    logger.warning(
                        "Bunkr: не удалось заново открыть страницу файла: $error",
                        source = item.sourceUrl,
                    )
                }
            }
            BunkrSupport.signBunkrMediaUrl(item.url)
        }

    private fun bunkrHeadersFor(item: MediaItem, downloadUrl: String): Map<String, String> =
        BunkrSupport.bunkrMediaHeaders(
            if (BunkrSupport.isBunkrRelatedUrl(item.sourceUrl)) item.sourceUrl else null,
        )

    // endregion

    // region Storage

    private suspend fun existingDownloadPath(item: MediaItem): String? {
        val recorded = downloadedFiles.findExisting(item)
        if (recorded != null) {
            if (recorded.savedPath.startsWith("content://")) return recorded.savedPath
            if (File(recorded.savedPath).exists()) return recorded.savedPath
        }
        return findInPublicDownloads(item.fileName)
    }

    private fun findInPublicDownloads(fileName: String): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val projection = arrayOf(MediaStore.Downloads._ID)
            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ?"
            try {
                context.contentResolver.query(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    arrayOf(fileName),
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(0)
                        return android.content.ContentUris.withAppendedId(
                            MediaStore.Downloads.EXTERNAL_CONTENT_URI, id,
                        ).toString()
                    }
                }
            } catch (error: Exception) {
                scope.launch {
                    logger.debug(
                        "Проверка существующего файла в Downloads не выполнена: $error",
                        source = fileName,
                    )
                }
            }
            return null
        }

        @Suppress("DEPRECATION")
        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val file = File(File(dir, "source_installer"), fileName)
        return if (file.exists()) file.absolutePath else null
    }

    private suspend fun moveToPublicDownloads(task: DownloadTask, tempFile: File): String? =
        withContext(Dispatchers.IO) {
            val item = task.mediaItem
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    val values = ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, item.fileName)
                        put(MediaStore.Downloads.MIME_TYPE, mimeTypeForExtension(item.extension))
                        put(MediaStore.Downloads.RELATIVE_PATH, "Download/source_installer")
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                    val uri = context.contentResolver.insert(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI, values,
                    ) ?: return@withContext null

                    context.contentResolver.openOutputStream(uri)?.use { output ->
                        tempFile.inputStream().use { input -> input.copyTo(output) }
                    } ?: return@withContext null

                    val done = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
                    context.contentResolver.update(uri, done, null, null)
                    tempFile.delete()

                    logger.success("Файл перемещён в Downloads", source = uri.toString())
                    return@withContext uri.toString()
                } catch (error: Throwable) {
                    logger.warning(
                        "Не удалось переместить файл в Downloads: $error",
                        source = tempFile.absolutePath,
                    )
                    return@withContext tempFile.absolutePath
                }
            }

            val hasPermission = ContextCompat.checkSelfPermission(
                context, android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) == PackageManager.PERMISSION_GRANTED
            if (!hasPermission) {
                logger.warning(
                    "Нет разрешения на запись в общее хранилище; файл оставлен во внутренней папке",
                    source = task.mediaItem.fileName,
                )
                return@withContext tempFile.absolutePath
            }

            @Suppress("DEPRECATION")
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "source_installer",
            ).apply { mkdirs() }
            val dest = uniqueFile(dir, item.fileName)
            return@withContext try {
                tempFile.copyTo(dest, overwrite = true)
                tempFile.delete()
                logger.success("Файл перемещён в Downloads", source = dest.absolutePath)
                dest.absolutePath
            } catch (error: Throwable) {
                logger.warning(
                    "Не удалось переместить файл в Downloads: $error",
                    source = tempFile.absolutePath,
                )
                tempFile.absolutePath
            }
        }

    private fun uniqueFile(dir: File, fileName: String): File {
        var candidate = File(dir, fileName)
        if (!candidate.exists()) return candidate
        val dot = fileName.lastIndexOf('.')
        val base = if (dot > 0) fileName.substring(0, dot) else fileName
        val ext = if (dot > 0) fileName.substring(dot) else ""
        var index = 1
        while (candidate.exists()) {
            candidate = File(dir, "$base ($index)$ext")
            index++
        }
        return candidate
    }

    private fun mimeTypeForExtension(extension: String): String =
        when (extension.lowercase().removePrefix(".")) {
            "mp4" -> "video/mp4"
            "webm" -> "video/webm"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            else -> "application/octet-stream"
        }

    private fun tempFileFor(taskId: String): File {
        // Task ids contain timestamps + file names with arbitrary characters;
        // the hash keeps the on-disk name safe and stable across pause/resume.
        return File(downloadsDir, "${taskId.hashCode().toUInt()}.part")
    }

    // endregion

    // region State helpers

    private fun upsert(task: DownloadTask) {
        val current = _tasks.value
        val index = current.indexOfFirst { it.id == task.id }
        _tasks.value = if (index == -1) {
            current + task
        } else {
            current.toMutableList().apply { set(index, task) }
        }
    }

    private fun updateTask(taskId: String, transform: (DownloadTask) -> DownloadTask) {
        val current = _tasks.value
        val index = current.indexOfFirst { it.id == taskId }
        if (index == -1) return
        _tasks.value = current.toMutableList().apply { set(index, transform(get(index))) }
    }

    // endregion

    private class TaskControl {
        val pauseRequested = AtomicBoolean(false)
        val cancelRequested = AtomicBoolean(false)

        @Volatile
        var activeCall: okhttp3.Call? = null
    }

    private class PauseException : Exception("Paused")

    class HttpStatusException(val code: Int) : IOException("HTTP $code")

    companion object {
        private const val MAX_CONCURRENT_DOWNLOADS = 3
        private const val MAX_ATTEMPTS = 3
        private const val PROGRESS_UPDATE_INTERVAL_NS = 200_000_000L

        private val RETRYABLE_CODES = setOf(408, 403, 404, 425, 429, 500, 502, 503, 504) +
            (520..524).toSet()

        private fun Throwable.isConnectionError(): Boolean = this is java.net.ConnectException ||
            this is java.net.NoRouteToHostException ||
            this is java.net.UnknownHostException
    }
}
