package io.github.rustnomicon.sourceinstaller.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import io.github.rustnomicon.sourceinstaller.data.model.FilterSettings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.filterSettingsDataStore by preferencesDataStore(
    name = "filter_settings",
)

/**
 * Persists [FilterSettings] via Preferences DataStore (replaces the Isar
 * settings table from the Flutter version).
 */
class SettingsRepository(private val context: Context) {

    private object Keys {
        val onlyVideo = booleanPreferencesKey("only_video")
        val ignoreSmallFiles = booleanPreferencesKey("ignore_small_files")
        val minSizeBytes = longPreferencesKey("min_size_bytes")
        val downloadLimit = intPreferencesKey("download_limit")
        val allowedExtensions = stringPreferencesKey("allowed_extensions")
    }

    val settings: Flow<FilterSettings> =
        context.filterSettingsDataStore.data.map { prefs ->
            FilterSettings(
                onlyVideo = prefs[Keys.onlyVideo] ?: true,
                ignoreSmallFiles = prefs[Keys.ignoreSmallFiles] ?: false,
                minSizeBytes = prefs[Keys.minSizeBytes]?.takeIf { it >= 0 },
                downloadLimit = prefs[Keys.downloadLimit]?.takeIf { it >= 0 },
                allowedExtensions = prefs[Keys.allowedExtensions]
                    ?.split(',')
                    ?.filter { it.isNotBlank() }
                    ?.toSet()
                    ?: setOf("mp4", "webm"),
            )
        }

    suspend fun save(settings: FilterSettings) {
        context.filterSettingsDataStore.edit { prefs ->
            prefs[Keys.onlyVideo] = settings.onlyVideo
            prefs[Keys.ignoreSmallFiles] = settings.ignoreSmallFiles
            val minSize = settings.minSizeBytes
            if (minSize == null) prefs.remove(Keys.minSizeBytes) else
                prefs[Keys.minSizeBytes] = minSize
            val limit = settings.downloadLimit
            if (limit == null) prefs.remove(Keys.downloadLimit) else
                prefs[Keys.downloadLimit] = limit
            prefs[Keys.allowedExtensions] = settings.allowedExtensions.joinToString(",")
        }
    }

    suspend fun setOnlyVideo(value: Boolean) {
        context.filterSettingsDataStore.edit { prefs ->
            prefs[Keys.onlyVideo] = value
            prefs[Keys.allowedExtensions] = (
                if (value) FilterSettings.VIDEO_EXTENSIONS
                else FilterSettings.ALL_EXTENSIONS
                ).joinToString(",")
        }
    }

    suspend fun setIgnoreSmallFiles(value: Boolean) {
        context.filterSettingsDataStore.edit { prefs ->
            prefs[Keys.ignoreSmallFiles] = value
        }
    }

    suspend fun setDownloadLimit(value: Int?) {
        context.filterSettingsDataStore.edit { prefs ->
            if (value == null) prefs.remove(Keys.downloadLimit) else
                prefs[Keys.downloadLimit] = value
        }
    }
}
