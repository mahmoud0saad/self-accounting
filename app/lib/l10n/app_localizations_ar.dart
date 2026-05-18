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

  @override
  String get dayLabelToday => 'اليوم';

  @override
  String get dayLabelYesterday => 'أمس';

  @override
  String get dayPickerPreviousLabel => 'اليوم السابق';

  @override
  String get dayPickerNextLabel => 'اليوم التالي';

  @override
  String get readOnlyBadge => 'للقراءة فقط';

  @override
  String get resetTodayDialogTitle => 'إعادة تعيين تقدم اليوم؟';

  @override
  String get resetTodayDialogBody =>
      'سيتم إلغاء تحديد كل المهام لهذا اليوم. الأيام السابقة لن تتأثر.';

  @override
  String get resetTodayDialogCancel => 'إلغاء';

  @override
  String get resetTodayDialogConfirm => 'إعادة تعيين';

  @override
  String get loadingChecklist => 'جارٍ تحميل قائمتك…';

  @override
  String get navChecklistLabel => 'TODO: قائمة المهام';

  @override
  String get navDashboardLabel => 'TODO: لوحة المعلومات';

  @override
  String get navSettingsLabel => 'TODO: الإعدادات';

  @override
  String get settingsTitle => 'TODO: الإعدادات';

  @override
  String get settingsNotificationsTitle => 'TODO: التنبيهات';

  @override
  String get settingsNotificationsGlobalToggleLabel =>
      'TODO: تفعيل كل التنبيهات';

  @override
  String settingsCategoryScheduleTimeLabel(String category, String time) {
    return 'TODO: $category · $time';
  }

  @override
  String get settingsEodToggleLabel => 'TODO: ملخص نهاية اليوم';

  @override
  String settingsEodTimeLabel(String time) {
    return 'TODO: عند $time';
  }

  @override
  String get settingsEodThresholdNote =>
      'TODO: يظهر عندما يكون إنجاز اليوم أقل من 50٪.';

  @override
  String get settingsWebNotificationNote =>
      'TODO: التنبيهات تحتاج أن تبقى نافذة التطبيق مفتوحة.';

  @override
  String get settingsAboutTitle => 'TODO: حول التطبيق';

  @override
  String settingsVersionLabel(String version) {
    return 'TODO: الإصدار $version';
  }

  @override
  String get onboardingNotifTitle => 'TODO: حافظ على الاستمرارية';

  @override
  String get onboardingNotifBody =>
      'TODO: اسمح بتذكيرات لطيفة كي ينبهك التطبيق في أوقات الصلاة التي تختارها. أنت تتحكم في التذكيرات التي تصلك.';

  @override
  String get onboardingNotifEnableButton => 'TODO: تفعيل التنبيهات';

  @override
  String get onboardingNotifSkipButton => 'TODO: ليس الآن';

  @override
  String notifCategoryBody(String taskSummary) {
    return 'TODO: $taskSummary';
  }

  @override
  String notifEodBody(int percent) {
    return 'TODO: أنجزت $percent% اليوم. دقائق من الذكر قد تغير اليوم.';
  }

  @override
  String settingsTaskNotifToggleA11y(String taskName) {
    return 'TODO: تفعيل تنبيه $taskName';
  }

  @override
  String get dashboardTitle => 'TODO: لوحة المعلومات';

  @override
  String get dashboardRangeWeek => 'TODO: أسبوع';

  @override
  String get dashboardRangeMonth => 'TODO: شهر';

  @override
  String get dashboardRange90 => 'TODO: 90 يومًا';

  @override
  String get dashboardWeeklyBarsTitle => 'TODO: الإنجاز اليومي';

  @override
  String get dashboardHeatmapTitle => 'TODO: خريطة النشاط';

  @override
  String get dashboardCategoriesTitle => 'TODO: حسب الفئة';

  @override
  String get dashboardEmptyTitle => 'TODO: لا توجد بيانات بعد';

  @override
  String get dashboardEmptyBody =>
      'TODO: أكمل مهمة في قائمة المهام لتبدأ في عرض الإحصائيات هنا.';

  @override
  String get dashboardEmptyCtaLabel => 'TODO: فتح قائمة المهام';

  @override
  String get dashboardErrorLabel => 'TODO: حدث خطأ أثناء تحميل هذا العرض.';

  @override
  String get dashboardRetryLabel => 'TODO: إعادة المحاولة';

  @override
  String get categoryChartTypeBarsTooltip => 'TODO: أعمدة';

  @override
  String get categoryChartTypeRadarTooltip => 'TODO: رادار';

  @override
  String get categoryChartTypeStackedTooltip => 'TODO: مكدسة';

  @override
  String get categoryChartTypeDonutTooltip => 'TODO: حلقة';

  @override
  String get categoryNameFajr => 'TODO: الفجر';

  @override
  String get categoryNameDhuhr => 'TODO: الظهر';

  @override
  String get categoryNameAsr => 'TODO: العصر';

  @override
  String get categoryNameMaghrib => 'TODO: المغرب';

  @override
  String get categoryNameIsha => 'TODO: العشاء';

  @override
  String get categoryNameQiyamEvening => 'TODO: قيام الليل والمساء';

  @override
  String get categoryNameQuranFasting => 'TODO: القرآن والصيام';

  @override
  String get categoryNameMiscAdhkar => 'TODO: الأذكار';

  @override
  String dashboardBarA11y(String date, int percent, String fardState) {
    return 'TODO: $date، $percent بالمئة، $fardState';
  }

  @override
  String dashboardHeatmapCellA11y(String date, int percent, String fardState) {
    return 'TODO: $date، $percent بالمئة مكتمل، $fardState';
  }

  @override
  String dashboardCategoryA11y(String category, int percent) {
    return 'TODO: $category: $percent بالمئة مكتمل';
  }

  @override
  String historyStripCellA11y(String date, int percent, String fardState) {
    return 'TODO: $date، $percent بالمئة مكتمل، $fardState';
  }

  @override
  String get historyStripFardComplete => 'TODO: الفرائض مكتملة';

  @override
  String get historyStripFardIncomplete => 'TODO: الفرائض غير مكتملة';

  @override
  String streakCurrentLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      one: 'يوم',
    );
    return 'TODO: الحالي: $count $_temp0';
  }

  @override
  String get streakCurrentEmpty => 'TODO: ابدأ سلسلتك اليوم';

  @override
  String streakLongestLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      one: 'يوم',
    );
    return 'TODO: الأطول: $count $_temp0';
  }

  @override
  String streakLongestWindowQualifier(int days) {
    return 'TODO: (آخر $days يومًا)';
  }

  @override
  String get authSignInTitle => 'تسجيل الدخول';

  @override
  String get authSignUpTitle => 'إنشاء حساب';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authEmailInvalid => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authPasswordTooShort => 'استخدم 8 أحرف على الأقل';

  @override
  String get authConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get authPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authFullNameLabel => 'الاسم الكامل';

  @override
  String get authFullNameInvalid => 'يجب أن يكون الاسم حرفين على الأقل';

  @override
  String get authNoAccountPrompt => 'جديد هنا؟ أنشئ حسابًا';

  @override
  String get authHaveAccountPrompt => 'لديك حساب؟ سجّل الدخول';

  @override
  String get authConfirmEmailTitle => 'أكّد بريدك الإلكتروني';

  @override
  String authConfirmEmailBody(String email) {
    return 'أرسلنا رابطًا إلى $email. افتحه ثم عد هنا.';
  }

  @override
  String get authResendConfirmation => 'إعادة إرسال البريد';

  @override
  String get authResendSent => 'إن وُجد حساب، أُرسل بريد جديد.';

  @override
  String get authCheckAgain => 'أكّدت — تحقق مرة أخرى';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authSignOutConfirm => 'تسجيل الخروج؟ تبقى بياناتك على هذا الجهاز.';

  @override
  String get authSignOutCancel => 'البقاء مسجّلًا';

  @override
  String syncHistorySnack(int days) {
    return 'تمت مزامنة $days يومًا من السجل.';
  }

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileSave => 'حفظ';

  @override
  String get profilePhotoUrlLabel => 'رابط الصورة (اختياري)';

  @override
  String get profileTimezoneLabel => 'المنطقة الزمنية (اختياري)';

  @override
  String get profileLocaleLabel => 'اللغة';

  @override
  String get profileLocaleEn => 'English';

  @override
  String get profileLocaleAr => 'العربية';

  @override
  String get profileBioLabel => 'نبذة (اختياري)';

  @override
  String get settingsAccountTitle => 'الحساب';

  @override
  String get settingsSyncNow => 'مزامنة الآن';

  @override
  String get settingsSyncDone => 'اكتملت المزامنة.';
}
