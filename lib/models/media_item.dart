import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

@freezed
abstract class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String url,
    required String fileName,
    required String extension,
    required String sourceUrl,
    int? sizeBytes,
    String? quality,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}
