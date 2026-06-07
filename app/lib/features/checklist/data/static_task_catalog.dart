import '../domain/fard_anchor_set.dart';
import '../domain/task.dart';

/// Hard-coded catalog from `specs/2026-05-12-static-daily-checklist/requirements.md` §3.1.
/// Order: Fajr → Dhuhr → Asr → Maghrib → Isha → Qiyam & Evening → Quran & Fasting → Misc.
final List<Task> staticTaskCatalog = <Task>[
  Task(
    id: 'fajr_waking_up_adhkar',
    points: 2,
    category: TaskCategory.fajr,
    titleResolver: (l) => l.taskFajrWakingUpAdhkar,
  ),
  Task(
    id: 'fajr_sunnah_before_fajr',
    points: 2,
    category: TaskCategory.fajr,
    titleResolver: (l) => l.taskFajrSunnahBeforeFajr,
  ),
  Task(
    id: 'fajr_first_congregation',
    points: 2,
    category: TaskCategory.fajr,
    titleResolver: (l) => l.taskFajrFirstCongregation,
  ),
  Task(
    id: 'fajr_post_prayer_adhkar',
    points: 2,
    category: TaskCategory.fajr,
    titleResolver: (l) => l.taskFajrPostPrayerAdhkar,
  ),
  Task(
    id: 'fajr_morning_adhkar',
    points: 2,
    category: TaskCategory.fajr,
    titleResolver: (l) => l.taskFajrMorningAdhkar,
  ),
  Task(
    id: 'fajr_duha_4_rakahs',
    points: 2,
    category: TaskCategory.fajr,
    titleResolver: (l) => l.taskFajrDuhaPrayer4Rakahs,
  ),
  Task(
    id: 'dhuhr_sunnah_before_4_rakahs',
    points: 2,
    category: TaskCategory.dhuhr,
    titleResolver: (l) => l.taskDhuhrSunnahBefore4Rakahs,
  ),
  Task(
    id: 'dhuhr_first_congregation',
    points: 2,
    category: TaskCategory.dhuhr,
    titleResolver: (l) => l.taskDhuhrFirstCongregation,
  ),
  Task(
    id: 'dhuhr_post_prayer_adhkar',
    points: 2,
    category: TaskCategory.dhuhr,
    titleResolver: (l) => l.taskDhuhrPostPrayerAdhkar,
  ),
  Task(
    id: 'dhuhr_sunnah_after',
    points: 2,
    category: TaskCategory.dhuhr,
    titleResolver: (l) => l.taskDhuhrSunnahAfter,
  ),
  Task(
    id: 'asr_first_congregation',
    points: 2,
    category: TaskCategory.asr,
    titleResolver: (l) => l.taskAsrFirstCongregation,
  ),
  Task(
    id: 'asr_post_prayer_adhkar',
    points: 2,
    category: TaskCategory.asr,
    titleResolver: (l) => l.taskAsrPostPrayerAdhkar,
  ),
  Task(
    id: 'asr_evening_adhkar',
    points: 2,
    category: TaskCategory.asr,
    titleResolver: (l) => l.taskAsrEveningAdhkar,
  ),
  Task(
    id: 'maghrib_first_congregation',
    points: 2,
    category: TaskCategory.maghrib,
    titleResolver: (l) => l.taskMaghribFirstCongregation,
  ),
  Task(
    id: 'maghrib_post_prayer_adhkar',
    points: 2,
    category: TaskCategory.maghrib,
    titleResolver: (l) => l.taskMaghribPostPrayerAdhkar,
  ),
  Task(
    id: 'maghrib_sunnah_after',
    points: 2,
    category: TaskCategory.maghrib,
    titleResolver: (l) => l.taskMaghribSunnahAfter,
  ),
  Task(
    id: 'isha_first_congregation',
    points: 2,
    category: TaskCategory.isha,
    titleResolver: (l) => l.taskIshaFirstCongregation,
  ),
  Task(
    id: 'isha_post_prayer_adhkar',
    points: 2,
    category: TaskCategory.isha,
    titleResolver: (l) => l.taskIshaPostPrayerAdhkar,
  ),
  Task(
    id: 'isha_sunnah_after',
    points: 2,
    category: TaskCategory.isha,
    titleResolver: (l) => l.taskIshaSunnahAfter,
  ),
  Task(
    id: 'qiyam_two_rakahs',
    points: 4,
    category: TaskCategory.qiyamEvening,
    titleResolver: (l) => l.taskQiyamTwoRakahs,
  ),
  Task(
    id: 'qiyam_daily_quran_two_quarters',
    points: 4,
    category: TaskCategory.qiyamEvening,
    titleResolver: (l) => l.taskQiyamDailyQuranTwoQuarters,
  ),
  Task(
    id: 'qiyam_witr',
    points: 1,
    category: TaskCategory.qiyamEvening,
    titleResolver: (l) => l.taskQiyamWitr,
  ),
  Task(
    id: 'quran_memorize_half_page',
    points: 2,
    category: TaskCategory.quranFasting,
    titleResolver: (l) => l.taskQuranMemorizeHalfPage,
  ),
  Task(
    id: 'quran_read_six_quarters',
    points: 2,
    category: TaskCategory.quranFasting,
    titleResolver: (l) => l.taskQuranReadSixQuarters,
  ),
  Task(
    id: 'misc_restroom_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscRestroomAdhkar,
  ),
  Task(
    id: 'misc_clothing_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscClothingAdhkar,
  ),
  Task(
    id: 'misc_wudu_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscWuduAdhkar,
  ),
  Task(
    id: 'misc_house_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscHouseAdhkar,
  ),
  Task(
    id: 'misc_mosque_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscMosqueAdhkar,
  ),
  Task(
    id: 'misc_walking_mosque_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscWalkingMosqueAdhkar,
  ),
  Task(
    id: 'misc_eating_drinking_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscEatingDrinkingAdhkar,
  ),
  Task(
    id: 'misc_riding_traveling_adhkar',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskMiscRidingTravelingAdhkar,
  ),
  Task(
    id: 'qiyam_adhkar_before_sleep',
    points: 2,
    category: TaskCategory.miscAdhkar,
    titleResolver: (l) => l.taskQiyamAdhkarBeforeSleep,
  ),
];

/// Debug-only invariant: every id in [fardAnchorTaskIds] exists in the
/// catalog, and the anchor set's catalog-points sum equals
/// [fardAnchorPointsTotal]. Called from `AppDatabase.seedAndReconcile`.
void assertFardAnchorIntegrity() {
  assert(() {
    final ids = staticTaskCatalog.map((t) => t.id).toSet();
    for (final fardId in fardAnchorTaskIds) {
      if (!ids.contains(fardId)) {
        throw StateError(
          'fardAnchorTaskIds contains "$fardId" but the static catalog '
          'has no task with that id.',
        );
      }
    }
    final pts = staticTaskCatalog
        .where((t) => fardAnchorTaskIds.contains(t.id))
        .fold<int>(0, (s, t) => s + t.points);
    if (pts != fardAnchorPointsTotal) {
      throw StateError(
        'Fard anchor points drifted: got $pts, expected '
        '$fardAnchorPointsTotal.',
      );
    }
    return true;
  }());
}
