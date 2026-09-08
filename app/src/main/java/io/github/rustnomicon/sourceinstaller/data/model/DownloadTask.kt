package io.github.rustnomicon.sourceinstaller.data.model

enum class DownloadState { Queued, Running, Paused, Completed, Failed, Canceled }

/**
 * Port of the Flutter `DownloadTask` freezed model.
 */
data class DownloadTask(
    val id: String,
    val mediaItem: MediaItem,
    val progress: Float = 0f,
    val state: DownloadState = DownloadState.Queued,
    val savedPath: String? = null,
    val errorMessage: String? = null,
)
