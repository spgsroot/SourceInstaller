package io.github.rustnomicon.sourceinstaller

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FilterSettingsTest {

    @Test
    fun `defaults match the Flutter model`() {
        val filters = FilterSettings()
        assertTrue(filters.onlyVideo)
        assertFalse(filters.ignoreSmallFiles)
        assertNull(filters.minSizeBytes)
        assertNull(filters.downloadLimit)
        assertEquals(setOf("mp4", "webm"), filters.allowedExtensions)
        assertNull(filters.effectiveMinSizeBytes)
    }

    @Test
    fun `ignoreSmallFiles applies 2MB threshold when no explicit minimum`() {
        val filters = FilterSettings(ignoreSmallFiles = true)
        assertEquals(FilterSettings.DEFAULT_SMALL_FILE_THRESHOLD_BYTES, filters.effectiveMinSizeBytes)
    }

    @Test
    fun `explicit min size wins over ignoreSmallFiles`() {
        val filters = FilterSettings(ignoreSmallFiles = true, minSizeBytes = 1024)
        assertEquals(1024L, filters.effectiveMinSizeBytes)
    }

    @Test
    fun `acceptsExtension enforces video-only mode`() {
        val filters = FilterSettings(onlyVideo = true)
        assertTrue(filters.acceptsExtension("mp4"))
        assertTrue(filters.acceptsExtension("webm"))
        assertFalse(filters.acceptsExtension("jpg"))
    }

    @Test
    fun `acceptsExtension respects allowed set when images enabled`() {
        val filters = FilterSettings(onlyVideo = false, allowedExtensions = setOf("png"))
        assertTrue(filters.acceptsExtension(".png"))
        assertFalse(filters.acceptsExtension("mp4"))
    }

    @Test
    fun `acceptsSize semantics match the Dart implementation`() {
        val permissive = FilterSettings()
        assertTrue(permissive.acceptsSize(null))
        assertTrue(permissive.acceptsSize(1))

        val minimum = FilterSettings(minSizeBytes = 1024)
        assertTrue(minimum.acceptsSize(null))
        assertTrue(minimum.acceptsSize(1024))
        assertFalse(minimum.acceptsSize(1023))
    }
}

class MediaItemContractTest {
    @Test
    fun `media item keeps scraper fields`() {
        val item = MediaItem(
            url = "https://cdn.example.com/a.mp4",
            fileName = "a.mp4",
            extension = "mp4",
            sourceUrl = "https://example.com/post",
            sizeBytes = 100,
            quality = "720p",
        )
        assertEquals("720p", item.quality)
        assertEquals(100L, item.sizeBytes)
    }
}
