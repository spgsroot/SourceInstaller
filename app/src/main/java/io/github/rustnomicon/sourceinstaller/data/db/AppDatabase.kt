package io.github.rustnomicon.sourceinstaller.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [HistoryEntity::class, LogEntity::class, DownloadedFileEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun historyDao(): HistoryDao
    abstract fun logDao(): LogDao
    abstract fun downloadedFileDao(): DownloadedFileDao

    companion object {
        private const val DB_NAME = "source_installer"

        fun open(context: Context): AppDatabase {
            return Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                DB_NAME,
            ).build()
        }
    }
}
