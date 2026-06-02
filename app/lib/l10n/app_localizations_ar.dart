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
  String get taskStateChecked => 'مُحدَّد';

  @override
  String get taskStateUnchecked => 'غير مُحدَّد';

  @override
  String get taskToggleFailed =>
      'تعذّر تحديث هذه المهمة. يُرجى المحاولة مرة أخرى.';

  @override
  String taskRowSemanticLabel(String title, int points, String state) {
    return '$title، $points نقطة، $state';
  }

  @override
  String get languageToggleTooltip => 'تبديل اللغة (العربية، الإنجليزية)';

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
  String get taskFajrSunnahBeforeFajr => 'سنة الفجر القبلية';

  @override
  String get taskFajrFirstCongregation => 'الصلاة في الجماعة الأولى';

  @override
  String get taskFajrPostPrayerAdhkar => 'أذكار ما بعد الصلاة';

  @override
  String get taskFajrMorningAdhkar => 'أذكار الصباح';

  @override
  String get taskFajrDuhaPrayer4Rakahs => 'صلاة الضحى — 4 ركعات';

  @override
  String get taskDhuhrSunnahBefore4Rakahs => 'سنة الظهر القبلية — 4 ركعات';

  @override
  String get taskDhuhrFirstCongregation => 'الصلاة في الجماعة الأولى';

  @override
  String get taskDhuhrPostPrayerAdhkar => 'أذكار ما بعد الصلاة';

  @override
  String get taskDhuhrSunnahAfter => 'سنة الظهر البعدية';

  @override
  String get taskAsrFirstCongregation => 'الصلاة في الجماعة الأولى';

  @override
  String get taskAsrPostPrayerAdhkar => 'أذكار ما بعد الصلاة';

  @override
  String get taskAsrEveningAdhkar => 'أذكار المساء';

  @override
  String get taskMaghribFirstCongregation => 'الصلاة في الجماعة الأولى';

  @override
  String get taskMaghribPostPrayerAdhkar => 'أذكار ما بعد الصلاة';

  @override
  String get taskMaghribSunnahAfter => 'سنة المغرب البعدية';

  @override
  String get taskIshaFirstCongregation => 'الصلاة في الجماعة الأولى';

  @override
  String get taskIshaPostPrayerAdhkar => 'أذكار ما بعد الصلاة';

  @override
  String get taskIshaSunnahAfter => 'سنة العشاء البعدية';

  @override
  String get taskQiyamTwoRakahs => 'ركعتان من قيام الليل';

  @override
  String get taskQiyamDailyQuranTwoQuarters => 'وِرد القرآن اليومي — ربعان';

  @override
  String get taskQiyamWitr => 'صلاة الوتر';

  @override
  String get taskQiyamAdhkarBeforeSleep => 'أذكار النوم';

  @override
  String get taskQuranMemorizeHalfPage => 'حفظ نصف صفحة';

  @override
  String get taskQuranReadSixQuarters => 'قراءة ستة أرباع (حوالي 1.5 جزء)';

  @override
  String get taskQuranFastingMonThu => 'صيام الاثنين والخميس';

  @override
  String get taskMiscRestroomAdhkar => 'أذكار دخول الخلاء والخروج منه';

  @override
  String get taskMiscClothingAdhkar => 'أذكار لُبس الثوب وخلعه';

  @override
  String get taskMiscWuduAdhkar => 'أذكار الوضوء';

  @override
  String get taskMiscHouseAdhkar => 'أذكار دخول البيت والخروج منه';

  @override
  String get taskMiscMosqueAdhkar => 'أذكار دخول المسجد والخروج منه';

  @override
  String get taskMiscWalkingMosqueAdhkar => 'أذكار المشي إلى المسجد';

  @override
  String get taskMiscEatingDrinkingAdhkar => 'أذكار الطعام والشراب';

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
  String get resetTodayDialogTitle => 'إعادة تعيين تقدّم اليوم؟';

  @override
  String get resetTodayDialogBody =>
      'سيُلغى تحديد كل المهام لهذا اليوم. الأيام السابقة لن تتأثّر.';

  @override
  String get resetTodayDialogCancel => 'إلغاء';

  @override
  String get resetTodayDialogConfirm => 'إعادة تعيين';

  @override
  String get loadingChecklist => 'جارٍ تحميل قائمتك…';

  @override
  String get navChecklistLabel => 'قائمة المهام';

  @override
  String get navDashboardLabel => 'لوحة المعلومات';

  @override
  String get navSettingsLabel => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsNotificationsTitle => 'الإشعارات';

  @override
  String get settingsEodToggleLabel => 'ملخّص نهاية اليوم';

  @override
  String settingsEodTimeLabel(String time) {
    return 'عند $time';
  }

  @override
  String get settingsEodThresholdNote => 'يظهر عند انخفاض إنجاز اليوم عن 50٪.';

  @override
  String get settingsWebNotificationNote =>
      'تتطلّب الإشعارات إبقاء نافذة التطبيق مفتوحة.';

  @override
  String get settingsAboutTitle => 'حول التطبيق';

  @override
  String settingsVersionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String get onboardingNotifTitle => 'حافظ على انتظامك';

  @override
  String get onboardingNotifBody =>
      'اسمح بتذكير لطيف في نهاية اليوم عندما يكون إنجازك أقل من 50٪. يمكنك اختيار الوقت من الإعدادات.';

  @override
  String get onboardingNotifEnableButton => 'تفعيل الإشعارات';

  @override
  String get onboardingNotifSkipButton => 'ليس الآن';

  @override
  String notifEodBody(int percent) {
    return 'أنجزت $percent٪ من مهام اليوم. دقائق من الذكر قد تُغيّر يومك.';
  }

  @override
  String get dashboardTitle => 'لوحة المعلومات';

  @override
  String get dashboardRangeWeek => 'أسبوع';

  @override
  String get dashboardRangeMonth => 'شهر';

  @override
  String get dashboardRange90 => '90 يومًا';

  @override
  String get dashboardWeeklyBarsTitle => 'الإنجاز اليومي';

  @override
  String get dashboardHeatmapTitle => 'خريطة النشاط';

  @override
  String get dashboardCategoriesTitle => 'حسب الفئة';

  @override
  String get dashboardEmptyTitle => 'لا توجد بيانات بعد';

  @override
  String get dashboardEmptyBody =>
      'أكمِل مهمة من قائمة المهام لتظهر إحصائياتك هنا.';

  @override
  String get dashboardEmptyCtaLabel => 'فتح قائمة المهام';

  @override
  String get dashboardErrorLabel => 'حدث خطأ أثناء تحميل هذا العرض.';

  @override
  String get dashboardRetryLabel => 'إعادة المحاولة';

  @override
  String get categoryChartTypeBarsTooltip => 'أعمدة';

  @override
  String get categoryChartTypeRadarTooltip => 'رادار';

  @override
  String get categoryChartTypeStackedTooltip => 'مُكدَّسة';

  @override
  String get categoryChartTypeDonutTooltip => 'حلقي';

  @override
  String get categoryNameFajr => 'الفجر';

  @override
  String get categoryNameDhuhr => 'الظهر';

  @override
  String get categoryNameAsr => 'العصر';

  @override
  String get categoryNameMaghrib => 'المغرب';

  @override
  String get categoryNameIsha => 'العشاء';

  @override
  String get categoryNameQiyamEvening => 'قيام الليل والمساء';

  @override
  String get categoryNameQuranFasting => 'القرآن والصيام';

  @override
  String get categoryNameMiscAdhkar => 'الأذكار';

  @override
  String dashboardBarA11y(String date, int percent, String fardState) {
    return '$date، $percent بالمئة، $fardState';
  }

  @override
  String dashboardHeatmapCellA11y(String date, int percent, String fardState) {
    return '$date، $percent بالمئة مكتملة، $fardState';
  }

  @override
  String dashboardCategoryA11y(String category, int percent) {
    return '$category: $percent بالمئة مكتملة';
  }

  @override
  String historyStripCellA11y(String date, int percent, String fardState) {
    return '$date، $percent بالمئة مكتملة، $fardState';
  }

  @override
  String get historyStripFardComplete => 'الفرائض مكتملة';

  @override
  String get historyStripFardIncomplete => 'الفرائض غير مكتملة';

  @override
  String streakCurrentLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يومان',
      one: 'يوم',
    );
    return 'الحالي: $count $_temp0';
  }

  @override
  String get streakCurrentEmpty => 'ابدأ سلسلتك اليوم';

  @override
  String streakLongestLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يومان',
      one: 'يوم',
    );
    return 'الأطول: $count $_temp0';
  }

  @override
  String streakLongestWindowQualifier(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return '(خلال آخر $days $_temp0)';
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
  String get authFullNameInvalid => 'يجب ألّا يقل الاسم عن حرفين';

  @override
  String get authNoAccountPrompt => 'جديد هنا؟ أنشئ حسابًا';

  @override
  String get authHaveAccountPrompt => 'لديك حساب؟ سجّل الدخول';

  @override
  String get authConfirmEmailTitle => 'أكّد بريدك الإلكتروني';

  @override
  String authConfirmEmailCodeBody(String email) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $email. أدخله أدناه.';
  }

  @override
  String get authConfirmationCodeLabel => 'رمز التأكيد';

  @override
  String get authConfirmCodeButton => 'تأكيد البريد';

  @override
  String get authCodeInvalid =>
      'أدخل الرمز المكوّن من 6 أرقام المُرسَل إلى بريدك';

  @override
  String get authEmailConfirmedSignIn =>
      'تم تأكيد البريد. يمكنك تسجيل الدخول الآن.';

  @override
  String get authResendConfirmation => 'إعادة إرسال الرمز';

  @override
  String get authResendSent => 'إن وُجد حساب بهذا البريد، فقد أُرسل رمز جديد.';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authSignOutConfirm => 'تسجيل الخروج؟ تبقى بياناتك على هذا الجهاز.';

  @override
  String get authSignOutCancel => 'البقاء مسجَّلًا';

  @override
  String syncHistorySnack(int days) {
    return 'تمت مزامنة $days يومًا من السجل.';
  }

  @override
  String get syncLoadingMessage => 'جارٍ مزامنة بياناتك…';

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

  @override
  String get manageChecklistTitle => 'إدارة القائمة';

  @override
  String get manageChecklistMenu => 'إدارة القائمة';

  @override
  String get manageChecklistCategoriesTab => 'الفئات';

  @override
  String get manageChecklistTasksTab => 'المهام';

  @override
  String get manageChecklistAddCategory => 'إضافة فئة';

  @override
  String get manageChecklistAddTask => 'إضافة مهمة';

  @override
  String get manageChecklistEditCategory => 'تعديل الفئة';

  @override
  String get manageChecklistEditTask => 'تعديل المهمة';

  @override
  String get manageChecklistNameLabel => 'الاسم';

  @override
  String get manageChecklistCategoryLabel => 'الفئة';

  @override
  String get manageChecklistSave => 'حفظ';

  @override
  String get manageChecklistCancel => 'إلغاء';

  @override
  String get manageChecklistHide => 'إخفاء';

  @override
  String get manageChecklistFardHideTitle => 'إخفاء هذه المهمة؟';

  @override
  String get manageChecklistFardHideBody =>
      'هذه فريضة. الإخفاء يُزيلها من عدّك اليومي، لا من يومك.';

  @override
  String get manageChecklistRemovePermanently => 'إزالة نهائية';

  @override
  String get manageChecklistRemoveConfirmBody =>
      'سيُزال هذا العنصر ولا يمكن التراجع. يبقى تقدّمك اليومي في المهام الأخرى.';

  @override
  String get manageChecklistRemoveHasHistory =>
      'لهذا العنصر سجل. يمكنك إخفاؤه بدل الإزالة للاحتفاظ بسجلك.';

  @override
  String get manageChecklistTooltipHide =>
      'إخفاء من قائمة اليوم — مع الاحتفاظ بالسجل.';

  @override
  String get manageChecklistTooltipShow => 'إظهار في قائمة اليوم.';

  @override
  String get restoreCatalogDialogTitle => 'استعادة قائمتك المحفوظة؟';

  @override
  String get restoreCatalogDialogBody =>
      'وجدنا قائمتك المحفوظة على هذا الحساب. ستحلّ الاستعادة محلّ التخصيصات على هذا الجهاز — مع الاحتفاظ بتقدّمك اليومي في المهام الافتراضية.';

  @override
  String get restoreCatalogDialogRestore => 'استعادة';

  @override
  String get settingsRestoreCatalogTitle => 'استعادة القائمة من حسابك';

  @override
  String get settingsRestoreCatalogNever => 'لم تُستعَد على هذا الجهاز بعد';

  @override
  String settingsRestoreCatalogLast(String when) {
    return 'آخر استعادة: $when';
  }

  @override
  String get settingsRestoreCatalogOffline =>
      'أنت غير متصل — ستُنفَّذ الاستعادة عند عودة الاتصال.';

  @override
  String get restoreCatalogPushing => 'جارٍ حفظ قائمتك على حسابك…';

  @override
  String get restoreCatalogRestoring => 'جارٍ استعادة قائمتك المحفوظة…';

  @override
  String restoreCatalogDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عنصر',
      many: 'عنصرًا',
      few: 'عناصر',
      two: 'عنصرين',
      one: 'عنصر',
    );
    return 'تمت استعادة $count $_temp0 من حسابك.';
  }

  @override
  String get restoreCatalogSaved => 'تم حفظ قائمتك على حسابك.';

  @override
  String get restoreUnifiedDialogTitle => 'استعادة بياناتك المحفوظة؟';

  @override
  String get restoreUnifiedDialogBody =>
      'وجدنا قائمتك وتحدياتك المحفوظة على هذا الحساب. ستحلّ الاستعادة محلّ ما على هذا الجهاز — مع الاحتفاظ بتقدّمك اليومي في المهام الافتراضية.';

  @override
  String get restoreChallengesDialogTitle => 'استعادة تحدياتك المحفوظة؟';

  @override
  String get restoreChallengesDialogBody =>
      'وجدنا تحدياتك الأسبوعية المحفوظة على هذا الحساب. ستحلّ الاستعادة محلّ التحديات على هذا الجهاز.';

  @override
  String get challengeStartThisWeek => 'هذا الأسبوع: ابدأ تحديًا';

  @override
  String get challengeBrowseTemplatesCta => 'استكشاف القوالب';

  @override
  String get challengesThisWeekTab => 'هذا الأسبوع';

  @override
  String get challengesBrowseTab => 'استكشاف';

  @override
  String get challengeSubscribe => 'اشتراك';

  @override
  String get challengeSubscribed => 'مشترك';

  @override
  String challengeProgress(int achieved, int goal) {
    return '$achieved / $goal';
  }

  @override
  String get challengeCreateCustom => 'إنشاء تحدي مخصص';

  @override
  String get challengeCustomTitleLabel => 'العنوان';

  @override
  String get challengeCustomIconLabel => 'الأيقونة';

  @override
  String get challengeCustomSourceLabel => 'المصدر';

  @override
  String get challengeSourceTabTask => 'مهمة';

  @override
  String get challengeSourceTabCategory => 'فئة';

  @override
  String challengeGoalDaysLabel(int days) {
    return 'الهدف: $days أيام هذا الأسبوع';
  }

  @override
  String get challengeCustomCreate => 'إنشاء';

  @override
  String get challengeWeekStartTitle => 'بداية الأسبوع';

  @override
  String get challengeWeekStartSubtitle => 'يُطبَّق من الأسبوع القادم.';

  @override
  String get challengeWeekStartSaturday => 'السبت';

  @override
  String get challengeWeekStartSunday => 'الأحد';

  @override
  String get challengeWeekStartMonday => 'الاثنين';

  @override
  String challengeWeekStartSnackbar(String weekday) {
    return 'أسبوعك الجديد يبدأ $weekday.';
  }

  @override
  String get challengeCelebrationTitle => 'ما شاء الله';

  @override
  String challengeCelebrationBody(String title, int goal) {
    return '$title — $goal من $goal أيام هذا الأسبوع.';
  }

  @override
  String get challengeContinue => 'متابعة';

  @override
  String get challengeViewChallenge => 'عرض التحدي';

  @override
  String get challengeCompletedThisWeek => 'أُنجز هذا الأسبوع';

  @override
  String get challengeTemplateFajrInJamaah => 'صلِّ كل فجرٍ جماعة';

  @override
  String get challengeTemplateQiyamWitrAllWeek => 'صلِّ الوتر كل ليلة';

  @override
  String get challengeTemplateReadQuranDaily => 'اقرأ القرآن كل يوم';

  @override
  String get challengeTemplateTahajjudThreeNights => 'قُم للتهجد ثلاث ليالٍ';

  @override
  String get challengeTemplateFajrCategoryAllWeek => 'أكمل بلوك الفجر كل يوم';

  @override
  String get challengeTemplateMorningAdhkarDaily => 'أذكار الصباح كل صباح';
}
