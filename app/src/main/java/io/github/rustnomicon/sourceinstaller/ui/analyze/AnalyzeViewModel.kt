package io.github.rustnomicon.sourceinstaller.ui.analyze

import android.webkit.WebView
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.github.rustnomicon.sourceinstaller.data.HistoryEntry
import io.github.rustnomicon.sourceinstaller.data.model.DownloadTask
import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.di.AppContainer
import io.github.rustnomicon.sourceinstaller.errors.CaptchaRequiredException
import io.github.rustnomicon.sourceinstaller.scrape.BaseScraper
import io.github.rustnomicon.sourceinstaller.scrape.DynamicWebViewScraper
import io.github.rustnomicon.sourceinstaller.scrape.RedditScraper
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface AnalysisState {
    data object Idle : AnalysisState
    data object Loading : AnalysisState
    data class Success(val items: List<MediaItem>) : AnalysisState
    data class Error(val error: Throwable, val analysisUrl: String) : AnalysisState {
        val isCaptcha: Boolean get() = error is CaptchaRequiredException
    }
}

class AnalyzeViewModel(private val container: AppContainer) : ViewModel() {

    val urlInput = MutableStateFlow("")

    private val _analysis = MutableStateFlow<AnalysisState>(AnalysisState.Idle)
    val analysis: StateFlow<AnalysisState> = _analysis.asStateFlow()

    val filters: StateFlow<FilterSettings> = container.settingsRepository.settings
        .stateIn(viewModelScope, SharingStarted.Eagerly, FilterSettings())

    val tasks: StateFlow<List<DownloadTask>> = container.downloadEngine.tasks

    var lastAnalysisUrl: String = ""
        private set

    fun setOnlyVideo(value: Boolean) {
        viewModelScope.launch { container.settingsRepository.setOnlyVideo(value) }
    }

    fun setIgnoreSmallFiles(value: Boolean) {
        viewModelScope.launch { container.settingsRepository.setIgnoreSmallFiles(value) }
    }

    fun setDownloadLimit(value: Int?) {
        viewModelScope.launch { container.settingsRepository.setDownloadLimit(value) }
    }

    fun analyze(rawUrl: String = urlInput.value) {
        val url = rawUrl.trim()
        if (url.isEmpty()) return
        lastAnalysisUrl = url
        _analysis.value = AnalysisState.Loading

        viewModelScope.launch {
            runAnalysis(url) { scraper, currentFilters ->
                scraper.extractMedia(url, currentFilters)
            }
        }
    }

    fun analyzeWithWebView(
        rawUrl: String,
        webView: WebView,
        capturedMediaUrls: Set<String> = emptySet(),
    ) {
        val url = rawUrl.trim()
        if (url.isEmpty()) return
        container.logger.info("Продолжение анализа в уже открытом WebView", source = url)
        _analysis.value = AnalysisState.Loading

        viewModelScope.launch {
            runAnalysis(url) { scraper, currentFilters ->
                when (scraper) {
                    is DynamicWebViewScraper -> scraper.extractMediaFromWebView(
                        url,
                        webView,
                        filters = currentFilters,
                        capturedMediaUrls = capturedMediaUrls,
                    )
                    is RedditScraper -> scraper.extractMediaFromWebView(
                        url,
                        webView,
                        filters = currentFilters,
                        capturedMediaUrls = capturedMediaUrls,
                    )
                    else -> scraper.extractMedia(url, currentFilters)
                }
            }
        }
    }

    /** Suspends until the running analysis leaves the Loading state. */
    suspend fun awaitAnalysisSettled() {
        analysis.first { it !is AnalysisState.Loading }
    }

    fun enqueue(item: MediaItem) {
        container.downloadEngine.enqueue(item, filters.value)
    }

    fun enqueueAll(items: List<MediaItem>) {
        container.downloadEngine.enqueueAll(items, filters.value)
    }

    private suspend fun runAnalysis(
        url: String,
        extract: suspend (BaseScraper, FilterSettings) -> List<MediaItem>,
    ) {
        val logger = container.logger
        try {
            val scraper = container.scraperRegistry.forUrl(url)
            val currentFilters = filters.value
            val items = extract(scraper, currentFilters)
            container.historyRepository.add(
                HistoryEntry(
                    sourceUrl = url,
                    foundCount = items.size,
                    createdAtMillis = System.currentTimeMillis(),
                ),
            )
            _analysis.value = AnalysisState.Success(items)
            logger.success("Анализ завершён: ${items.size} файлов", source = url)
        } catch (error: CaptchaRequiredException) {
            _analysis.value = AnalysisState.Error(error, url)
            logger.warning(error.message ?: "Captcha required", source = url)
        } catch (error: Throwable) {
            _analysis.value = AnalysisState.Error(error, url)
            logger.error("Анализ не выполнен", source = url, error = error)
        }
    }
}
