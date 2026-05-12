// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'محاسبة';

  @override
  String get pointsLabel => 'نقاط';

  @override
  String pointsRatio(int completed, int total) {
    return '$completed / $total نقطة';
  }

  @override
  String get taskStateChecked => 'مُحدد';

  @override
  String get taskStateUnchecked => 'غير مُحدد';

  @override
  String taskRowSemanticLabel(String title, int points, String state) {
    return '$title، $points نقطة، $state';
  }

  @override
  String get languageToggleTooltip =>
      'تبديل اللغة (النظام، الإنجليزية، العربية)';

  @override
  String get languageAutoSuffix => 'تلقائي';

  @override
  String get categoryFajr => 'الفجر';

  @override
  String get categoryDhuhr => 'الظهر';

  @override
  String get categoryAsr => 'العصر';

  @override
  String get categoryMaghrib => 'المغرب';

  @override
  String get categoryIsha => 'العشاء';

  @override
  String get categoryQiyamEvening => 'قيام الليل والعبادة المسائية';

  @override
  String get categoryQuranFasting => 'القرآن والصيام';

  @override
  String get categoryMiscAdhkar => 'أذكار متنوعة';

  @override
  String get taskFajrWakingUpAdhkar => 'أذكار الاستيقاظ';

  @override
  String get taskFajrSunnahBeforeFajr => 'سنة قبل الفجر';

  @override
  String get taskFajrFirstCongregation => 'الجماعة في أول وقت';

  @override
  String get taskFajrPostPrayerAdhkar => 'أذكار بعد الصلاة';

  @override
  String get taskFajrMorningAdhkar => 'أذكار الصباح';

  @override
  String get taskFajrDuhaPrayer4Rakahs => 'صلاة الضحى — 4 ركعات';

  @override
  String get taskDhuhrSunnahBefore4Rakahs => 'سنة قبل الظهر — 4 ركعات';

  @override
  String get taskDhuhrFirstCongregation => 'الجماعة في أول وقت';

  @override
  String get taskDhuhrPostPrayerAdhkar => 'أذكار بعد الصلاة';

  @override
  String get taskDhuhrSunnahAfter => 'سنة بعد الظهر';

  @override
  String get taskAsrFirstCongregation => 'الجماعة في أول وقت';

  @override
  String get taskAsrPostPrayerAdhkar => 'أذكار بعد الصلاة';

  @override
  String get taskAsrEveningAdhkar => 'أذكار المساء';

  @override
  String get taskMaghribFirstCongregation => 'الجماعة في أول وقت';

  @override
  String get taskMaghribPostPrayerAdhkar => 'أذكار بعد الصلاة';

  @override
  String get taskMaghribSunnahAfter => 'سنة بعد المغرب';

  @override
  String get taskIshaFirstCongregation => 'الجماعة في أول وقت';

  @override
  String get taskIshaPostPrayerAdhkar => 'أذكار بعد الصلاة';

  @override
  String get taskIshaSunnahAfter => 'سنة بعد العشاء';

  @override
  String get taskQiyamTwoRakahs => 'ركعتان من قيام الليل';

  @override
  String get taskQiyamDailyQuranTwoQuarters => 'ورد القرآن اليومي — ربعان';

  @override
  String get taskQiyamWitr => 'صلاة الوتر';

  @override
  String get taskQiyamAdhkarBeforeSleep => 'أذكار قبل النوم';

  @override
  String get taskQuranMemorizeHalfPage => 'حفظ نصف صفحة';

  @override
  String get taskQuranReadSixQuarters => 'قراءة ستة أرباع (حوالي 1.5 جزء)';

  @override
  String get taskQuranFastingMonThu => 'صيام الاثنين والخميس';

  @override
  String get taskMiscRestroomAdhkar => 'أذكار دخول وخروج الحمام';

  @override
  String get taskMiscClothingAdhkar => 'أذكار لبس وخلع الملابس';

  @override
  String get taskMiscWuduAdhkar => 'أذكار الوضوء';

  @override
  String get taskMiscHouseAdhkar => 'أذكار دخول وخروج البيت';

  @override
  String get taskMiscMosqueAdhkar => 'أذكار دخول وخروج المسجد';

  @override
  String get taskMiscWalkingMosqueAdhkar => 'أذكار المشي إلى المسجد';

  @override
  String get taskMiscEatingDrinkingAdhkar => 'أذكار الأكل والشرب';

  @override
  String get taskMiscRidingTravelingAdhkar => 'أذكار الركوب والسفر';
}
