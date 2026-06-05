// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SourceInstaller';

  @override
  String get analyzeTab => 'Analyze';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get logTab => 'Log';

  @override
  String get urlFieldLabel => 'Resource URL';

  @override
  String get urlFieldHint => 'https://...';

  @override
  String get onlyVideoFilter => 'Video only';

  @override
  String get ignoreSmallFilesFilter => 'Ignore files smaller than 2 MB';

  @override
  String get downloadLimitLabel => 'Bulk download limit';

  @override
  String get downloadLimitUnlimited => 'No limit';

  @override
  String downloadLimitFiles(int count) {
    return '$count files';
  }

  @override
  String get startAnalysisButton => 'Start analysis';

  @override
  String get noMediaFound => 'No media found yet';

  @override
  String foundFiles(int count) {
    return 'Files found: $count';
  }

  @override
  String get downloadAllButton => 'Download all';

  @override
  String downloadLimitedButton(int count) {
    return 'Download $count';
  }

  @override
  String get previewTooltip => 'Preview';

  @override
  String get previewTitle => 'Preview';

  @override
  String get closeButton => 'Close';

  @override
  String get downloadTooltip => 'Download';

  @override
  String get alreadyDownloadedTooltip => 'Already downloaded';

  @override
  String get downloadInProgressTooltip => 'Download in progress';

  @override
  String get queueEmpty => 'Download queue is empty';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get cancelTooltip => 'Cancel';

  @override
  String get queuedState => 'Queued';

  @override
  String get runningState => 'Downloading';

  @override
  String get pausedState => 'Paused';

  @override
  String get completedState => 'Completed';

  @override
  String get failedState => 'Failed';

  @override
  String get canceledState => 'Canceled';

  @override
  String get logEmpty => 'Log is empty';

  @override
  String get captchaRequiredTitle => 'WebView required';

  @override
  String get captchaRequiredMessage =>
      'Open the page in the WebView below. The app will continue automatically; if it does not, retry analysis manually.';

  @override
  String get retryAnalysisButton => 'Retry analysis';
}
