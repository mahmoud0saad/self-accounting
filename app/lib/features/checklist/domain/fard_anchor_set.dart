/// The catalog-grounded mapping of "all fard tasks" used as the streak anchor.
///
/// Streak day = every id in this set is checked on the given calendar day.
/// See `specs/phase-3-2026-05-13-history-and-streaks/requirements.md` §3.1 / D1.
/// `quran_read_six_quarters` stands in for "Fajr/Asr Quran" — the closest
/// catalog item for the daily Qur'an portion (Wird). Phase 7 is the right
/// place to introduce an `is_fard` column on `tasks` and migrate this constant
/// to a query.
const Set<String> fardAnchorTaskIds = <String>{
  'fajr_first_congregation',
  'dhuhr_first_congregation',
  'asr_first_congregation',
  'maghrib_first_congregation',
  'isha_first_congregation',
  'quran_read_six_quarters',
};

/// Catalog-points total across [fardAnchorTaskIds]. Each of the six anchor
/// tasks is worth 2 points in the static catalog → 12.
const int fardAnchorPointsTotal = 12;
