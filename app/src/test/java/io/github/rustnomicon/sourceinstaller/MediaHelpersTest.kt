package io.github.rustnomicon.sourceinstaller

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.scrape.applyMediaFilters
import io.github.rustnomicon.sourceinstaller.scrape.fileNameFromUrl
import io.github.rustnomicon.sourceinstaller.scrape.mediaExtensionFromUrl
import io.github.rustnomicon.sourceinstaller.scrape.qualityFromFileName
import io.github.rustnomicon.sourceinstaller.util.formatBytes
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MediaHelpersTest {

    @Test
    fun `mediaExtensionFromUrl extracts supported extensions from path`() {
        assertEquals("mp4", mediaExtensionFromUrl("https://a.b/video.MP4?token=1"))
        assertEquals("webp", mediaExtensionFromUrl("https://a.b/x/y/pic.webp"))
        assertNull(mediaExtensionFromUrl("https://a.b/file.zip"))
        assertNull(mediaExtensionFromUrl("https://a.b/noextension"))
    }

    @Test
    fun `fileNameFromUrl decodes the last path segment`() {
        assertEquals("movie.mp4", fileNameFromUrl("https://a.b/dir/movie.mp4?x=1"))
        assertEquals("my file.mp4", fileNameFromUrl("https://a.b/dir/my%20file.mp4"))
        assertEquals("media", fileNameFromUrl("https://a.b/"))
        assertEquals("media", fileNameFromUrl("not a url"))
    }

    @Test
    fun `qualityFromFileName finds resolution markers`() {
        assertEquals("1080p", qualityFromFileName("cool-1080p.mp4"))
        assertEquals("720p", qualityFromFileName("720P.webm"))
        assertEquals("1080p", qualityFromFileName("cool1080p.mp4"))
        assertNull(qualityFromFileName("no-marker.mp4"))
    }

    @Test
    fun `applyMediaFilters composes extension and size checks`() {
        val items = listOf(
            MediaItem("https://a/1.mp4", "1.mp4", "mp4", "src", sizeBytes = 3L * 1024 * 1024),
            MediaItem("https://a/2.mp4", "2.mp4", "mp4", "src", sizeBytes = 1L * 1024 * 1024),
            MediaItem("https://a/3.jpg", "3.jpg", "jpg", "src", sizeBytes = 9L * 1024 * 1024),
        )
        val filtered = applyMediaFilters(items, FilterSettings(ignoreSmallFiles = true))
        assertEquals(listOf("1.mp4"), filtered.map { it.fileName })
    }

    @Test
    fun `formatBytes matches the Flutter formatter`() {
        assertNull(formatBytes(null))
        assertNull(formatBytes(-1))
        assertEquals("0 B", formatBytes(0))
        assertEquals("512 B", formatBytes(512))
        assertEquals("1.0 KB", formatBytes(1024))
        assertEquals("10 KB", formatBytes(10 * 1024))
        assertEquals("2.0 MB", formatBytes(2L * 1024 * 1024))
        assertEquals("1.5 GB", formatBytes(1610612736))
    }
}
