import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_item.dart';

part 'download_task.freezed.dart';
part 'download_task.g.dart';

enum DownloadState { queued, running, paused, completed, failed, canceled }

@freezed
abstract class DownloadTask with _$DownloadTask {
  const factory DownloadTask({
    required String id,
    required MediaItem mediaItem,
    @Default(0) double progress,
    @Default(DownloadState.queued) DownloadState state,
    String? savedPath,
    String? errorMessage,
  }) = _DownloadTask;

  factory DownloadTask.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskFromJson(json);
}
