package io.github.rustnomicon.sourceinstaller

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.scrape.BunkrSupport
import io.github.rustnomicon.sourceinstaller.scrape.DynamicWebViewScraper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BunkrSupportTest {

    @Test
    fun `isBunkrRelatedHost covers bunkr fronts and CDNs`() {
        assertTrue(BunkrSupport.isBunkrRelatedHost("bunkr.cr"))
        assertTrue(BunkrSupport.isBunkrRelatedHost("bunkr.sk"))
        assertTrue(BunkrSupport.isBunkrRelatedHost("media-files6.cdn.cr"))
        assertTrue(BunkrSupport.isBunkrRelatedHost("gigachad-cdn.example.com"))
        assertTrue(BunkrSupport.isBunkrRelatedHost("bnkr.b-cdn.net"))
        assertFalse(BunkrSupport.isBunkrRelatedHost("reddit.com"))
    }

    @Test
    fun `isBunkrFilePageUrl matches single-file paths`() {
        assertTrue(
            BunkrSupport.isBunkrFilePageUrl(
                BunkrSupport.parseUri("https://bunkr.cr/f/abc123")!!,
            ),
        )
        assertTrue(
            BunkrSupport.isBunkrFilePageUrl(
                BunkrSupport.parseUri("https://bunkr.cr/v/xyz")!!,
            ),
        )
        assertFalse(
            BunkrSupport.isBunkrFilePageUrl(
                BunkrSupport.parseUri("https://bunkr.cr/a/album")!!,
            ),
        )
        assertFalse(
            BunkrSupport.isBunkrFilePageUrl(
                BunkrSupport.parseUri("https://example.com/f/abc")!!,
            ),
        )
    }

    @Test
    fun `bunkrAdvancedAlbumUrl adds and preserves query params`() {
        assertEquals(
            "https://bunkr.cr/a/album?advanced=1",
            BunkrSupport.bunkrAdvancedAlbumUrl("https://bunkr.cr/a/album"),
        )
        val withBoth = BunkrSupport.bunkrAdvancedAlbumUrl("https://bunkr.cr/a/album?x=y")
        assertTrue(withBoth.contains("x=y"))
        assertTrue(withBoth.contains("advanced=1"))
    }

    @Test
    fun `visibleChallengeUrlFor upgrades only album URLs`() {
        assertEquals(
            "https://bunkr.cr/a/album?advanced=1",
            BunkrSupport.visibleChallengeUrlFor("https://bunkr.cr/a/album"),
        )
        assertEquals(
            "https://bunkr.cr/f/file",
            BunkrSupport.visibleChallengeUrlFor("https://bunkr.cr/f/file"),
        )
        assertEquals(
            "https://www.redgifs.com/watch/id",
            BunkrSupport.visibleChallengeUrlFor("https://www.redgifs.com/watch/id"),
        )
    }

    @Test
    fun `extractBunkrJsCdn validates host and extension`() {
        val html = """<script>var jsCDN = "https://media-files9.cdn.cr/storage/media/movie.mp4";</script>"""
        assertEquals(
            "https://media-files9.cdn.cr/storage/media/movie.mp4",
            BunkrSupport.extractBunkrJsCdn(html),
        )
        assertNull(BunkrSupport.extractBunkrJsCdn("""var jsCDN = "https://evil.example.com/a.mp4";"""))
        assertNull(BunkrSupport.extractBunkrJsCdn("""var jsCDN = "https://media-files9.cdn.cr/a.zip";"""))
        assertNull(BunkrSupport.extractBunkrJsCdn("<html></html>"))
    }

    @Test
    fun `bunkrSignPath only accepts sign urls with video paths`() {
        assertEquals(
            "/storage/media/clip.mp4",
            BunkrSupport.bunkrSignPath(
                "https://glb-apisign.cdn.cr/sign?path=%2Fstorage%2Fmedia%2Fclip.mp4",
            ),
        )
        assertNull(BunkrSupport.bunkrSignPath("https://glb-apisign.cdn.cr/sign?path=%2Fa.txt"))
        assertNull(BunkrSupport.bunkrSignPath("https://bunkr.cr/sign?path=/clip.mp4"))
    }

    @Test
    fun `sizeBytesFromHeaders reads content-length or range tail`() {
        assertEquals(1024L, BunkrSupport.sizeBytesFromHeaders("1024", null))
        assertEquals(2048L, BunkrSupport.sizeBytesFromHeaders(null, "bytes 0-1023/2048"))
        assertNull(BunkrSupport.sizeBytesFromHeaders(null, null))
    }

    @Test
    fun `mediaItemDedupeKey strips query only on bunkr hosts`() {
        assertEquals(
            "https://media-files9.cdn.cr/a.mp4",
            BunkrSupport.mediaItemDedupeKey("https://media-files9.cdn.cr/a.mp4?token=1"),
        )
        assertEquals(
            "https://other.example/a.mp4?token=1",
            BunkrSupport.mediaItemDedupeKey("https://other.example/a.mp4?token=1"),
        )
    }
}

