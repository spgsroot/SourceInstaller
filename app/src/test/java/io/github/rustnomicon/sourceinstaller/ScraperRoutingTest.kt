package io.github.rustnomicon.sourceinstaller

import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.errors.ScrapeException
import io.github.rustnomicon.sourceinstaller.scrape.BaseScraper
import io.github.rustnomicon.sourceinstaller.scrape.RedditScraper
import io.github.rustnomicon.sourceinstaller.scrape.StaticBoardScraper
import io.github.rustnomicon.sourceinstaller.scrape.selectScraper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class ScraperRoutingTest {

    private class FakeScraper(private val marker: String) : BaseScraper {
        override fun canHandle(url: String): Boolean = url.contains(marker)
        override suspend fun extractMedia(
            url: String,
            filters: FilterSettings,
        ): List<MediaItem> = emptyList()
    }

    @Test
    fun `selectScraper returns the first scraper that can handle the URL`() {
        val first = FakeScraper("a.example")
        val second = FakeScraper("example")
        val selected = selectScraper("https://a.example/page", listOf(first, second))
        assertSame(first, selected)
    }

    @Test(expected = ScrapeException::class)
    fun `selectScraper throws when nothing matches`() {
        selectScraper("https://unknown.example", listOf(FakeScraper("zyxwvut")))
    }

    @Test
    fun `static board scraper handles known board hosts`() {
        val scraper = StaticBoardScraper()
        assertTrue(scraper.canHandle("https://2ch.hk/b/res/1.html"))
        assertTrue(scraper.canHandle("https://boards.4channel.org/g/thread/1"))
        assertTrue(scraper.canHandle("https://www.4chan.org/x"))
        assertTrue(scraper.canHandle("https://lainchan.org/r/res/1.html"))
        assertTrue(scraper.canHandle("https://endchan.net/b/res/1.html"))
        assertFalse(scraper.canHandle("https://www.reddit.com/r/test"))
        assertFalse(scraper.canHandle("not a url"))
    }

    @Test
    fun `reddit scraper handles reddit media and post hosts`() {
        val scraper = RedditScraper()
        assertTrue(scraper.canHandle("https://www.reddit.com/r/test/comments/abc/x/"))
        assertTrue(scraper.canHandle("https://redd.it/abcd123"))
        assertTrue(scraper.canHandle("https://i.redd.it/pic.jpg"))
        assertTrue(scraper.canHandle("https://v.redd.it/xyz/DASH_720.mp4"))
        assertTrue(scraper.canHandle("https://packaged-media.redd.it/a.mp4"))
        assertFalse(scraper.canHandle("https://2ch.hk/b/"))
    }
}
