import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_schemas.dart';

class AppDatabase {
  const AppDatabase._(this.isar);

  final Isar isar;

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        HistorySchemaSchema,
        LogSchemaSchema,
        DownloadedFileSchemaSchema,
        FilterSettingsSchemaSchema,
      ],
      directory: directory.path,
      name: 'source_installer',
    );
    return AppDatabase._(isar);
  }

  Future<void> close() => isar.close();
}
