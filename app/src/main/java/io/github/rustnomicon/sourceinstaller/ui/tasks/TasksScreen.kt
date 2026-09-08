package io.github.rustnomicon.sourceinstaller.ui.tasks

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.SourceInstallerApplication
import io.github.rustnomicon.sourceinstaller.data.model.DownloadState
import io.github.rustnomicon.sourceinstaller.data.model.DownloadTask

@Composable
fun TasksScreen() {
    val app = LocalContext.current.applicationContext as SourceInstallerApplication
    val engine = app.container.downloadEngine
    val tasks by engine.tasks.collectAsStateWithLifecycle()

    if (tasks.isEmpty()) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            Text(stringResource(R.string.queue_empty))
            Spacer(Modifier.weight(1f))
        }
        return
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
    ) {
        items(tasks, key = { it.id }) { task ->
            TaskTile(
                task = task,
                onPause = { engine.pause(task.id) },
                onResume = { engine.resume(task.id) },
                onCancel = { engine.cancel(task.id) },
            )
        }
    }
}

@Composable
private fun TaskTile(
    task: DownloadTask,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onCancel: () -> Unit,
) {
    val canPause = task.state == DownloadState.Running
    val canResume = task.state == DownloadState.Paused
    val canCancel = task.state == DownloadState.Running ||
        task.state == DownloadState.Queued ||
        task.state == DownloadState.Paused

    Card(modifier = Modifier.padding(bottom = 8.dp)) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    task.mediaItem.fileName,
                    style = MaterialTheme.typography.titleSmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    stateLabel(task.state),
                    style = MaterialTheme.typography.bodySmall,
                )
                Spacer(Modifier.height(8.dp))
                LinearProgressIndicator(
                    progress = { task.progress.coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth().padding(end = 8.dp),
                )
                task.savedPath?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                task.errorMessage?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }

            when {
                canResume -> IconButton(onClick = onResume) {
                    Icon(
                        Icons.Filled.PlayArrow,
                        contentDescription = stringResource(R.string.resume_tooltip),
                    )
                }
                else -> IconButton(onClick = onPause, enabled = canPause) {
                    Icon(
                        Icons.Filled.Pause,
                        contentDescription = stringResource(R.string.pause_tooltip),
                    )
                }
            }
            IconButton(onClick = onCancel, enabled = canCancel) {
                Icon(
                    Icons.Filled.Close,
                    contentDescription = stringResource(R.string.cancel_tooltip),
                )
            }
        }
    }
}

@Composable
private fun stateLabel(state: DownloadState): String = when (state) {
    DownloadState.Queued -> stringResource(R.string.queued_state)
    DownloadState.Running -> stringResource(R.string.running_state)
    DownloadState.Paused -> stringResource(R.string.paused_state)
    DownloadState.Completed -> stringResource(R.string.completed_state)
    DownloadState.Failed -> stringResource(R.string.failed_state)
    DownloadState.Canceled -> stringResource(R.string.canceled_state)
}
