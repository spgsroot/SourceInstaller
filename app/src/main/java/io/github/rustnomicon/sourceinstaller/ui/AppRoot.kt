package io.github.rustnomicon.sourceinstaller.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Link
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import io.github.rustnomicon.sourceinstaller.R
import io.github.rustnomicon.sourceinstaller.ui.analyze.AnalyzeScreen
import io.github.rustnomicon.sourceinstaller.ui.logs.LogScreen
import io.github.rustnomicon.sourceinstaller.ui.tasks.TasksScreen
import kotlinx.coroutines.launch

private val TAB_ICONS = listOf(
    Icons.Filled.Link,
    Icons.Filled.Download,
    Icons.AutoMirrored.Filled.List,
)

private val TAB_LABELS = listOf(
    R.string.analyze_tab,
    R.string.tasks_tab,
    R.string.log_tab,
)

/**
 * App shell: app bar with three tabs (port of the Flutter `SourceInstallerShell`).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppRoot() {
    val pagerState = rememberPagerState(pageCount = { TAB_LABELS.size })
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            Column {
                TopAppBar(
                    title = { Text(stringResource(R.string.app_name)) },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer,
                    ),
                )
                TabRow(selectedTabIndex = pagerState.currentPage) {
                    TAB_LABELS.forEachIndexed { index, labelRes ->
                        Tab(
                            selected = pagerState.currentPage == index,
                            onClick = { scope.launch { pagerState.animateScrollToPage(index) } },
                            icon = {
                                Icon(
                                    TAB_ICONS[index],
                                    contentDescription = stringResource(labelRes),
                                )
                            },
                            text = { Text(stringResource(labelRes)) },
                        )
                    }
                }
            }
        },
    ) { padding ->
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) { page ->
            when (page) {
                0 -> AnalyzeScreen()
                1 -> TasksScreen()
                else -> LogScreen()
            }
        }
    }
}
