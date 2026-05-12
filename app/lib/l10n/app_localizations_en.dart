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
}
