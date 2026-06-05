import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SourceInstaller'**
  String get appTitle;

  /// No description provided for @analyzeTab.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeTab;

  /// No description provided for @tasksTab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTab;

  /// No description provided for @logTab.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logTab;

  /// No description provided for @urlFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Resource URL'**
  String get urlFieldLabel;

  /// No description provided for @urlFieldHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get urlFieldHint;

  /// No description provided for @onlyVideoFilter.
  ///
  /// In en, this message translates to:
  /// **'Video only'**
  String get onlyVideoFilter;

  /// No description provided for @ignoreSmallFilesFilter.
  ///
  /// In en, this message translates to:
  /// **'Ignore files smaller than 2 MB'**
  String get ignoreSmallFilesFilter;

  /// No description provided for @downloadLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Bulk download limit'**
  String get downloadLimitLabel;

  /// No description provided for @downloadLimitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get downloadLimitUnlimited;

  /// No description provided for @downloadLimitFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String downloadLimitFiles(int count);

  /// No description provided for @startAnalysisButton.
  ///
  /// In en, this message translates to:
  /// **'Start analysis'**
  String get startAnalysisButton;

  /// No description provided for @noMediaFound.
  ///
  /// In en, this message translates to:
  /// **'No media found yet'**
  String get noMediaFound;

  /// No description provided for @foundFiles.
  ///
  /// In en, this message translates to:
  /// **'Files found: {count}'**
  String foundFiles(int count);

  /// No description provided for @downloadAllButton.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get downloadAllButton;

  /// No description provided for @downloadLimitedButton.
  ///
  /// In en, this message translates to:
  /// **'Download {count}'**
  String downloadLimitedButton(int count);

  /// No description provided for @previewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTooltip;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @downloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadTooltip;

  /// No description provided for @alreadyDownloadedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Already downloaded'**
  String get alreadyDownloadedTooltip;

  /// No description provided for @downloadInProgressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download in progress'**
  String get downloadInProgressTooltip;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Download queue is empty'**
  String get queueEmpty;

  /// No description provided for @pauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTooltip;

  /// No description provided for @cancelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTooltip;

  /// No description provided for @queuedState.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queuedState;

  /// No description provided for @runningState.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get runningState;

  /// No description provided for @pausedState.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedState;

  /// No description provided for @completedState.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedState;

  /// No description provided for @failedState.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedState;

  /// No description provided for @canceledState.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceledState;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log is empty'**
  String get logEmpty;

  /// No description provided for @captchaRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'WebView required'**
  String get captchaRequiredTitle;

  /// No description provided for @captchaRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Open the page in the WebView below. The app will continue automatically; if it does not, retry analysis manually.'**
  String get captchaRequiredMessage;

  /// No description provided for @retryAnalysisButton.
  ///
  /// In en, this message translates to:
  /// **'Retry analysis'**
  String get retryAnalysisButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
