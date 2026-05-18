import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Muhasabah'**
  String get appTitle;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsLabel;

  /// No description provided for @pointsRatio.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} points'**
  String pointsRatio(int completed, int total);

  /// No description provided for @taskStateChecked.
  ///
  /// In en, this message translates to:
  /// **'checked'**
  String get taskStateChecked;

  /// No description provided for @taskStateUnchecked.
  ///
  /// In en, this message translates to:
  /// **'not checked'**
  String get taskStateUnchecked;

  /// No description provided for @taskRowSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{title}, {points} points, {state}'**
  String taskRowSemanticLabel(String title, int points, String state);

  /// No description provided for @languageToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch language (system, English, Arabic)'**
  String get languageToggleTooltip;

  /// No description provided for @languageAutoSuffix.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get languageAutoSuffix;

  /// No description provided for @categoryFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get categoryFajr;

  /// No description provided for @categoryDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get categoryDhuhr;

  /// No description provided for @categoryAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get categoryAsr;

  /// No description provided for @categoryMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get categoryMaghrib;

  /// No description provided for @categoryIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get categoryIsha;

  /// No description provided for @categoryQiyamEvening.
  ///
  /// In en, this message translates to:
  /// **'Qiyam & Evening Devotion'**
  String get categoryQiyamEvening;

  /// No description provided for @categoryQuranFasting.
  ///
  /// In en, this message translates to:
  /// **'Quran & Fasting'**
  String get categoryQuranFasting;

  /// No description provided for @categoryMiscAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous Adhkar'**
  String get categoryMiscAdhkar;

  /// No description provided for @taskFajrWakingUpAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Waking up Adhkar'**
  String get taskFajrWakingUpAdhkar;

  /// No description provided for @taskFajrSunnahBeforeFajr.
  ///
  /// In en, this message translates to:
  /// **'Sunnah before Fajr'**
  String get taskFajrSunnahBeforeFajr;

  /// No description provided for @taskFajrFirstCongregation.
  ///
  /// In en, this message translates to:
  /// **'First Congregation (Jama\'ah)'**
  String get taskFajrFirstCongregation;

  /// No description provided for @taskFajrPostPrayerAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer Adhkar'**
  String get taskFajrPostPrayerAdhkar;

  /// No description provided for @taskFajrMorningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Morning Adhkar'**
  String get taskFajrMorningAdhkar;

  /// No description provided for @taskFajrDuhaPrayer4Rakahs.
  ///
  /// In en, this message translates to:
  /// **'Duha Prayer — 4 Rak\'ahs'**
  String get taskFajrDuhaPrayer4Rakahs;

  /// No description provided for @taskDhuhrSunnahBefore4Rakahs.
  ///
  /// In en, this message translates to:
  /// **'Sunnah before Dhuhr — 4 Rak\'ahs'**
  String get taskDhuhrSunnahBefore4Rakahs;

  /// No description provided for @taskDhuhrFirstCongregation.
  ///
  /// In en, this message translates to:
  /// **'First Congregation (Jama\'ah)'**
  String get taskDhuhrFirstCongregation;

  /// No description provided for @taskDhuhrPostPrayerAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer Adhkar'**
  String get taskDhuhrPostPrayerAdhkar;

  /// No description provided for @taskDhuhrSunnahAfter.
  ///
  /// In en, this message translates to:
  /// **'Sunnah after Dhuhr'**
  String get taskDhuhrSunnahAfter;

  /// No description provided for @taskAsrFirstCongregation.
  ///
  /// In en, this message translates to:
  /// **'First Congregation (Jama\'ah)'**
  String get taskAsrFirstCongregation;

  /// No description provided for @taskAsrPostPrayerAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer Adhkar'**
  String get taskAsrPostPrayerAdhkar;

  /// No description provided for @taskAsrEveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Evening Adhkar'**
  String get taskAsrEveningAdhkar;

  /// No description provided for @taskMaghribFirstCongregation.
  ///
  /// In en, this message translates to:
  /// **'First Congregation (Jama\'ah)'**
  String get taskMaghribFirstCongregation;

  /// No description provided for @taskMaghribPostPrayerAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer Adhkar'**
  String get taskMaghribPostPrayerAdhkar;

  /// No description provided for @taskMaghribSunnahAfter.
  ///
  /// In en, this message translates to:
  /// **'Sunnah after Maghrib'**
  String get taskMaghribSunnahAfter;

  /// No description provided for @taskIshaFirstCongregation.
  ///
  /// In en, this message translates to:
  /// **'First Congregation (Jama\'ah)'**
  String get taskIshaFirstCongregation;

  /// No description provided for @taskIshaPostPrayerAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Post-prayer Adhkar'**
  String get taskIshaPostPrayerAdhkar;

  /// No description provided for @taskIshaSunnahAfter.
  ///
  /// In en, this message translates to:
  /// **'Sunnah after Isha'**
  String get taskIshaSunnahAfter;

  /// No description provided for @taskQiyamTwoRakahs.
  ///
  /// In en, this message translates to:
  /// **'Two Rak\'ahs of Qiyam al-Layl'**
  String get taskQiyamTwoRakahs;

  /// No description provided for @taskQiyamDailyQuranTwoQuarters.
  ///
  /// In en, this message translates to:
  /// **'Daily Quran Portion (Wird) — Two quarters'**
  String get taskQiyamDailyQuranTwoQuarters;

  /// No description provided for @taskQiyamWitr.
  ///
  /// In en, this message translates to:
  /// **'Witr Prayer'**
  String get taskQiyamWitr;

  /// No description provided for @taskQiyamAdhkarBeforeSleep.
  ///
  /// In en, this message translates to:
  /// **'Adhkar before sleep'**
  String get taskQiyamAdhkarBeforeSleep;

  /// No description provided for @taskQuranMemorizeHalfPage.
  ///
  /// In en, this message translates to:
  /// **'Memorizing half a page'**
  String get taskQuranMemorizeHalfPage;

  /// No description provided for @taskQuranReadSixQuarters.
  ///
  /// In en, this message translates to:
  /// **'Reading six quarters (~1.5 Juz\')'**
  String get taskQuranReadSixQuarters;

  /// No description provided for @taskQuranFastingMonThu.
  ///
  /// In en, this message translates to:
  /// **'Fasting (Monday and Thursday)'**
  String get taskQuranFastingMonThu;

  /// No description provided for @taskMiscRestroomAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Restroom Adhkar (Entering/Leaving)'**
  String get taskMiscRestroomAdhkar;

  /// No description provided for @taskMiscClothingAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Clothing Adhkar (Putting on/Taking off)'**
  String get taskMiscClothingAdhkar;

  /// No description provided for @taskMiscWuduAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Wudu (Ablution) Adhkar'**
  String get taskMiscWuduAdhkar;

  /// No description provided for @taskMiscHouseAdhkar.
  ///
  /// In en, this message translates to:
  /// **'House Adhkar (Entering/Leaving)'**
  String get taskMiscHouseAdhkar;

  /// No description provided for @taskMiscMosqueAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Mosque Adhkar (Entering/Leaving)'**
  String get taskMiscMosqueAdhkar;

  /// No description provided for @taskMiscWalkingMosqueAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Walking to the Mosque Adhkar'**
  String get taskMiscWalkingMosqueAdhkar;

  /// No description provided for @taskMiscEatingDrinkingAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Eating and Drinking Adhkar'**
  String get taskMiscEatingDrinkingAdhkar;

  /// No description provided for @taskMiscRidingTravelingAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Riding/Traveling Adhkar'**
  String get taskMiscRidingTravelingAdhkar;

  /// No description provided for @dayLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayLabelToday;

  /// No description provided for @dayLabelYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayLabelYesterday;

  /// No description provided for @dayPickerPreviousLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get dayPickerPreviousLabel;

  /// No description provided for @dayPickerNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get dayPickerNextLabel;

  /// No description provided for @readOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnlyBadge;

  /// No description provided for @resetTodayDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset today\'s progress?'**
  String get resetTodayDialogTitle;

  /// No description provided for @resetTodayDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will uncheck every task for today. Past days are not affected.'**
  String get resetTodayDialogBody;

  /// No description provided for @resetTodayDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get resetTodayDialogCancel;

  /// No description provided for @resetTodayDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTodayDialogConfirm;

  /// No description provided for @loadingChecklist.
  ///
  /// In en, this message translates to:
  /// **'Loading your checklist…'**
  String get loadingChecklist;

  /// No description provided for @navChecklistLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get navChecklistLabel;

  /// No description provided for @navDashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboardLabel;

  /// No description provided for @navSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettingsLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsGlobalToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable all notifications'**
  String get settingsNotificationsGlobalToggleLabel;

  /// No description provided for @settingsCategoryScheduleTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'{category} · {time}'**
  String settingsCategoryScheduleTimeLabel(String category, String time);

  /// No description provided for @settingsEodToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'End-of-day summary'**
  String get settingsEodToggleLabel;

  /// No description provided for @settingsEodTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String settingsEodTimeLabel(String time);

  /// No description provided for @settingsEodThresholdNote.
  ///
  /// In en, this message translates to:
  /// **'Fires when daily completion is below 50 %.'**
  String get settingsEodThresholdNote;

  /// No description provided for @settingsWebNotificationNote.
  ///
  /// In en, this message translates to:
  /// **'Notifications require the app tab to be open.'**
  String get settingsWebNotificationNote;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersionLabel(String version);

  /// No description provided for @onboardingNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay consistent'**
  String get onboardingNotifTitle;

  /// No description provided for @onboardingNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Allow gentle reminders so the app can nudge you at your chosen prayer times. You control which reminders you receive.'**
  String get onboardingNotifBody;

  /// No description provided for @onboardingNotifEnableButton.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get onboardingNotifEnableButton;

  /// No description provided for @onboardingNotifSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotifSkipButton;

  /// No description provided for @notifCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'{taskSummary}'**
  String notifCategoryBody(String taskSummary);

  /// No description provided for @notifEodBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re at {percent}% today. A few minutes of Adhkar can change the day.'**
  String notifEodBody(int percent);

  /// No description provided for @settingsTaskNotifToggleA11y.
  ///
  /// In en, this message translates to:
  /// **'Enable notification for {taskName}'**
  String settingsTaskNotifToggleA11y(String taskName);

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get dashboardRangeWeek;

  /// No description provided for @dashboardRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get dashboardRangeMonth;

  /// No description provided for @dashboardRange90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get dashboardRange90;

  /// No description provided for @dashboardWeeklyBarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily completion'**
  String get dashboardWeeklyBarsTitle;

  /// No description provided for @dashboardHeatmapTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity map'**
  String get dashboardHeatmapTitle;

  /// No description provided for @dashboardCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get dashboardCategoriesTitle;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a task on the Checklist to see your insights bloom here.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardEmptyCtaLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Checklist'**
  String get dashboardEmptyCtaLabel;

  /// No description provided for @dashboardErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading this view.'**
  String get dashboardErrorLabel;

  /// No description provided for @dashboardRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dashboardRetryLabel;

  /// No description provided for @categoryChartTypeBarsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get categoryChartTypeBarsTooltip;

  /// No description provided for @categoryChartTypeRadarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get categoryChartTypeRadarTooltip;

  /// No description provided for @categoryChartTypeStackedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get categoryChartTypeStackedTooltip;

  /// No description provided for @categoryChartTypeDonutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Donut'**
  String get categoryChartTypeDonutTooltip;

  /// No description provided for @categoryNameFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get categoryNameFajr;

  /// No description provided for @categoryNameDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get categoryNameDhuhr;

  /// No description provided for @categoryNameAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get categoryNameAsr;

  /// No description provided for @categoryNameMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get categoryNameMaghrib;

  /// No description provided for @categoryNameIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get categoryNameIsha;

  /// No description provided for @categoryNameQiyamEvening.
  ///
  /// In en, this message translates to:
  /// **'Qiyam & Evening'**
  String get categoryNameQiyamEvening;

  /// No description provided for @categoryNameQuranFasting.
  ///
  /// In en, this message translates to:
  /// **'Quran & Fasting'**
  String get categoryNameQuranFasting;

  /// No description provided for @categoryNameMiscAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get categoryNameMiscAdhkar;

  /// No description provided for @dashboardBarA11y.
  ///
  /// In en, this message translates to:
  /// **'{date}, {percent} percent, {fardState}'**
  String dashboardBarA11y(String date, int percent, String fardState);

  /// No description provided for @dashboardHeatmapCellA11y.
  ///
  /// In en, this message translates to:
  /// **'{date}, {percent} percent complete, {fardState}'**
  String dashboardHeatmapCellA11y(String date, int percent, String fardState);

  /// No description provided for @dashboardCategoryA11y.
  ///
  /// In en, this message translates to:
  /// **'{category}: {percent} percent complete'**
  String dashboardCategoryA11y(String category, int percent);

  /// No description provided for @historyStripCellA11y.
  ///
  /// In en, this message translates to:
  /// **'{date}, {percent} percent complete, {fardState}'**
  String historyStripCellA11y(String date, int percent, String fardState);

  /// No description provided for @historyStripFardComplete.
  ///
  /// In en, this message translates to:
  /// **'fard complete'**
  String get historyStripFardComplete;

  /// No description provided for @historyStripFardIncomplete.
  ///
  /// In en, this message translates to:
  /// **'fard not complete'**
  String get historyStripFardIncomplete;

  /// No description provided for @streakCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current: {count} {count, plural, one{day} other{days}}'**
  String streakCurrentLabel(int count);

  /// No description provided for @streakCurrentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start a streak today'**
  String get streakCurrentEmpty;

  /// No description provided for @streakLongestLabel.
  ///
  /// In en, this message translates to:
  /// **'Best: {count} {count, plural, one{day} other{days}}'**
  String streakLongestLabel(int count);

  /// No description provided for @streakLongestWindowQualifier.
  ///
  /// In en, this message translates to:
  /// **'(last {days} days)'**
  String streakLongestWindowQualifier(int days);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
