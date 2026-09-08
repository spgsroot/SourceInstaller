package io.github.rustnomicon.sourceinstaller.ui.analyze

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Downloading
import androidx.compose.material.icons.filled.HourglassEmpty
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.PauseCircle
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil3.compose.AsyncImage
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.SourceInstallerApplication
import io.github.rustnomicon.sourceinstaller.data.model.DownloadState
import io.github.rustnomicon.sourceinstaller.data.model.DownloadTask
import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import io.github.rustnomicon.sourceinstaller.di.AppContainer
import io.github.rustnomicon.sourceinstaller.util.formatMediaSubtitle

@Composable
fun analyzeViewModel(): AnalyzeViewModel {
    val app = LocalContext.current.applicationContext as SourceInstallerApplication
    val container: AppContainer = app.container
    return viewModel(
        key = "analyze",
        factory = viewModelFactory {
            initializer { AnalyzeViewModel(container) }
        },
    )
}

@Composable
fun AnalyzeScreen(viewModel: AnalyzeViewModel = analyzeViewModel()) {
    val url by viewModel.urlInput.collectAsStateWithLifecycle()
    val filters by viewModel.filters.collectAsStateWithLifecycle()
    val analysis by viewModel.analysis.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
    ) {
        OutlinedTextField(
            value = url,
            onValueChange = { viewModel.urlInput.value = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text(stringResource(R.string.url_field_label)) },
            placeholder = { Text(stringResource(R.string.url_field_hint)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
            keyboardActions = KeyboardActions(onDone = { viewModel.analyze() }),
        )
        Spacer(Modifier.height(12.dp))
        FilterPanel(filters = filters, viewModel = viewModel)
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = { viewModel.analyze() },
            enabled = analysis !is AnalysisState.Loading,
            modifier = Modifier.fillMaxWidth(),
        ) {
            if (analysis is AnalysisState.Loading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(18.dp),
                    strokeWidth = 2.dp,
                )
            } else {
                Icon(Icons.Filled.Search, contentDescription = null)
            }
            Spacer(Modifier.size(8.dp))
            Text(stringResource(R.string.start_analysis_button))
        }
        Spacer(Modifier.height(16.dp))

        when (val state = analysis) {
            is AnalysisState.Success -> ResultsList(items = state.items, viewModel = viewModel)
            is AnalysisState.Error -> ErrorCard(
                error = state.error,
                analysisUrl = state.analysisUrl.ifEmpty { viewModel.lastAnalysisUrl },
                viewModel = viewModel,
            )
            AnalysisState.Loading -> LinearProgressIndicator(Modifier.fillMaxWidth())
            AnalysisState.Idle -> Unit
        }
    }
}

@Composable
private fun FilterPanel(filters: FilterSettings, viewModel: AnalyzeViewModel) {
    Card {
        Column(Modifier.padding(8.dp)) {
            FilterCheckboxRow(
                checked = filters.onlyVideo,
                label = stringResource(R.string.only_video_filter),
                onCheckedChange = { viewModel.setOnlyVideo(it) },
            )
            FilterCheckboxRow(
                checked = filters.ignoreSmallFiles,
                label = stringResource(R.string.ignore_small_files_filter),
                onCheckedChange = { viewModel.setIgnoreSmallFiles(it) },
            )
            DownloadLimitDropdown(
                selected = filters.downloadLimit,
                onSelected = { viewModel.setDownloadLimit(it) },
            )
        }
    }
}

@Composable
private fun FilterCheckboxRow(
    checked: Boolean,
    label: String,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp)),
    ) {
        Checkbox(checked = checked, onCheckedChange = onCheckedChange)
        Text(label, style = MaterialTheme.typography.bodyMedium)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DownloadLimitDropdown(
    selected: Int?,
    onSelected: (Int?) -> Unit,
) {
    val options = listOf(0, 5, 10, 25, 50, 100)

    @Composable
    fun labelFor(limit: Int): String =
        if (limit == 0) stringResource(R.string.download_limit_unlimited)
        else stringResource(R.string.download_limit_files, limit)

    var expanded = androidx.compose.runtime.remember {
        androidx.compose.runtime.mutableStateOf(false)
    }

    ExposedDropdownMenuBox(
        expanded = expanded.value,
        onExpandedChange = { expanded.value = it },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 8.dp),
    ) {
        OutlinedTextField(
            value = labelFor(selected ?: 0),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.download_limit_label)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded.value) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor(androidx.compose.material3.MenuAnchorType.PrimaryNotEditable),
        )
        ExposedDropdownMenu(
            expanded = expanded.value,
            onDismissRequest = { expanded.value = false },
        ) {
            options.forEach { limit ->
                DropdownMenuItem(
                    text = { Text(labelFor(limit)) },
                    onClick = {
                        onSelected(if (limit == 0) null else limit)
                        expanded.value = false
                    },
                )
            }
        }
    }
}

