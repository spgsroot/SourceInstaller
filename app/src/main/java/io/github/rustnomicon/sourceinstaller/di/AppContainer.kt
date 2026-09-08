package io.github.rustnomicon.sourceinstaller.di

import android.content.Context
import io.github.rustnomicon.sourceinstaller.data.DownloadedFileRepository
import io.github.rustnomicon.sourceinstaller.data.HistoryRepository
import io.github.rustnomicon.sourceinstaller.data.InMemoryDownloadedFileRepository
import io.github.rustnomicon.sourceinstaller.data.InMemoryHistoryRepository
import io.github.rustnomicon.sourceinstaller.data.RoomDownloadedFileRepository
import io.github.rustnomicon.sourceinstaller.data.RoomHistoryRepository
import io.github.rustnomicon.sourceinstaller.data.SettingsRepository
import io.github.rustnomicon.sourceinstaller.data.db.AppDatabase
import io.github.rustnomicon.sourceinstaller.download.DownloadEngine
import io.github.rustnomicon.sourceinstaller.download.DownloadService
import io.github.rustnomicon.sourceinstaller.scrape.ScraperRegistry
import io.github.rustnomicon.sourceinstaller.service.InMemoryLogRepository
import io.github.rustnomicon.sourceinstaller.service.LoggerService
import io.github.rustnomicon.sourceinstaller.service.RoomLogRepository

/**
 * Manual DI container (replaces the Riverpod providers from the Flutter app).
 */
class AppContainer(val context: Context) {

    private val database: AppDatabase? = try {
        AppDatabase.open(context)
    } catch (error: Throwable) {
        // Falls back to in-memory storage below; logged after logger init.
        null
    }

    val logger: LoggerService

    val settingsRepository: SettingsRepository = SettingsRepository(context)

    val historyRepository: HistoryRepository =
        database?.let { RoomHistoryRepository(it.historyDao()) }
            ?: InMemoryHistoryRepository()

    val downloadedFileRepository: DownloadedFileRepository =
        database?.let { RoomDownloadedFileRepository(it.downloadedFileDao()) }
            ?: InMemoryDownloadedFileRepository()

    val scraperRegistry: ScraperRegistry

    val downloadEngine: DownloadEngine

    init {
        val db = database
        if (db != null) {
            LoggerService.configure(RoomLogRepository(db.logDao()))
        }
        logger = LoggerService.getInstance()
        if (db == null) {
            logger.error("Local database initialization failed; using in-memory storage")
        }

        scraperRegistry = ScraperRegistry(logger)
        downloadEngine = DownloadEngine(
            context = context,
            logger = logger,
            downloadedFiles = downloadedFileRepository,
        )
        downloadEngine.onActiveDownloadsChanged = { active ->
            if (active) DownloadService.start(context) else DownloadService.stop(context)
        }
    }
}
