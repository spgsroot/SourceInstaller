package io.github.rustnomicon.sourceinstaller.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "history")
data class HistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val sourceUrl: String,
    val foundCount: Int,
    val createdAtMillis: Long,
)

@Entity(tableName = "logs")
data class LogEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val timestampMillis: Long,
    val level: String,
    val message: String,
    val source: String? = null,
)

@Entity(tableName = "downloaded_files")
data class DownloadedFileEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val url: String,
    val fileName: String,
    val savedPath: String,
    val extension: String,
    val downloadedAtMillis: Long,
    val sourceUrl: String? = null,
)
