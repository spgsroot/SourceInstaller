package io.github.rustnomicon.sourceinstaller.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface HistoryDao {
    @Insert
    suspend fun insert(entry: HistoryEntity)

    @Query("SELECT * FROM history ORDER BY createdAtMillis DESC LIMIT :limit")
    suspend fun recent(limit: Int): List<HistoryEntity>
}

@Dao
interface LogDao {
    @Insert
    suspend fun insert(entry: LogEntity)

    @Query("SELECT * FROM logs ORDER BY timestampMillis DESC LIMIT :limit")
    suspend fun recent(limit: Int): List<LogEntity>
}

@Dao
interface DownloadedFileDao {
    @Insert
    suspend fun insert(entity: DownloadedFileEntity): Long

    @Query("SELECT * FROM downloaded_files ORDER BY id DESC")
    suspend fun allNewestFirst(): List<DownloadedFileEntity>

    @Query("DELETE FROM downloaded_files WHERE url = :url OR fileName = :fileName")
    suspend fun deleteDuplicates(url: String, fileName: String)
}
