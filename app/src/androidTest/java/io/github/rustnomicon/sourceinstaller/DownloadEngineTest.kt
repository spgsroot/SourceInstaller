package io.github.rustnomicon.sourceinstaller

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.github.rustnomicon.sourceinstaller.data.model.DownloadState
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.download.DownloadEngine
import java.io.File
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import okio.Buffer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented pause/resume test for [DownloadEngine] against an in-process
 * throttled HTTP server. Verifies observable contract: pause stops mid-flight
 * and keeps the partial file, resume continues with an HTTP Range request from
 * the partial offset, and the completed artifact has exactly the full payload.
 */
@RunWith(AndroidJUnit4::class)
class DownloadEngineTest {

    private lateinit var context: Context
    private lateinit var server: MockWebServer
    // path -> Range header value, as observed by the dispatcher at dispatch time.
    private val seenRequests = java.util.concurrent.CopyOnWriteArrayList<Pair<String, String?>>()

    private val payload = ByteArray(2 * 1024 * 1024) { (it % 251).toByte() }

    @Before
    fun setUp() {
        context = InstrumentationRegistry.getInstrumentation().targetContext
        // Each run starts from an empty temp-download directory so partial-size
        // assertions only observe this test's artifact.
        File(context.filesDir, "downloads").deleteRecursively()
        // Purge artifacts of a previous incomplete run so downloads are not
        // deduped as already-completed.
        context.contentResolver.delete(
            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            "${android.provider.MediaStore.MediaColumns.DATA} LIKE ?",
            arrayOf("%test-range-resume%"),
        )

        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                seenRequests += (request.path ?: "") to request.headers["Range"]
                val range = request.headers["Range"]
                val offset = if (range == null) 0 else {
                    range.removePrefix("bytes=").substringBefore('-').toInt()
                }
                return MockResponse()
                    .setResponseCode(if (range == null) 200 else 206)
                    .setHeader("Accept-Ranges", "bytes")
                    .setBody(Buffer().write(payload, offset, payload.size - offset))
                    .throttleBody(64 * 1024, 60, TimeUnit.MILLISECONDS)
            }
        }
        server.start()
    }

    @After
    fun tearDown() {
        server.shutdown()
        context.contentResolver.delete(
            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            "${android.provider.MediaStore.MediaColumns.DATA} LIKE ?",
            arrayOf("%test-range-resume%"),
        )
        File(context.filesDir, "downloads").deleteRecursively()
    }

    @Test
    fun pauseKeepsPartialAndResumeCompletesWithRangeRequest() = runBlocking {
        val engine = DownloadEngine(
            context,
            downloadedFiles = io.github.rustnomicon.sourceinstaller.data.InMemoryDownloadedFileRepository(),
        )
        val item = MediaItem(
            url = server.url("/file.mp4").toString(),
            fileName = "test-range-resume.mp4",
            extension = "mp4",
            sourceUrl = server.url("/").toString(),
        )

        engine.enqueue(item)
        val task = awaitTaskState(engine, item.fileName, DownloadState.Running, timeoutMs = 15_000)
        assertTrue("task must become Running", task.state == DownloadState.Running)

        delay(800) // let a partial body accumulate
        engine.pause(task.id)
        val paused = awaitTaskState(engine, item.fileName, DownloadState.Paused, timeoutMs = 15_000)
        assertEquals("expected Paused, states=${engine.tasks.value}", DownloadState.Paused, paused.state)

        val partial = File(context.filesDir, "downloads").listFiles()?.singleOrNull()
        assertTrue("partial file must exist after pause", partial != null && partial.length() > 0)
        assertTrue(
            "partial file must be smaller than the full payload",
            partial!!.length() < payload.size,
        )
        val partialBytes = partial.length()

        engine.resume(task.id)
        val completed = awaitTaskState(
            engine, item.fileName, DownloadState.Completed, timeoutMs = 60_000,
        )
        assertEquals("expected Completed, states=${engine.tasks.value}", DownloadState.Completed, completed.state)

        // Resume MUST have issued a Range request starting at the partial offset.
        val resumeRequest = seenRequests.drop(1).firstOrNull { it.first == "/file.mp4" }
        assertEquals(
            "resume request Range header; seen=$seenRequests",
            "bytes=$partialBytes-",
            resumeRequest?.second,
        )

        assertNotEquals(null, completed.savedPath)
        // Exact payload bytes on the merged file prove the range continuation
        // landed at the right offset.
        val merged = File(context.filesDir, "downloads").listFiles()?.firstOrNull()
        assertTrue("temp file must be consumed by the move", merged == null)
        assertEquals(1f, completed.progress, 0.001f)

        engine.shutdown()
    }

    private suspend fun awaitTaskState(
        engine: DownloadEngine,
        fileName: String,
        state: DownloadState,
        timeoutMs: Long,
    ): io.github.rustnomicon.sourceinstaller.data.model.DownloadTask {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            val task = engine.tasks.value.firstOrNull { it.mediaItem.fileName == fileName }
            if (task != null && task.state == state) return task
            delay(50)
        }
        return engine.tasks.value.first { it.mediaItem.fileName == fileName }
    }
}
