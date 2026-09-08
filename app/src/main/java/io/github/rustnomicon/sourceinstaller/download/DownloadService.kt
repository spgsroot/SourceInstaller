package io.github.rustnomicon.sourceinstaller.download

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import io.github.rustnomicon.sourceinstaller.SourceInstallerApplication
import io.github.rustnomicon.sourceinstaller.data.model.DownloadState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * Keeps the process alive while downloads run (the Flutter version got this
 * from the background_downloader plugin's native side).
 */
class DownloadService : Service() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val app = application as SourceInstallerApplication
        val engine = app.container.downloadEngine
        val notifier = DownloadNotifier(this)

        if (!notifier.canNotify()) {
            // Without the notifications permission a FGS would crash; downloads
            // still proceed while the app process is alive.
            stopSelf()
            return START_NOT_STICKY
        }

        goForeground(notifier, engine)
        observeQueue(engine, notifier)
        return START_STICKY
    }

    private fun goForeground(notifier: DownloadNotifier, engine: DownloadEngine) {
        val notification = notifier.currentNotification(engine.tasks.value)
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        } else {
            0
        }
        ServiceCompat.startForeground(
            this,
            DownloadNotifier.NOTIFICATION_ID,
            notification,
            type,
        )
    }

    private fun observeQueue(engine: DownloadEngine, notifier: DownloadNotifier) {
        scope.launch {
            var idleStreak = 0
            engine.tasks.collectLatest { tasks ->
                val hasActive = tasks.any {
                    it.state == DownloadState.Running || it.state == DownloadState.Queued
                }
                if (hasActive) {
                    idleStreak = 0
                } else {
                    idleStreak++
                    if (idleStreak >= 2) {
                        // Small debounce so back-to-back enqueues don't cycle the service.
                        delay(1500)
                        stopSelf()
                        return@collectLatest
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        fun start(context: Context) {
            val intent = Intent(context, DownloadService::class.java)
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, DownloadService::class.java))
        }
    }
}