class DynamicScraperParsingTest {

    private val scraper = DynamicWebViewScraper()

    @Test
    fun `parseSizeBytes handles plain numbers and units`() {
        assertEquals(42L, scraper.parseSizeBytes(42))
        assertEquals(42L, scraper.parseSizeBytes("42"))
        assertEquals(1024L, scraper.parseSizeBytes("1 KB"))
        assertEquals((1.5 * 1024 * 1024).toLong(), scraper.parseSizeBytes("1,5 MB"))
        assertEquals(2L * 1024 * 1024 * 1024, scraper.parseSizeBytes("2 GiB"))
        assertNull(scraper.parseSizeBytes(""))
        assertNull(scraper.parseSizeBytes("unknown"))
    }

    @Test
    fun `extensionFromHint maps loose hints`() {
        assertEquals("mp4", scraper.extensionFromHint("video/mp4"))
        assertEquals("webm", scraper.extensionFromHint(".WebM"))
        assertEquals("jpg", scraper.extensionFromHint("jpeg"))
        assertNull(scraper.extensionFromHint("zip"))
        assertNull(scraper.extensionFromHint(null))
    }

    @Test
    fun `redgifsMediaRank prefers hd over sd over mobile`() {
        assertEquals(1, scraper.redgifsMediaRank("https://media.redgifs.com/abc.mp4"))
        assertEquals(2, scraper.redgifsMediaRank("https://media.redgifs.com/sd.mp4"))
        assertEquals(3, scraper.redgifsMediaRank("https://media.redgifs.com/abc-mobile.mp4"))
    }

    @Test
    fun `sameWebViewPage compares host path and advanced flag`() {
        assertTrue(
            scraper.sameWebViewPage(
                "https://bunkr.cr/a/x?advanced=1",
                "https://bunkr.cr/a/x?advanced=1",
            ),
        )
        assertFalse(
            scraper.sameWebViewPage(
                "https://bunkr.cr/a/x",
                "https://bunkr.cr/a/x?advanced=1",
            ),
        )
        assertTrue(
            scraper.sameWebViewPage(
                "https://bunkr.cr/f/abc?utm=1",
                "https://bunkr.cr/f/abc",
            ),
        )
        assertFalse(
            scraper.sameWebViewPage("https://bunkr.cr/f/abc", "https://other.cr/f/abc"),
        )
    }

    @Test
    fun `parseBunkrCandidates filters by settings and keeps direct urls`() {
        val payload = """"[{\"url\":\"https://bunkr.cr/f/1\",\"extension\":\"mp4\",\"size\":3145728,\"directUrl\":\"https://media-files9.cdn.cr/a.mp4\"},{\"url\":\"https://bunkr.cr/f/2\",\"extension\":\"jpg\",\"size\":100},{\"url\":\"https://bunkr.cr/f/3\",\"extension\":\"mp4\",\"size\":1024}]""""
        val candidates = scraper.parseBunkrCandidates(
            payload,
            FilterSettings(onlyVideo = true, ignoreSmallFiles = true),
        )
        assertEquals(1, candidates.size)
        val candidate = candidates[0]
        assertEquals("https://bunkr.cr/f/1", candidate.url)
        assertEquals("https://media-files9.cdn.cr/a.mp4", candidate.directMediaUrl)
        assertEquals(3145728L, candidate.sizeBytes)
    }

    @Test
    fun `media candidate detection accepts direct video and sign urls`() {
        assertTrue(scraper.isBunkrMediaCandidate("https://media-files9.cdn.cr/a.mp4?token=1"))
        assertTrue(
            scraper.isBunkrMediaCandidate(
                "https://glb-apisign.cdn.cr/sign?path=%2Fstorage%2Fmedia%2Fclip.webm",
            ),
        )
        assertFalse(scraper.isBunkrMediaCandidate("https://bunkr.cr/f/page"))
    }

    @Test
    fun `bunkrMediaUrlFromCandidate translates sign urls via cdn hint`() {
        val hints = io.github.rustnomicon.sourceinstaller.scrape.BunkrPageHints(
            cdn = "https://media-files9.cdn.cr",
        )
        val url = scraper.bunkrMediaUrlFromCandidate(
            "https://glb-apisign.cdn.cr/sign?path=%2Fstorage%2Fmedia%2Fclip.mp4",
            hints,
        )
        assertNotNull(url)
        assertTrue(url!!.startsWith("https://media-files9.cdn.cr/storage/media/clip.mp4"))

        val direct = scraper.bunkrMediaUrlFromCandidate(
            "https://media-files9.cdn.cr/direct.webm",
            hints,
        )
        assertEquals("https://media-files9.cdn.cr/direct.webm", direct)
    }
}
