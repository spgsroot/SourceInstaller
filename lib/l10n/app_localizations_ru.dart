// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'SourceInstaller';

  @override
  String get analyzeTab => 'Анализ';

  @override
  String get tasksTab => 'Задачи';

  @override
  String get logTab => 'Лог';

  @override
  String get urlFieldLabel => 'URL ресурса';

  @override
  String get urlFieldHint => 'https://...';

  @override
  String get onlyVideoFilter => 'Только видео';

  @override
  String get ignoreSmallFilesFilter => 'Игнорировать файлы меньше 2 МБ';

  @override
  String get downloadLimitLabel => 'Лимит массовой загрузки';

  @override
  String get downloadLimitUnlimited => 'Без лимита';

  @override
  String downloadLimitFiles(int count) {
    return '$count файлов';
  }

  @override
  String get startAnalysisButton => 'Начать анализ';

  @override
  String get noMediaFound => 'Медиа пока не найдено';

  @override
  String foundFiles(int count) {
    return 'Найдено файлов: $count';
  }

  @override
  String get downloadAllButton => 'Скачать всё';

  @override
  String downloadLimitedButton(int count) {
    return 'Скачать $count';
  }

  @override
  String get previewTooltip => 'Предпросмотр';

  @override
  String get previewTitle => 'Предпросмотр';

  @override
  String get closeButton => 'Закрыть';

  @override
  String get downloadTooltip => 'Скачать';

  @override
  String get alreadyDownloadedTooltip => 'Уже скачано';

  @override
  String get downloadInProgressTooltip => 'Загрузка уже идёт';

  @override
  String get queueEmpty => 'Очередь загрузок пуста';

  @override
  String get pauseTooltip => 'Пауза';

  @override
  String get cancelTooltip => 'Отмена';

  @override
  String get queuedState => 'В очереди';

  @override
  String get runningState => 'Загрузка';

  @override
  String get pausedState => 'Пауза';

  @override
  String get completedState => 'Готово';

  @override
  String get failedState => 'Ошибка';

  @override
  String get canceledState => 'Отменено';

  @override
  String get logEmpty => 'Лог пуст';

  @override
  String get captchaRequiredTitle => 'Требуется WebView';

  @override
  String get captchaRequiredMessage =>
      'Откройте страницу в WebView ниже. Приложение продолжит анализ автоматически; если этого не произошло, повторите анализ вручную.';

  @override
  String get retryAnalysisButton => 'Повторить анализ';
}
