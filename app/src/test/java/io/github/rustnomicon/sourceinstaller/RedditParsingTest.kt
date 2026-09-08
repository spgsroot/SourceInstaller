package io.github.rustnomicon.sourceinstaller

import io.github.rustnomicon.sourceinstaller.scrape.RedditScraper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RedditParsingTest {

    private val scraper = RedditScraper()

    @Test
    fun `jsonEndpointFor maps reddit URLs to the comments JSON endpoint`() {
        assertEquals(
            "https://www.reddit.com/comments/abc123/.json?raw_json=1",
            scraper.jsonEndpointFor("https://www.reddit.com/r/videos/comments/abc123/title/"),
        )
        assertEquals(
            "https://www.reddit.com/comments/xyz789/.json?raw_json=1",
            scraper.jsonEndpointFor("https://redd.it/xyz789"),
        )
        assertEquals(
            "https://www.reddit.com/comments/gal42/.json?raw_json=1",
            scraper.jsonEndpointFor("https://www.reddit.com/gallery/gal42"),
        )
        assertEquals(null, scraper.jsonEndpointFor("https://i.redd.it/image.jpg"))
        assertEquals(null, scraper.jsonEndpointFor("https://example.com/comments/abc"))
    }

    @Test
    fun `isRedditShareUrl detects short share links`() {
        assertTrue(scraper.isRedditShareUrl("https://www.reddit.com/r/funny/s/AbcDefGh"))
        assertFalse(scraper.isRedditShareUrl("https://www.reddit.com/r/funny/comments/abc/x"))
        assertFalse(scraper.isRedditShareUrl("https://example.com/s/foo"))
    }

    @Test
    fun `qualityFromRedditUrl reads the DASH height`() {
        assertEquals("720p", scraper.qualityFromRedditUrl("https://v.redd.it/id/DASH_720.mp4"))
        assertEquals(null, scraper.qualityFromRedditUrl("https://i.redd.it/a.jpg"))
    }

    @Test
    fun `cleanUrl normalizes escapes and strips trailing punctuation`() {
        assertEquals(
            "https://i.redd.it/pic.jpg?x=1&y=2",
            scraper.cleanUrl("https://i.redd.it/pic.jpg?x=1&amp;y=2)."),
        )
        assertEquals(
            "https://v.redd.it/id/DASH_720.mp4",
            scraper.cleanUrl("""https:\/\/v.redd.it\/id\/DASH_720.mp4"""),
        )
        assertEquals(null, scraper.cleanUrl("not-a-url"))
    }

    @Test
    fun `extractVRedditIds dedupes video ids`() {
        val html = """a https://v.redd.it/abc123/DASH_720.mp4 b https://v.redd.it/abc123/x c"""
        assertEquals(setOf("abc123"), scraper.extractVRedditIds(html))
    }

    @Test
    fun `redditRank orders qualities then hosts`() {
        // dash_1080 < dash_720 < dash_480 < packaged-media < v.redd.it < i.redd.it < rest
        assertTrue(scraper.redditRank("https://v.redd.it/a/DASH_1080.mp4") < scraper.redditRank("https://v.redd.it/a/DASH_720.mp4"))
        assertTrue(scraper.redditRank("https://v.redd.it/a/DASH_720.mp4") < scraper.redditRank("https://v.redd.it/a/DASH_480.mp4"))
        assertTrue(scraper.redditRank("https://v.redd.it/a/DASH_480.mp4") < scraper.redditRank("https://packaged-media.redd.it/a.mp4"))
        assertTrue(scraper.redditRank("https://v.redd.it/a/DASH_96.mp4") < scraper.redditRank("https://i.redd.it/a.jpg"))
    }

    @Test
    fun `extractItemsFromHtml collects direct and encoded media urls`() {
        val html = buildString {
            append("<a href=\"https://i.redd.it/direct.jpg\">img</a>")
            append("<video src=\"https://v.redd.it/vid1/DASH_1080.mp4?source=fallback\"></video>")
            append("<a href=\"https://outbound.test/away?url=https%3A%2F%2Fi.redd.it%2Fencoded.png\">x</a>")
        }
        val items = scraper.extractItemsFromHtml(html, "https://www.reddit.com/r/t/comments/id/t")
        val urls = items.map { it.url }
        assertTrue(urls.any { it.contains("i.redd.it/direct.jpg") })
        assertTrue(urls.any { it.contains("DASH_1080") })
        assertTrue(urls.any { it.contains("i.redd.it/encoded.png") })
        assertEquals("1080p", items.first { it.url.contains("DASH_1080") }.quality)
    }

    @Test
    fun `dedupeByFile merges v redd it variants by video id`() {
        val item480 = scraper.directMediaItem(
            "https://v.redd.it/sameid/DASH_480.mp4", sourceUrl = "s",
        )!!
        val item720 = scraper.directMediaItem(
            "https://v.redd.it/sameid/DASH_720.mp4", sourceUrl = "s",
        )!!
        val deduped = scraper.dedupeByFile(listOf(item480, item720))
        assertEquals(1, deduped.size)
    }

    @Test
    fun `submissionFromListing drills into the first child data`() {
        val json = """[{"kind":"Listing","data":{"children":[{"kind":"t3","data":{"id":"abc","url":"https://i.redd.it/pic.jpg"}}]}}]"""
        val submission = scraper.submissionFromListing(json)
        assertEquals("abc", submission?.get("id")?.toString()?.trim('"'))
        assertEquals(null, scraper.submissionFromListing("not json"))
        assertEquals(null, scraper.submissionFromListing("{}"))
    }
}
