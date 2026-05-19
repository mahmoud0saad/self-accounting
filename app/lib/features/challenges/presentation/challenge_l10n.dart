import 'package:app/l10n/app_localizations.dart';

import '../domain/challenge_models.dart';

String challengeDisplayTitle(AppLocalizations l, UserChallenge c) {
  return switch (c.templateCode) {
    'fajr_in_jamaah' => l.challengeTemplateFajrInJamaah,
    'qiyam_witr_all_week' => l.challengeTemplateQiyamWitrAllWeek,
    'read_quran_daily' => l.challengeTemplateReadQuranDaily,
    'tahajjud_three_nights' => l.challengeTemplateTahajjudThreeNights,
    'fajr_category_all_week' => l.challengeTemplateFajrCategoryAllWeek,
    'morning_adhkar_daily' => l.challengeTemplateMorningAdhkarDaily,
    _ => c.displayTitleFallback,
  };
}
