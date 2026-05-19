// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Muhasabah';

  @override
  String get pointsLabel => 'pts';

  @override
  String pointsRatio(int completed, int total) {
    return '$completed / $total points';
  }

  @override
  String get taskStateChecked => 'checked';

  @override
  String get taskStateUnchecked => 'not checked';

  @override
  String taskRowSemanticLabel(String title, int points, String state) {
    return '$title, $points points, $state';
  }

  @override
  String get languageToggleTooltip =>
      'Switch language (system, English, Arabic)';

  @override
  String get languageAutoSuffix => 'auto';

  @override
  String get categoryFajr => 'Fajr';

  @override
  String get categoryDhuhr => 'Dhuhr';

  @override
  String get categoryAsr => 'Asr';

  @override
  String get categoryMaghrib => 'Maghrib';

  @override
  String get categoryIsha => 'Isha';

  @override
  String get categoryQiyamEvening => 'Qiyam & Evening Devotion';

  @override
  String get categoryQuranFasting => 'Quran & Fasting';

  @override
  String get categoryMiscAdhkar => 'Miscellaneous Adhkar';

  @override
  String get taskFajrWakingUpAdhkar => 'Waking up Adhkar';

  @override
  String get taskFajrSunnahBeforeFajr => 'Sunnah before Fajr';

  @override
  String get taskFajrFirstCongregation => 'First Congregation (Jama\'ah)';

  @override
  String get taskFajrPostPrayerAdhkar => 'Post-prayer Adhkar';

  @override
  String get taskFajrMorningAdhkar => 'Morning Adhkar';

  @override
  String get taskFajrDuhaPrayer4Rakahs => 'Duha Prayer — 4 Rak\'ahs';

  @override
  String get taskDhuhrSunnahBefore4Rakahs => 'Sunnah before Dhuhr — 4 Rak\'ahs';

  @override
  String get taskDhuhrFirstCongregation => 'First Congregation (Jama\'ah)';

  @override
  String get taskDhuhrPostPrayerAdhkar => 'Post-prayer Adhkar';

  @override
  String get taskDhuhrSunnahAfter => 'Sunnah after Dhuhr';

  @override
  String get taskAsrFirstCongregation => 'First Congregation (Jama\'ah)';

  @override
  String get taskAsrPostPrayerAdhkar => 'Post-prayer Adhkar';

  @override
  String get taskAsrEveningAdhkar => 'Evening Adhkar';

  @override
  String get taskMaghribFirstCongregation => 'First Congregation (Jama\'ah)';

  @override
  String get taskMaghribPostPrayerAdhkar => 'Post-prayer Adhkar';

  @override
  String get taskMaghribSunnahAfter => 'Sunnah after Maghrib';

  @override
  String get taskIshaFirstCongregation => 'First Congregation (Jama\'ah)';

  @override
  String get taskIshaPostPrayerAdhkar => 'Post-prayer Adhkar';

  @override
  String get taskIshaSunnahAfter => 'Sunnah after Isha';

  @override
  String get taskQiyamTwoRakahs => 'Two Rak\'ahs of Qiyam al-Layl';

  @override
  String get taskQiyamDailyQuranTwoQuarters =>
      'Daily Quran Portion (Wird) — Two quarters';

  @override
  String get taskQiyamWitr => 'Witr Prayer';

  @override
  String get taskQiyamAdhkarBeforeSleep => 'Adhkar before sleep';

  @override
  String get taskQuranMemorizeHalfPage => 'Memorizing half a page';

  @override
  String get taskQuranReadSixQuarters => 'Reading six quarters (~1.5 Juz\')';

  @override
  String get taskQuranFastingMonThu => 'Fasting (Monday and Thursday)';

  @override
  String get taskMiscRestroomAdhkar => 'Restroom Adhkar (Entering/Leaving)';

  @override
  String get taskMiscClothingAdhkar =>
      'Clothing Adhkar (Putting on/Taking off)';

  @override
  String get taskMiscWuduAdhkar => 'Wudu (Ablution) Adhkar';

  @override
  String get taskMiscHouseAdhkar => 'House Adhkar (Entering/Leaving)';

  @override
  String get taskMiscMosqueAdhkar => 'Mosque Adhkar (Entering/Leaving)';

  @override
  String get taskMiscWalkingMosqueAdhkar => 'Walking to the Mosque Adhkar';

  @override
  String get taskMiscEatingDrinkingAdhkar => 'Eating and Drinking Adhkar';

  @override
  String get taskMiscRidingTravelingAdhkar => 'Riding/Traveling Adhkar';

  @override
  String get dayLabelToday => 'Today';

  @override
  String get dayLabelYesterday => 'Yesterday';

  @override
  String get dayPickerPreviousLabel => 'Previous day';

  @override
  String get dayPickerNextLabel => 'Next day';

  @override
  String get readOnlyBadge => 'Read-only';

  @override
  String get resetTodayDialogTitle => 'Reset today\'s progress?';

  @override
  String get resetTodayDialogBody =>
      'This will uncheck every task for today. Past days are not affected.';

  @override
  String get resetTodayDialogCancel => 'Cancel';

  @override
  String get resetTodayDialogConfirm => 'Reset';

  @override
  String get loadingChecklist => 'Loading your checklist…';

  @override
  String get navChecklistLabel => 'Checklist';

  @override
  String get navDashboardLabel => 'Dashboard';

  @override
  String get navSettingsLabel => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsGlobalToggleLabel =>
      'Enable all notifications';

  @override
  String settingsCategoryScheduleTimeLabel(String category, String time) {
    return '$category · $time';
  }

  @override
  String get settingsEodToggleLabel => 'End-of-day summary';

  @override
  String settingsEodTimeLabel(String time) {
    return 'At $time';
  }

  @override
  String get settingsEodThresholdNote =>
      'Fires when daily completion is below 50 %.';

  @override
  String get settingsWebNotificationNote =>
      'Notifications require the app tab to be open.';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String settingsVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get onboardingNotifTitle => 'Stay consistent';

  @override
  String get onboardingNotifBody =>
      'Allow gentle reminders so the app can nudge you at your chosen prayer times. You control which reminders you receive.';

  @override
  String get onboardingNotifEnableButton => 'Enable notifications';

  @override
  String get onboardingNotifSkipButton => 'Not now';

  @override
  String notifCategoryBody(String taskSummary) {
    return '$taskSummary';
  }

  @override
  String notifEodBody(int percent) {
    return 'You\'re at $percent% today. A few minutes of Adhkar can change the day.';
  }

  @override
  String settingsTaskNotifToggleA11y(String taskName) {
    return 'Enable notification for $taskName';
  }

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardRangeWeek => 'Week';

  @override
  String get dashboardRangeMonth => 'Month';

  @override
  String get dashboardRange90 => '90 days';

  @override
  String get dashboardWeeklyBarsTitle => 'Daily completion';

  @override
  String get dashboardHeatmapTitle => 'Activity map';

  @override
  String get dashboardCategoriesTitle => 'By category';

  @override
  String get dashboardEmptyTitle => 'No data yet';

  @override
  String get dashboardEmptyBody =>
      'Complete a task on the Checklist to see your insights bloom here.';

  @override
  String get dashboardEmptyCtaLabel => 'Open Checklist';

  @override
  String get dashboardErrorLabel => 'Something went wrong loading this view.';

  @override
  String get dashboardRetryLabel => 'Retry';

  @override
  String get categoryChartTypeBarsTooltip => 'Bars';

  @override
  String get categoryChartTypeRadarTooltip => 'Radar';

  @override
  String get categoryChartTypeStackedTooltip => 'Stacked';

  @override
  String get categoryChartTypeDonutTooltip => 'Donut';

  @override
  String get categoryNameFajr => 'Fajr';

  @override
  String get categoryNameDhuhr => 'Dhuhr';

  @override
  String get categoryNameAsr => 'Asr';

  @override
  String get categoryNameMaghrib => 'Maghrib';

  @override
  String get categoryNameIsha => 'Isha';

  @override
  String get categoryNameQiyamEvening => 'Qiyam & Evening';

  @override
  String get categoryNameQuranFasting => 'Quran & Fasting';

  @override
  String get categoryNameMiscAdhkar => 'Adhkar';

  @override
  String dashboardBarA11y(String date, int percent, String fardState) {
    return '$date, $percent percent, $fardState';
  }

  @override
  String dashboardHeatmapCellA11y(String date, int percent, String fardState) {
    return '$date, $percent percent complete, $fardState';
  }

  @override
  String dashboardCategoryA11y(String category, int percent) {
    return '$category: $percent percent complete';
  }

  @override
  String historyStripCellA11y(String date, int percent, String fardState) {
    return '$date, $percent percent complete, $fardState';
  }

  @override
  String get historyStripFardComplete => 'fard complete';

  @override
  String get historyStripFardIncomplete => 'fard not complete';

  @override
  String streakCurrentLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Current: $count $_temp0';
  }

  @override
  String get streakCurrentEmpty => 'Start a streak today';

  @override
  String streakLongestLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Best: $count $_temp0';
  }

  @override
  String streakLongestWindowQualifier(int days) {
    return '(last $days days)';
  }

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordTooShort => 'Use at least 8 characters';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameInvalid => 'Name must be at least 2 characters';

  @override
  String get authNoAccountPrompt => 'New here? Create an account';

  @override
  String get authHaveAccountPrompt => 'Already have an account? Sign in';

  @override
  String get authConfirmEmailTitle => 'Confirm your email';

  @override
  String authConfirmEmailCodeBody(String email) {
    return 'We sent a 6-digit code to $email. Enter it below.';
  }

  @override
  String get authConfirmationCodeLabel => 'Confirmation code';

  @override
  String get authConfirmCodeButton => 'Confirm email';

  @override
  String get authCodeInvalid => 'Enter the 6-digit code from your email';

  @override
  String get authEmailConfirmedSignIn =>
      'Email confirmed. You can sign in now.';

  @override
  String get authResendConfirmation => 'Resend code';

  @override
  String get authResendSent => 'If an account exists, a new code was sent.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSignOutConfirm =>
      'Sign out? Your data on this device will be kept.';

  @override
  String get authSignOutCancel => 'Stay signed in';

  @override
  String syncHistorySnack(int days) {
    return 'Synced $days days of history.';
  }

  @override
  String get syncLoadingMessage => 'Syncing your data…';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSave => 'Save';

  @override
  String get profilePhotoUrlLabel => 'Photo URL (optional)';

  @override
  String get profileTimezoneLabel => 'Timezone (optional)';

  @override
  String get profileLocaleLabel => 'Language';

  @override
  String get profileLocaleEn => 'English';

  @override
  String get profileLocaleAr => 'Arabic';

  @override
  String get profileBioLabel => 'Bio (optional)';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsSyncNow => 'Sync now';

  @override
  String get settingsSyncDone => 'Sync complete.';

  @override
  String get manageChecklistTitle => 'Manage checklist';

  @override
  String get manageChecklistMenu => 'Manage checklist';

  @override
  String get manageChecklistCategoriesTab => 'Categories';

  @override
  String get manageChecklistTasksTab => 'Tasks';

  @override
  String get manageChecklistAddCategory => 'Add category';

  @override
  String get manageChecklistAddTask => 'Add task';

  @override
  String get manageChecklistEditCategory => 'Edit category';

  @override
  String get manageChecklistEditTask => 'Edit task';

  @override
  String get manageChecklistNameLabel => 'Name';

  @override
  String get manageChecklistCategoryLabel => 'Category';

  @override
  String get manageChecklistSave => 'Save';

  @override
  String get manageChecklistCancel => 'Cancel';

  @override
  String get manageChecklistHide => 'Hide';

  @override
  String get manageChecklistFardHideTitle => 'Hide this task?';

  @override
  String get manageChecklistFardHideBody =>
      'This is an obligatory prayer. Hiding removes it from your daily count, not from your day.';
}
