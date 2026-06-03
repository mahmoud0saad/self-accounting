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

  /// No description provided for @taskToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this task. Please try again.'**
  String get taskToggleFailed;

  /// No description provided for @taskRowSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{title}, {points} points, {state}'**
  String taskRowSemanticLabel(String title, int points, String state);

  /// No description provided for @languageToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch language (Arabic, English)'**
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
  /// **'Allow a gentle end-of-day reminder when your daily completion is below 50%. You choose the time in Settings.'**
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

  /// No description provided for @notifEodBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re at {percent}% today. A few minutes of Adhkar can change the day.'**
  String notifEodBody(int percent);

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

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get authFullNameInvalid;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authNoAccountPrompt;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccountPrompt;

  /// No description provided for @authConfirmEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get authConfirmEmailTitle;

  /// No description provided for @authConfirmEmailCodeBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it below.'**
  String authConfirmEmailCodeBody(String email);

  /// No description provided for @authConfirmationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get authConfirmationCodeLabel;

  /// No description provided for @authConfirmCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get authConfirmCodeButton;

  /// No description provided for @authCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your email'**
  String get authCodeInvalid;

  /// No description provided for @authEmailConfirmedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed. You can sign in now.'**
  String get authEmailConfirmedSignIn;

  /// No description provided for @authResendConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendConfirmation;

  /// No description provided for @authResendSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, a new code was sent.'**
  String get authResendSent;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out? Your data on this device will be kept.'**
  String get authSignOutConfirm;

  /// No description provided for @authSignOutCancel.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get authSignOutCancel;

  /// No description provided for @syncHistorySnack.
  ///
  /// In en, this message translates to:
  /// **'Synced {days} days of history.'**
  String syncHistorySnack(int days);

  /// No description provided for @syncLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Syncing your data…'**
  String get syncLoadingMessage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profilePhotoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo URL (optional)'**
  String get profilePhotoUrlLabel;

  /// No description provided for @profileTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone (optional)'**
  String get profileTimezoneLabel;

  /// No description provided for @profileLocaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLocaleLabel;

  /// No description provided for @profileLocaleEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLocaleEn;

  /// No description provided for @profileLocaleAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get profileLocaleAr;

  /// No description provided for @profileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio (optional)'**
  String get profileBioLabel;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountTitle;

  /// No description provided for @settingsSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settingsSyncNow;

  /// No description provided for @settingsSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Sync complete.'**
  String get settingsSyncDone;

  /// No description provided for @manageChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage checklist'**
  String get manageChecklistTitle;

  /// No description provided for @manageChecklistMenu.
  ///
  /// In en, this message translates to:
  /// **'Manage checklist'**
  String get manageChecklistMenu;

  /// No description provided for @manageChecklistCategoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get manageChecklistCategoriesTab;

  /// No description provided for @manageChecklistTasksTab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get manageChecklistTasksTab;

  /// No description provided for @manageChecklistAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get manageChecklistAddCategory;

  /// No description provided for @manageChecklistAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get manageChecklistAddTask;

  /// No description provided for @manageChecklistEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get manageChecklistEditCategory;

  /// No description provided for @manageChecklistEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get manageChecklistEditTask;

  /// No description provided for @manageChecklistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get manageChecklistNameLabel;

  /// No description provided for @manageChecklistCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get manageChecklistCategoryLabel;

  /// No description provided for @manageChecklistSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get manageChecklistSave;

  /// No description provided for @manageChecklistCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get manageChecklistCancel;

  /// No description provided for @manageChecklistHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get manageChecklistHide;

  /// No description provided for @manageChecklistFardHideTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this task?'**
  String get manageChecklistFardHideTitle;

  /// No description provided for @manageChecklistFardHideBody.
  ///
  /// In en, this message translates to:
  /// **'This is an obligatory prayer. Hiding removes it from your daily count, not from your day.'**
  String get manageChecklistFardHideBody;

  /// No description provided for @manageChecklistRemovePermanently.
  ///
  /// In en, this message translates to:
  /// **'Remove permanently'**
  String get manageChecklistRemovePermanently;

  /// No description provided for @manageChecklistRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the entry and cannot be undone. Your daily progress on other tasks is kept.'**
  String get manageChecklistRemoveConfirmBody;

  /// No description provided for @manageChecklistRemoveHasHistory.
  ///
  /// In en, this message translates to:
  /// **'This task has history. Hide it instead to keep your records.'**
  String get manageChecklistRemoveHasHistory;

  /// No description provided for @manageChecklistTooltipHide.
  ///
  /// In en, this message translates to:
  /// **'Hide from today — keeps your history.'**
  String get manageChecklistTooltipHide;

  /// No description provided for @manageChecklistTooltipShow.
  ///
  /// In en, this message translates to:
  /// **'Show on today\'s list.'**
  String get manageChecklistTooltipShow;

  /// No description provided for @manageChecklistNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get manageChecklistNewCategory;

  /// No description provided for @manageChecklistAddCustomTask.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Task'**
  String get manageChecklistAddCustomTask;

  /// No description provided for @manageChecklistCustomTasks.
  ///
  /// In en, this message translates to:
  /// **'Custom Tasks'**
  String get manageChecklistCustomTasks;

  /// No description provided for @manageChecklistHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get manageChecklistHiddenLabel;

  /// No description provided for @manageChecklistCustomCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get manageChecklistCustomCategoryLabel;

  /// No description provided for @manageChecklistCustomTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom task'**
  String get manageChecklistCustomTaskLabel;

  /// No description provided for @manageChecklistNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Add one to organize your tasks.'**
  String get manageChecklistNoCategories;

  /// No description provided for @manageChecklistNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks here yet. Add a custom task to begin.'**
  String get manageChecklistNoTasks;

  /// No description provided for @manageChecklistPointsPlus.
  ///
  /// In en, this message translates to:
  /// **'+{points} {label}'**
  String manageChecklistPointsPlus(int points, String label);

  /// No description provided for @restoreCatalogDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your saved checklist?'**
  String get restoreCatalogDialogTitle;

  /// No description provided for @restoreCatalogDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We found your saved checklist on this account. Restoring will replace the customizations on this device — your daily progress on default tasks is kept.'**
  String get restoreCatalogDialogBody;

  /// No description provided for @restoreCatalogDialogRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreCatalogDialogRestore;

  /// No description provided for @settingsRestoreCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore checklist from your account'**
  String get settingsRestoreCatalogTitle;

  /// No description provided for @settingsRestoreCatalogNever.
  ///
  /// In en, this message translates to:
  /// **'Never restored on this device'**
  String get settingsRestoreCatalogNever;

  /// No description provided for @settingsRestoreCatalogLast.
  ///
  /// In en, this message translates to:
  /// **'Last restored: {when}'**
  String settingsRestoreCatalogLast(String when);

  /// No description provided for @settingsRestoreCatalogOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — restore will run when you\'re back online.'**
  String get settingsRestoreCatalogOffline;

  /// No description provided for @restoreCatalogPushing.
  ///
  /// In en, this message translates to:
  /// **'Saving your checklist to your account…'**
  String get restoreCatalogPushing;

  /// No description provided for @restoreCatalogRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring your saved checklist…'**
  String get restoreCatalogRestoring;

  /// No description provided for @restoreCatalogDone.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} items from your account.'**
  String restoreCatalogDone(int count);

  /// No description provided for @restoreCatalogSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved your checklist to your account.'**
  String get restoreCatalogSaved;

  /// No description provided for @restoreUnifiedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your saved data?'**
  String get restoreUnifiedDialogTitle;

  /// No description provided for @restoreUnifiedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We found your saved checklist and your saved challenges on this account. Restoring will replace what\'s on this device — your daily progress on default tasks is kept.'**
  String get restoreUnifiedDialogBody;

  /// No description provided for @restoreChallengesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your saved challenges?'**
  String get restoreChallengesDialogTitle;

  /// No description provided for @restoreChallengesDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We found your saved weekly challenges on this account. Restoring will replace the challenges on this device.'**
  String get restoreChallengesDialogBody;

  /// No description provided for @challengeStartThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week: start a challenge'**
  String get challengeStartThisWeek;

  /// No description provided for @challengeBrowseTemplatesCta.
  ///
  /// In en, this message translates to:
  /// **'Browse templates'**
  String get challengeBrowseTemplatesCta;

  /// No description provided for @challengesThisWeekTab.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get challengesThisWeekTab;

  /// No description provided for @challengesBrowseTab.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get challengesBrowseTab;

  /// No description provided for @challengeSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get challengeSubscribe;

  /// No description provided for @challengeSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get challengeSubscribed;

  /// No description provided for @challengeProgress.
  ///
  /// In en, this message translates to:
  /// **'{achieved} / {goal}'**
  String challengeProgress(int achieved, int goal);

  /// No description provided for @challengeCreateCustom.
  ///
  /// In en, this message translates to:
  /// **'Create custom challenge'**
  String get challengeCreateCustom;

  /// No description provided for @challengeCustomTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get challengeCustomTitleLabel;

  /// No description provided for @challengeCustomIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get challengeCustomIconLabel;

  /// No description provided for @challengeCustomSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get challengeCustomSourceLabel;

  /// No description provided for @challengeSourceTabTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get challengeSourceTabTask;

  /// No description provided for @challengeSourceTabCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get challengeSourceTabCategory;

  /// No description provided for @challengeGoalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal: {days} days this week'**
  String challengeGoalDaysLabel(int days);

  /// No description provided for @challengeCustomCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get challengeCustomCreate;

  /// No description provided for @challengeWeekStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Week start'**
  String get challengeWeekStartTitle;

  /// No description provided for @challengeWeekStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to next week.'**
  String get challengeWeekStartSubtitle;

  /// No description provided for @challengeWeekStartSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get challengeWeekStartSaturday;

  /// No description provided for @challengeWeekStartSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get challengeWeekStartSunday;

  /// No description provided for @challengeWeekStartMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get challengeWeekStartMonday;

  /// No description provided for @challengeWeekStartSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Your new week starts {weekday}.'**
  String challengeWeekStartSnackbar(String weekday);

  /// No description provided for @challengeCelebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Mā shā\' Allāh'**
  String get challengeCelebrationTitle;

  /// No description provided for @challengeCelebrationBody.
  ///
  /// In en, this message translates to:
  /// **'{title} — {goal} of {goal} days this week.'**
  String challengeCelebrationBody(String title, int goal);

  /// No description provided for @challengeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get challengeContinue;

  /// No description provided for @challengeViewChallenge.
  ///
  /// In en, this message translates to:
  /// **'View challenge'**
  String get challengeViewChallenge;

  /// No description provided for @challengeCompletedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Completed this week'**
  String get challengeCompletedThisWeek;

  /// No description provided for @challengeTemplateFajrInJamaah.
  ///
  /// In en, this message translates to:
  /// **'Pray every Fajr in congregation'**
  String get challengeTemplateFajrInJamaah;

  /// No description provided for @challengeTemplateQiyamWitrAllWeek.
  ///
  /// In en, this message translates to:
  /// **'Pray Witr every night'**
  String get challengeTemplateQiyamWitrAllWeek;

  /// No description provided for @challengeTemplateReadQuranDaily.
  ///
  /// In en, this message translates to:
  /// **'Read Qur\'an every day'**
  String get challengeTemplateReadQuranDaily;

  /// No description provided for @challengeTemplateTahajjudThreeNights.
  ///
  /// In en, this message translates to:
  /// **'Stand for Tahajjud three nights'**
  String get challengeTemplateTahajjudThreeNights;

  /// No description provided for @challengeTemplateFajrCategoryAllWeek.
  ///
  /// In en, this message translates to:
  /// **'Complete the Fajr block every day'**
  String get challengeTemplateFajrCategoryAllWeek;

  /// No description provided for @challengeTemplateMorningAdhkarDaily.
  ///
  /// In en, this message translates to:
  /// **'Morning Adhkar every morning'**
  String get challengeTemplateMorningAdhkarDaily;
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
