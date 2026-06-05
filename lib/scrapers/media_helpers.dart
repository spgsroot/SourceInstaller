import '../models/filter_settings.dart';
import '../models/media_item.dart';

const videoExtensions = {'mp4', 'webm'};
const imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
const supportedMediaExtensions = {...videoExtensions, ...imageExtensions};

String? mediaExtensionFromUrl(String url) {
  final uri = Uri.tryParse(url);
  final path = uri?.path.toLowerCase() ?? url.toLowerCase();
  final match = RegExp(r'\.([a-z0-9]+)$').firstMatch(path);
  final extension = match?.group(1);
  if (extension == null) return null;
  return supportedMediaExtensions.contains(extension) ? extension : null;
}

String fileNameFromUrl(String url, {String fallback = 'media'}) {
  final uri = Uri.tryParse(url);
  final segment = uri?.pathSegments.where((part) => part.isNotEmpty).lastOrNull;
  if (segment == null || segment.trim().isEmpty) return fallback;
  return Uri.decodeComponent(segment);
}

String? qualityFromFileName(String fileName) {
  final match = RegExp(
    r'(?<!\d)(\d{3,4}p)(?!\d)',
    caseSensitive: false,
  ).firstMatch(fileName);
  return match?.group(1)?.toLowerCase();
}

List<MediaItem> applyMediaFilters(
  List<MediaItem> items,
  FilterSettings filters,
) {
  return items
      .where((item) {
        return filters.acceptsExtension(item.extension) &&
            filters.acceptsSize(item.sizeBytes);
      })
      .toList(growable: false);
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get lastOrNull {
    final iterator = this.iterator;
    T? last;
    while (iterator.moveNext()) {
      last = iterator.current;
    }
    return last;
  }
}
