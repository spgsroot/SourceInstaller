package io.github.rustnomicon.sourceinstaller.download

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.github.rustnomicon.sourceinstaller.MainActivity
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.data.model.DownloadState
import io.github.rustnomicon.sourceinstaller.data.model.DownloadTask

/**
 * Renders the single group download notification (port of the
 * `background_downloader` group notification config from the Flutter version).
 */
class DownloadNotifier(private val context: Context) {

    private val notificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        ensureChannel()
    }

    fun update(tasks: List<DownloadTask>) {
        if (!canNotify()) return
        if (tasks.isEmpty()) {
            notificationManager.cancel(NOTIFICATION_ID)
            return
        }

        val active = tasks.count {
            it.state == DownloadState.Running || it.state == DownloadState.Queued
        }
        val notification = if (active > 0) {
            buildRunningNotification(tasks)
        } else {
            buildTerminalNotification(tasks)
        }
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun currentNotification(tasks: List<DownloadTask>): Notification =
        if (tasks.any { it.state == DownloadState.Running || it.state == DownloadState.Queued }) {
            buildRunningNotification(tasks)
        } else {
            buildTerminalNotification(tasks)
        }

    fun cancel() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    fun canNotify(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

    private fun buildRunningNotification(tasks: List<DownloadTask>): Notification {
        val running = tasks.filter {
            it.state == DownloadState.Running || it.state == DownloadState.Queued
        }
        val finished = tasks.count { it.state == DownloadState.Completed }
        val avgProgress = running.map { it.progress }.average()
            .takeIf { !it.isNaN() } ?: 0.0
        val percent = (avgProgress * 100).toInt().coerceIn(0, 100)

        return baseBuilder()
            .setContentTitle(context.getString(R.string.notification_running_title))
            .setContentText(
                context.getString(
                    R.string.notification_running_text, finished, tasks.size, percent,
                ),
            )
            .setProgress(100, percent, tasks.isEmpty())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun buildTerminalNotification(tasks: List<DownloadTask>): Notification {
        val failed = tasks.count { it.state == DownloadState.Failed }
        val canceled = tasks.count { it.state == DownloadState.Canceled }
        val paused = tasks.count { it.state == DownloadState.Paused }
        val completed = tasks.count { it.state == DownloadState.Completed }

        val (titleRes, text) = when {
            failed > 0 -> R.string.notification_error_title to
                context.getString(R.string.notification_error_text, failed, tasks.size)
            paused > 0 -> R.string.notification_paused_title to
                context.getString(R.string.notification_paused_text)
            canceled > 0 -> R.string.notification_canceled_title to
                context.getString(R.string.notification_canceled_text)
            else -> R.string.notification_complete_title to
                context.getString(R.string.notification_complete_text, completed)
        }

        return baseBuilder()
            .setContentTitle(context.getString(titleRes))
            .setContentText(text)
            .setProgress(0, 0, false)
            .setOngoing(false)
            .setAutoCancel(true)
            .build()
    }

    private fun baseBuilder(): NotificationCompat.Builder {
        val openIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentIntent(openIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
    }

    private fun ensureChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_downloads),
            NotificationManager.IMPORTANCE_LOW,
        )
        notificationManager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "downloads"
        const val NOTIFICATION_ID = 42
    }
}
