# Changelog

## 2.0.0

- Rewrote the app from Flutter to native Kotlin + Jetpack Compose.
- Replaced Riverpod with `ViewModel`/`StateFlow` MVVM, Isar with Room, filter settings moved to Preferences DataStore.
- Replaced Dio with OkHttp and the `html` package with Jsoup.
- Replaced `background_downloader` with a coroutine download engine: pause keeps partial data, resume continues with HTTP Range requests, concurrency bounded to 3 transfers, failed/canceled tasks can be re-enqueued.
- Dropped the unreachable headless WebView scraper flows; Bunkr/Redgifs extraction runs through the visible challenge WebView with automatic continuation.
- Shared the Bunkr URL signing/size logic between scraper, downloads, and preview instead of three copies.
- Downloads publish to the public `Downloads/source_installer` folder via MediaStore.

## 1.0.0

- Initial GitHub-ready release metadata.
- Android APK CI/CD workflow.
- README with screenshots from `preview/`.
- Support summary for Reddit, Bunkr, Redgifs, and textboards/imageboards.
