/** Default category codes — mirrors api/prisma/seed-data.ts */
const STATIC_CATEGORY_CODES = [
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
  'qiyamEvening',
  'quranFasting',
  'miscAdhkar',
] as const;

/** Default task ids — mirrors api/prisma/seed-data.ts */
const STATIC_TASK_IDS = [
  'fajr_waking_up_adhkar',
  'fajr_sunnah_before_fajr',
  'fajr_first_congregation',
  'fajr_post_prayer_adhkar',
  'fajr_morning_adhkar',
  'fajr_duha_4_rakahs',
  'dhuhr_sunnah_before_4_rakahs',
  'dhuhr_first_congregation',
  'dhuhr_post_prayer_adhkar',
  'dhuhr_sunnah_after',
  'asr_first_congregation',
  'asr_post_prayer_adhkar',
  'asr_evening_adhkar',
  'maghrib_first_congregation',
  'maghrib_post_prayer_adhkar',
  'maghrib_sunnah_after',
  'isha_first_congregation',
  'isha_post_prayer_adhkar',
  'isha_sunnah_after',
  'qiyam_two_rakahs',
  'qiyam_daily_quran_two_quarters',
  'qiyam_witr',
  'qiyam_adhkar_before_sleep',
  'quran_memorize_half_page',
  'quran_read_six_quarters',
  'quran_fasting_mon_thu',
  'misc_restroom_adhkar',
  'misc_clothing_adhkar',
  'misc_wudu_adhkar',
  'misc_house_adhkar',
  'misc_mosque_adhkar',
  'misc_walking_mosque_adhkar',
  'misc_eating_drinking_adhkar',
  'misc_riding_traveling_adhkar',
] as const;

export const DEFAULT_CATEGORY_CODES = new Set<string>(STATIC_CATEGORY_CODES);
export const DEFAULT_TASK_IDS = new Set<string>(STATIC_TASK_IDS);

export function isDefaultCategoryRef(ref: string): boolean {
  return DEFAULT_CATEGORY_CODES.has(ref);
}

export function isDefaultTaskRef(ref: string): boolean {
  return DEFAULT_TASK_IDS.has(ref);
}

export function isValidDefaultSourceRef(
  sourceKind: string,
  sourceRef: string,
): boolean {
  if (sourceKind === 'TASK_WEEKLY_COUNT') {
    return isDefaultTaskRef(sourceRef);
  }
  if (sourceKind === 'CATEGORY_WEEKLY_COUNT') {
    return isDefaultCategoryRef(sourceRef);
  }
  return false;
}
