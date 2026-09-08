package io.github.rustnomicon.sourceinstaller.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Indigo seed palette matching the Flutter ColorScheme.fromSeed(Colors.indigo).
private val LightColors = lightColorScheme(
    primary = Color(0xFF3F51B5),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFDDE0FF),
    onPrimaryContainer = Color(0xFF00107B),
    secondary = Color(0xFF5A5D72),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFDFE1F9),
    onSecondaryContainer = Color(0xFF171B2C),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFB8C3FF),
    onPrimary = Color(0xFF0B2386),
    primaryContainer = Color(0xFF25389D),
    onPrimaryContainer = Color(0xFFDDE0FF),
    secondary = Color(0xFFC3C5DD),
    onSecondary = Color(0xFF2D3042),
    secondaryContainer = Color(0xFF434659),
    onSecondaryContainer = Color(0xFFDFE1F9),
)

@Composable
fun SourceInstallerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content,
    )
}
