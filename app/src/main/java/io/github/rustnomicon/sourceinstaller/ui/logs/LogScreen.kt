package io.github.rustnomicon.sourceinstaller.ui.logs

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.SourceInstallerApplication
import io.github.rustnomicon.sourceinstaller.data.model.AppLogLevel
import io.github.rustnomicon.sourceinstaller.data.model.LogEntry
import io.github.rustnomicon.sourceinstaller.service.LoggerService
import io.github.rustnomicon.sourceinstaller.util.formatLogTimestamp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

private const val MAX_ENTRIES = 500

class LogViewModel(private val logger: LoggerService) : ViewModel() {
    private val _entries = MutableStateFlow<List<LogEntry>>(emptyList())
    val entries: StateFlow<List<LogEntry>> = _entries.asStateFlow()

    init {
        viewModelScope.launch {
            _entries.value = logger.recent(MAX_ENTRIES).takeLast(MAX_ENTRIES)
            logger.stream.collect { entry ->
                _entries.value = (_entries.value + entry).takeLast(MAX_ENTRIES)
            }
        }
    }
}

@Composable
fun LogScreen() {
    val app = LocalContext.current.applicationContext as SourceInstallerApplication
    val logger = app.container.logger
    val viewModel: LogViewModel = viewModel(
        key = "log",
        factory = viewModelFactory { initializer { LogViewModel(logger) } },
    )
    val entries by viewModel.entries.collectAsStateWithLifecycle()
    val listState = rememberLazyListState()

    LaunchedEffect(entries.size) {
        if (entries.isNotEmpty()) {
            listState.animateScrollToItem(entries.size - 1)
        }
    }

    if (entries.isEmpty()) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            Text(stringResource(R.string.log_empty))
            Spacer(Modifier.weight(1f))
        }
        return
    }

    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(12.dp),
    ) {
        items(entries) { entry ->
            LogRow(entry)
        }
    }
}

@Composable
private fun LogRow(entry: LogEntry) {
    val color = when (entry.level) {
        AppLogLevel.Error -> Color(0xFFE53935)
        AppLogLevel.Warning -> Color(0xFFFB8C00)
        AppLogLevel.Success -> Color(0xFF43A047)
        AppLogLevel.Info -> Color(0xFF757575)
        AppLogLevel.Debug -> Color(0xFF607D8B)
    }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
    ) {
        Box(
            modifier = Modifier
                .size(10.dp)
                .clip(androidx.compose.foundation.shape.CircleShape)
                .background(color),
        )
        Spacer(Modifier.width(8.dp))
        Column {
            Text(entry.message, style = MaterialTheme.typography.bodyMedium)
            Text(
                buildString {
                    append(formatLogTimestamp(entry.timestampMillis))
                    append(" • ")
                    append(entry.displayLevel)
                    entry.source?.let { append(" • ").append(it) }
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
