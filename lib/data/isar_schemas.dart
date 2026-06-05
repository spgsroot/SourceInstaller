import 'package:isar_community/isar.dart';

part 'isar_schemas.g.dart';

@collection
class HistorySchema {
  Id id = Isar.autoIncrement;
  late String sourceUrl;
  late int foundCount;
  late DateTime createdAt;
}

@collection
class LogSchema {
  Id id = Isar.autoIncrement;
  late DateTime timestamp;
  late String level;
  late String message;
  String? source;
}

@collection
class DownloadedFileSchema {
  Id id = Isar.autoIncrement;
  late String url;
  late String fileName;
  late String savedPath;
  late String extension;
  late DateTime downloadedAt;
  String? sourceUrl;
}

@collection
class FilterSettingsSchema {
  Id id = Isar.autoIncrement;
  bool onlyVideo = true;
  bool ignoreSmallFiles = false;
  int? minSizeBytes;
  int? downloadLimit;
  List<String> allowedExtensions = const ['mp4', 'webm'];
}
