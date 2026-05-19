export const FARD_CATEGORY_CODES = new Set([
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
]);

export function isFardCategoryCode(code: string): boolean {
  return FARD_CATEGORY_CODES.has(code);
}
