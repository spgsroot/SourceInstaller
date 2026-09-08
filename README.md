# SourceInstaller

The ultimate media installer for Reddit, Bunkr, Redgifs, and textboards/imageboards such as 2ch, 4chan, Lainchan, and Endchan.

SourceInstaller is a native Android app (Kotlin + Jetpack Compose) for finding, previewing, filtering, queueing, and downloading media from supported web sources. It was rewritten from Flutter to a fully native stack.

<p align="center">
  <img src="preview/icon.png" alt="SourceInstaller icon" width="128" />
</p>

## Stack

- Kotlin, Jetpack Compose (Material 3), MVVM with `ViewModel` + `StateFlow`
- OkHttp + Jsoup for static scraping
- Android `WebView` for dynamic sources and anti-bot challenge handling
- Room for logs/history/download history, Preferences DataStore for filter settings
- Coroutine-based download engine with pause/resume (HTTP Range), bounded concurrency, retries with Bunkr URL re-signing

## Features

- Extract videos and media links from supported sources.
- Bunkr single-file and album support with refreshed video previews.
- Reddit post/media parsing (JSON API + HTML fallback + WebView fallback).
- Redgifs extraction via visible WebView with automatic challenge continuation.
- Static textboard/imageboard parsing for 2ch, 4chan/4channel, Lainchan, and Endchan.
- In-app media preview for videos and images.
- Bulk download queue with per-item progress, pause, resume, and cancel.
- Filters for video-only mode, minimum file size, and bulk download limits.
- Downloads land in the public `Downloads/source_installer` folder with progress notifications.
- Localized UI: English and Russian.
- CI/CD ready: GitHub Actions runs unit tests and builds release APKs.

## Supported sources

| Source | Status |
|---|---|
| Reddit | Posts and media URLs |
| Bunkr | Direct media, file pages, albums, refreshed previews |
| Redgifs | Visible WebView extraction |
| Textboards/imageboards | 2ch, 4chan/4channel, Lainchan, Endchan |

## Download APK

- Every push to `main`/`master` produces APK artifacts in GitHub Actions.
- Pushing a tag like `v1.0.0` creates a GitHub Release and attaches generated APK files.

## Local development

Prerequisites:

- JDK 17
- Android SDK (platform 36, build-tools 36.0.0)

```bash
./gradlew :app:testDebugUnitTest
./gradlew :app:assembleDebug
./gradlew :app:assembleRelease
```

APKs are written to:

```text
app/build/outputs/apk/
```

## CI/CD

The workflow in `.github/workflows/android-apk.yml` runs:

1. `./gradlew :app:testDebugUnitTest`
2. `./gradlew :app:assembleRelease`
3. Upload APK artifacts
4. Create a GitHub Release for `v*` tags

### Optional release signing

Without signing secrets, CI falls back to the debug signing config so APK generation works for every fork. For production-style releases, add these GitHub repository secrets:

- `ANDROID_KEYSTORE_BASE64` — base64-encoded JKS/keystore
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Then push a release tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## License

MIT. See [LICENSE](LICENSE).
