/// Single source of truth for seeded templates (mirrors api/src/challenges/seed-templates.ts).
class ChallengeTemplateSeed {
  const ChallengeTemplateSeed({
    required this.code,
    required this.defaultTitle,
    required this.defaultIcon,
    required this.sourceKind,
    required this.sourceRef,
    required this.goalCount,
    required this.defaultSortOrder,
  });

  final String code;
  final String defaultTitle;
  final String defaultIcon;
  final String sourceKind;
  final String sourceRef;
  final int goalCount;
  final int defaultSortOrder;
}

const kSeededChallengeTemplates = <ChallengeTemplateSeed>[
  ChallengeTemplateSeed(
    code: 'fajr_in_jamaah',
    defaultTitle: 'Pray every Fajr in congregation',
    defaultIcon: 'groups',
    sourceKind: 'TASK_WEEKLY_COUNT',
    sourceRef: 'fajr_first_congregation',
    goalCount: 7,
    defaultSortOrder: 0,
  ),
  ChallengeTemplateSeed(
    code: 'qiyam_witr_all_week',
    defaultTitle: 'Pray Witr every night',
    defaultIcon: 'nights_stay',
    sourceKind: 'TASK_WEEKLY_COUNT',
    sourceRef: 'qiyam_witr',
    goalCount: 7,
    defaultSortOrder: 1,
  ),
  ChallengeTemplateSeed(
    code: 'read_quran_daily',
    defaultTitle: "Read Qur'an every day",
    defaultIcon: 'menu_book',
    sourceKind: 'TASK_WEEKLY_COUNT',
    sourceRef: 'quran_read_six_quarters',
    goalCount: 7,
    defaultSortOrder: 2,
  ),
  ChallengeTemplateSeed(
    code: 'tahajjud_three_nights',
    defaultTitle: 'Stand for Tahajjud three nights',
    defaultIcon: 'bedtime',
    sourceKind: 'TASK_WEEKLY_COUNT',
    sourceRef: 'qiyam_two_rakahs',
    goalCount: 3,
    defaultSortOrder: 3,
  ),
  ChallengeTemplateSeed(
    code: 'fajr_category_all_week',
    defaultTitle: 'Complete the Fajr block every day',
    defaultIcon: 'wb_twilight',
    sourceKind: 'CATEGORY_WEEKLY_COUNT',
    sourceRef: 'fajr',
    goalCount: 7,
    defaultSortOrder: 4,
  ),
  ChallengeTemplateSeed(
    code: 'morning_adhkar_daily',
    defaultTitle: 'Morning Adhkar every morning',
    defaultIcon: 'wb_sunny',
    sourceKind: 'TASK_WEEKLY_COUNT',
    sourceRef: 'fajr_morning_adhkar',
    goalCount: 7,
    defaultSortOrder: 5,
  ),
];
