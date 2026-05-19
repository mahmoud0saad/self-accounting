/// Default category codes that cannot be hidden or renamed (Phase 7 §3.2).
const Set<String> fardCategoryCodes = {
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
};

bool isFardCategoryCode(String code) => fardCategoryCodes.contains(code);