@Composable
private fun ResultsList(items: List<MediaItem>, viewModel: AnalyzeViewModel) {
    val tasks by viewModel.tasks.collectAsStateWithLifecycle()

    if (items.isEmpty()) {
        Card {
            Text(
                stringResource(R.string.no_media_found),
                modifier = Modifier.padding(16.dp),
            )
        }
        return
    }

    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                stringResource(R.string.found_files, items.size),
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.weight(1f),
            )
            val limit = viewModel.filters.collectAsStateWithLifecycle().value.downloadLimit
            val downloadLabel = if (limit == null || limit >= items.size) {
                stringResource(R.string.download_all_button)
            } else {
                stringResource(R.string.download_limited_button, limit)
            }
            Button(onClick = { viewModel.enqueueAll(items) }) {
                Icon(Icons.Filled.Download, contentDescription = null)
                Spacer(Modifier.size(6.dp))
                Text(downloadLabel)
            }
        }
        Spacer(Modifier.height(8.dp))
        items.forEach { item ->
            ResultItemCard(item = item, tasks = tasks, viewModel = viewModel)
        }
    }
}

@Composable
private fun ResultItemCard(
    item: MediaItem,
    tasks: List<DownloadTask>,
    viewModel: AnalyzeViewModel,
) {
    val existingTask = tasks.asReversed().firstOrNull {
        it.mediaItem.url == item.url || it.mediaItem.fileName == item.fileName
    }
    val disabled = existingTask != null &&
        existingTask.state != DownloadState.Failed &&
        existingTask.state != DownloadState.Canceled

    val previewItem = androidx.compose.runtime.remember {
        androidx.compose.runtime.mutableStateOf<MediaItem?>(null)
    }

    previewItem.value?.let { preview ->
        MediaPreviewDialog(item = preview, onDismiss = { previewItem.value = null })
    }

    Card(modifier = Modifier.padding(bottom = 8.dp)) {
        ListItem(
            leadingContent = { MediaPreviewLeading(item) },
            headlineContent = {
                Text(item.fileName, maxLines = 1, overflow = TextOverflow.Ellipsis)
            },
            supportingContent = {
                Text(
                    formatMediaSubtitle(item.sizeBytes, item.url),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            },
            trailingContent = {
                Row {
                    IconButton(onClick = { previewItem.value = item }) {
                        Icon(
                            Icons.Filled.Visibility,
                            contentDescription = stringResource(R.string.preview_tooltip),
                        )
                    }
                    IconButton(
                        onClick = { viewModel.enqueue(item) },
                        enabled = !disabled,
                    ) {
                        Icon(
                            imageVector = downloadIconFor(existingTask),
                            contentDescription = downloadDescriptionFor(existingTask),
                        )
                    }
                }
            },
        )
    }
}

@Composable
private fun downloadIconFor(task: DownloadTask?): androidx.compose.ui.graphics.vector.ImageVector =
    when (task?.state) {
        DownloadState.Completed -> Icons.Filled.CheckCircle
        DownloadState.Running -> Icons.Filled.Downloading
        DownloadState.Queued -> Icons.Filled.HourglassEmpty
        DownloadState.Paused -> Icons.Filled.PauseCircle
        else -> Icons.Filled.Download
    }

@Composable
private fun downloadDescriptionFor(task: DownloadTask?): String =
    when (task?.state) {
        DownloadState.Completed -> stringResource(R.string.already_downloaded_tooltip)
        DownloadState.Running, DownloadState.Queued, DownloadState.Paused ->
            stringResource(R.string.download_in_progress_tooltip)
        else -> stringResource(R.string.download_tooltip)
    }

@Composable
private fun MediaPreviewLeading(item: MediaItem) {
    if (item.extension.lowercase() in setOf("jpg", "jpeg", "png", "gif", "webp")) {
        AsyncImage(
            model = item.url,
            contentDescription = null,
            modifier = Modifier
                .size(56.dp)
                .clip(RoundedCornerShape(8.dp)),
            contentScale = ContentScale.Crop,
        )
    } else {
        Icon(
            Icons.Filled.Movie,
            contentDescription = null,
            modifier = Modifier.size(56.dp),
        )
    }
}
