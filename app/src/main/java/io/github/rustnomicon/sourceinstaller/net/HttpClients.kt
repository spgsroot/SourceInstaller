package io.github.rustnomicon.sourceinstaller.net

import java.util.concurrent.TimeUnit
import okhttp3.OkHttpClient

const val DESKTOP_USER_AGENT =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) " +
        "Chrome/120.0.0.0 Safari/537.36"

const val MOBILE_USER_AGENT =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) " +
        "Chrome/125.0.0.0 Safari/537.36"

const val HTML_ACCEPT =
    "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

object HttpClients {

    /** General scraping client: desktop UA, 15s connect / 20s read. */
    val scraper: OkHttpClient by lazy {
        base()
            .newBuilder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .build()
    }

    /** Download client with a longer read allowance. */
    val downloader: OkHttpClient by lazy {
        base()
            .newBuilder()
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .build()
    }

    private fun base(): OkHttpClient {
        return OkHttpClient.Builder()
            .followRedirects(true)
            .followSslRedirects(true)
            .addInterceptor { chain ->
                chain.proceed(
                    chain.request()
                        .newBuilder()
                        .header("User-Agent", DESKTOP_USER_AGENT)
                        .build(),
                )
            }
            .build()
    }
}
