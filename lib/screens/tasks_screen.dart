import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/download_task.dart';
import '../providers/app_providers.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(downloadQueueProvider);

    if (tasks.isEmpty) {
      return Center(child: Text(l10n.queueEmpty));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canPause = task.state == DownloadState.running;
    final canCancel =
        task.state == DownloadState.running ||
        task.state == DownloadState.queued ||
        task.state == DownloadState.paused;

    return Card(
      child: ListTile(
        title: Text(task.mediaItem.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_stateLabel(l10n, task.state)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: task.progress.clamp(0, 1)),
            if (task.savedPath != null) Text(task.savedPath!),
            if (task.errorMessage != null)
              Text(
                task.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.pauseTooltip,
              icon: const Icon(Icons.pause),
              onPressed: canPause
                  ? () =>
                        ref.read(downloadQueueProvider.notifier).pause(task.id)
                  : null,
            ),
            IconButton(
              tooltip: l10n.cancelTooltip,
              icon: const Icon(Icons.cancel),
              onPressed: canCancel
                  ? () =>
                        ref.read(downloadQueueProvider.notifier).cancel(task.id)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _stateLabel(AppLocalizations l10n, DownloadState state) {
    return switch (state) {
      DownloadState.queued => l10n.queuedState,
      DownloadState.running => l10n.runningState,
      DownloadState.paused => l10n.pausedState,
      DownloadState.completed => l10n.completedState,
      DownloadState.failed => l10n.failedState,
      DownloadState.canceled => l10n.canceledState,
    };
  }
}
