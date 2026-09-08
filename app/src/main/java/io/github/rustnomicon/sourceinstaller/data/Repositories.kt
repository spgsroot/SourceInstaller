package io.github.rustnomicon.sourceinstaller.data

import io.github.rustnomicon.sourceinstaller.data.db.DownloadedFileDao
import io.github.rustnomicon.sourceinstaller.data.db.DownloadedFileEntity
import io.github.rustnomicon.sourceinstaller.data.db.HistoryDao
import io.github.rustnomicon.sourceinstaller.data.db.HistoryEntity
import io.github.rustnomicon.sourceinstaller.data.model.MediaItem
import java.util.Collections

data class HistoryEntry(
    val sourceUrl: String,
    val foundCount: Int,
    val createdAtMillis: Long,
)

interface HistoryRepository {
    suspend fun add(entry: HistoryEntry)
    suspend fun recent(limit: Int = 20): List<HistoryEntry>
}

class InMemoryHistoryRepository : HistoryRepository {
    private val entries = Collections.synchronizedList(mutableListOf<HistoryEntry>())

    override suspend fun add(entry: HistoryEntry) {
        entries.add(entry)
    }

    override suspend fun recent(limit: Int): List<HistoryEntry> =
        synchronized(entries) { entries.takeLast(limit) }
}

class RoomHistoryRepository(private val dao: HistoryDao) : HistoryRepository {
    override suspend fun add(entry: HistoryEntry) {
        dao.insert(
            HistoryEntity(
                sourceUrl = entry.sourceUrl,
                foundCount = entry.foundCount,
                createdAtMillis = entry.createdAtMillis,
            ),
        )
    }

    override suspend fun recent(limit: Int): List<HistoryEntry> =
        dao.recent(limit).asReversed().map { row ->
            HistoryEntry(
                sourceUrl = row.sourceUrl,
                foundCount = row.foundCount,
                createdAtMillis = row.createdAtMillis,
            )
        }
}

data class DownloadedFileEntry(
    val url: String,
    val fileName: String,
    val savedPath: String,
    val extension: String,
    val downloadedAtMillis: Long,
    val sourceUrl: String? = null,
)

interface DownloadedFileRepository {
    suspend fun findExisting(item: MediaItem): DownloadedFileEntry?
    suspend fun add(entry: DownloadedFileEntry)
}

class InMemoryDownloadedFileRepository : DownloadedFileRepository {
    private val entries = Collections.synchronizedList(mutableListOf<DownloadedFileEntry>())

    override suspend fun findExisting(item: MediaItem): DownloadedFileEntry? =
        synchronized(entries) {
            entries.asReversed().firstOrNull {
                it.url == item.url || it.fileName == item.fileName
            }
        }

    override suspend fun add(entry: DownloadedFileEntry) {
        synchronized(entries) {
            entries.removeAll { it.url == entry.url || it.fileName == entry.fileName }
            entries.add(entry)
        }
    }
}

class RoomDownloadedFileRepository(
    private val dao: DownloadedFileDao,
) : DownloadedFileRepository {

    override suspend fun findExisting(item: MediaItem): DownloadedFileEntry? {
        for (row in dao.allNewestFirst()) {
            if (row.url == item.url || row.fileName == item.fileName) {
                return DownloadedFileEntry(
                    url = row.url,
                    fileName = row.fileName,
                    savedPath = row.savedPath,
                    extension = row.extension,
                    downloadedAtMillis = row.downloadedAtMillis,
                    sourceUrl = row.sourceUrl,
                )
            }
        }
        return null
    }

    override suspend fun add(entry: DownloadedFileEntry) {
        dao.deleteDuplicates(url = entry.url, fileName = entry.fileName)
        dao.insert(
            DownloadedFileEntity(
                url = entry.url,
                fileName = entry.fileName,
                savedPath = entry.savedPath,
                extension = entry.extension,
                downloadedAtMillis = entry.downloadedAtMillis,
                sourceUrl = entry.sourceUrl,
            ),
        )
    }
}
