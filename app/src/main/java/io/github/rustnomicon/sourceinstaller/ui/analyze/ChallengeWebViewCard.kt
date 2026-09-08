package io.github.rustnomicon.sourceinstaller.ui.analyze

import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.errors.CaptchaRequiredException
import io.github.rustnomicon.sourceinstaller.scrape.BunkrSupport
import io.github.rustnomicon.sourceinstaller.scrape.ScraperScripts
import io.github.rustnomicon.sourceinstaller.scrape.webview.MediaUrlCapture
import io.github.rustnomicon.sourceinstaller.scrape.webview.decodeStringMap
import io.github.rustnomicon.sourceinstaller.scrape.webview.evaluateJs
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun ErrorCard(
    error: Throwable,
    analysisUrl: String,
    viewModel: AnalyzeViewModel,
) {
    if (error is CaptchaRequiredException && error.source != null) {
        ChallengeWebViewCard(
            challengeUrl = BunkrSupport.visibleChallengeUrlFor(
                analysisUrl.ifEmpty { error.source!! },
            ),
            analysisUrl = analysisUrl.ifEmpty { error.source!! },
            viewModel = viewModel,
        )
        return
    }

    Card(colors = CardDefaults.cardColors(MaterialTheme.colorScheme.errorContainer)) {
        Text(
            error.toString(),
            modifier = Modifier.padding(16.dp),
            color = MaterialTheme.colorScheme.onErrorContainer,
        )
    }
}

private val MEDIA_URL_REGEX = Regex("""\.(mp4|webm)([?#]|$)""", RegexOption.IGNORE_CASE)
private val BUNKR_SIGN_REGEX = Regex(
    """https?://glb-apisign\.cdn\.cr/sign\?[^\s]*path=[^\s]*\.(mp4|webm)(?:[&#]|$)""",
    RegexOption.IGNORE_CASE,
)

/** Visible WebView card for protected sources. Port of `_ChallengeWebViewCard`. */
@Composable
fun ChallengeWebViewCard(
    challengeUrl: String,
    analysisUrl: String,
    viewModel: AnalyzeViewModel,
) {
    val scope = rememberCoroutineScope()

    var webView by remember { mutableStateOf<WebView?>(null) }
    var progress by remember { mutableIntStateOf(0) }
    var continuing by remember { mutableStateOf(false) }
    var checking by remember { mutableStateOf(false) }
    var checkJob by remember { mutableStateOf<Job?>(null) }

    val capture = remember {
        MediaUrlCapture(accept = { url ->
            MEDIA_URL_REGEX.containsMatchIn(url) || BUNKR_SIGN_REGEX.containsMatchIn(url)
        })
    }

    fun continueAnalysis() {
        val view = webView ?: return
        if (continuing) return
        continuing = true
        scope.launch {
            try {
                viewModel.analyzeWithWebView(
                    analysisUrl,
                    view,
                    capturedMediaUrls = capture.snapshot,
                )
                viewModel.awaitAnalysisSettled()
            } finally {
                continuing = false
            }
        }
    }

    fun scheduleChallengeCheck(delayMs: Long = 900) {
        if (continuing) return
        checkJob?.cancel()
        checkJob = scope.launch {
            delay(delayMs)
            val view = webView ?: return@launch
            if (continuing || checking) return@launch
            checking = true
            try {
                val pageState = try {
                    decodeStringMap(view.evaluateJs(ScraperScripts.CHALLENGE_STATE_PROBE))
                } catch (e: CancellationException) {
                    throw e
                } catch (_: Exception) {
                    emptyMap()
                }

                val hasClearanceCookie = hasClearanceCookie(view, challengeUrl, analysisUrl)
                val ready = pageState["ready"] == "true"
                val hasBody = pageState["hasBody"] == "true"
                val hasMediaHints = pageState["hasMediaHints"] == "true"
                val hasChallenge = pageState["challenge"] == "true"
                val hasNetworkError = pageState["networkError"] == "true"

                val hasCapturedMedia = capture.snapshot.isNotEmpty()
                val pageLooksReady = ready && hasBody && hasMediaHints

                if (!hasNetworkError &&
                    (hasCapturedMedia || (!hasChallenge && (hasClearanceCookie || pageLooksReady)))
                ) {
                    continueAnalysis()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                // JS can be blocked mid-challenge; the manual retry button stays available.
            } finally {
                checking = false
            }
        }
    }

    Card(colors = CardDefaults.cardColors(MaterialTheme.colorScheme.errorContainer)) {
        Column(Modifier.padding(16.dp)) {
            Text(
                stringResource(R.string.captcha_required_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Spacer(Modifier.height(8.dp))
            Text(stringResource(R.string.captcha_required_message))
            Spacer(Modifier.height(12.dp))
            if (progress in 1..99) {
                LinearProgressIndicator(
                    progress = { progress / 100f },
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(8.dp))
            }
            AndroidView(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(420.dp)
                    .clip(RoundedCornerShape(12.dp)),
                factory = { context ->
                    WebView(context).apply {
                        settings.javaScriptEnabled = true
                        settings.mediaPlaybackRequiresUserGesture = false
                        settings.userAgentString =
                            io.github.rustnomicon.sourceinstaller.net.DESKTOP_USER_AGENT
                        settings.domStorageEnabled = true

                        webViewClient = object : WebViewClient() {
                            override fun shouldInterceptRequest(
                                view: WebView,
                                request: WebResourceRequest,
                            ): WebResourceResponse? {
                                capture.capture(request.url?.toString())
                                return null
                            }

                            override fun onPageFinished(view: WebView, url: String?) {
                                scheduleChallengeCheck()
                            }

                            override fun doUpdateVisitedHistory(
                                view: WebView,
                                url: String?,
                                isReload: Boolean,
                            ) {
                                scheduleChallengeCheck()
                            }

                            override fun onReceivedError(
                                view: WebView,
                                request: WebResourceRequest,
                                error: WebResourceError,
                            ) {
                                // Keep the card visible; the user can retry.
                            }
                        }
                        webChromeClient = object : WebChromeClient() {
                            override fun onProgressChanged(view: WebView, newProgress: Int) {
                                progress = newProgress
                                if (newProgress >= 100) scheduleChallengeCheck()
                            }
                        }
                        setDownloadListener { url, _, _, _, _ ->
                            capture.capture(url)
                            scheduleChallengeCheck(200)
                        }

                        webView = this
                        loadUrl(challengeUrl)
                    }
                },
            )
            Spacer(Modifier.height(12.dp))
            Button(
                onClick = { continueAnalysis() },
                enabled = !continuing,
            ) {
                if (continuing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                    )
                } else {
                    Icon(Icons.Filled.Refresh, contentDescription = null)
                }
                Spacer(Modifier.size(8.dp))
                Text(stringResource(R.string.retry_analysis_button))
            }
        }
    }
}

private fun hasClearanceCookie(
    view: WebView,
    challengeUrl: String,
    analysisUrl: String,
): Boolean {
    val cookieManager = CookieManager.getInstance()
    val urls = buildSet {
        add(challengeUrl)
        add(analysisUrl)
        view.url?.let { add(it) }
    }
    return urls.any { url ->
        cookieManager.getCookie(url)
            ?.split(';')
            ?.map { it.trim() }
            ?.any { it.startsWith("cf_clearance=") && it.removePrefix("cf_clearance=").isNotEmpty() } == true
    }
}
