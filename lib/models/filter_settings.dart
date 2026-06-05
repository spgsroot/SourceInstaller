import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_settings.freezed.dart';
part 'filter_settings.g.dart';

@freezed
abstract class FilterSettings with _$FilterSettings {
  const FilterSettings._();

  const factory FilterSettings({
    @Default(true) bool onlyVideo,
    @Default(false) bool ignoreSmallFiles,
    int? minSizeBytes,
    int? downloadLimit,
    @Default(<String>{'mp4', 'webm'}) Set<String> allowedExtensions,
  }) = _FilterSettings;

  factory FilterSettings.fromJson(Map<String, dynamic> json) =>
      _$FilterSettingsFromJson(json);

  static const int defaultSmallFileThresholdBytes = 2 * 1024 * 1024;

  int? get effectiveMinSizeBytes {
    if (minSizeBytes != null) return minSizeBytes;
    return ignoreSmallFiles ? defaultSmallFileThresholdBytes : null;
  }

  bool acceptsExtension(String extension) {
    final normalized = extension.toLowerCase().replaceFirst('.', '');
    if (onlyVideo && !{'mp4', 'webm'}.contains(normalized)) return false;
    return allowedExtensions.contains(normalized);
  }

  bool acceptsSize(int? sizeBytes) {
    final minimum = effectiveMinSizeBytes;
    if (minimum == null || sizeBytes == null) return true;
    return sizeBytes >= minimum;
  }
}
