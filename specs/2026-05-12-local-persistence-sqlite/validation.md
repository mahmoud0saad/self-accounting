# Phase 2 — Local Persistence with SQLite · Validation

> This phase merges when **every** check below passes. The bulk are manual; one mandatory unit test (V31) is the only automated gate, intentionally narrow per D15 / R8.

## 1. Roadmap exit criteria

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V1 | `tasks` table is added to the SQLite schema | Inspect `app/lib/core/db/tables/tasks_table.dart` + `app_database.dart` | Table is declared with columns `id, points, category, sort_order`, PK on `id`; included in `@DriftDatabase(tables: [...])` |
| V2 | `daily_logs` table is added | Inspect `app/lib/core/db/tables/daily_logs_table.dart` | Table is declared with columns `date, task_id, completed, updated_at`; composite PK `(date, task_id)`; FK `task_id → tasks.id`; included in `@DriftDatabase(tables: [...])` |
| V3 | Default tasks are seeded on first launch | Wipe the app's local storage (uninstall on mobile / clear site data on Web), then `flutter run`. Use Drift DevTools or a debug log to inspect the `tasks` table after the first frame. | `tasks` contains exactly the 34 rows from `staticTaskCatalog` with point values matching `requirements.md` §3.1; `SUM(points) = 74` |
| V4 | Closing/reopening the app preserves today's progress | Tick any 5 tasks. Force-quit / close the tab. Relaunch. | All 5 tasks remain ticked; header percentage matches the pre-close value |
| V5 | Switching days shows correct historical state | Tick a unique fingerprint of tasks today (e.g. 3 specific tasks across 2 categories). Use a debug `INSERT` via Drift DevTools (or the `resetDay` action across simulated days) to seed yesterday with a different fingerprint. Tap `‹`. | Yesterday's screen renders **only** yesterday's checked tasks; the percentage matches yesterday's distinct fingerprint; tapping `›` returns to today's distinct fingerprint with no bleed |
| V6 | Display auto-resets at local midnight | Set device clock to 23:59:50 with some tasks checked. Wait 30 seconds. | At 00:00 the active day's label switches from `Today` to the next-day `Today`; checkboxes return to unchecked (new day = empty `daily_logs`); tapping `‹` shows the previous day's checked rows intact |
| V7 | Repository layer + Riverpod providers are wired end-to-end | Inspect `app/lib/features/checklist/data/` and `app/lib/features/checklist/presentation/providers/` | `ChecklistRepository` (abstract) + `DriftChecklistRepository` (concrete) exist; `TaskRepository` + `SettingsRepository` exist; the three Phase-1 providers (`taskCatalogProvider`, `checklistStateProvider`, `dailyProgressProvider`) all resolve through repositories, **not** in-memory state |

## 2. Drift wiring & schema

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V8 | Drift codegen output is committed | `git ls-files app/lib/core/db/*.g.dart` | At least `app_database.g.dart` is tracked in git |
| V9 | Foreign keys are enabled at runtime | Inspect `MigrationStrategy.beforeOpen` on `AppDatabase.migration` in `app_database.dart` | `PRAGMA foreign_keys = ON;` is issued via `customStatement` on every open |
| V10 | Schema version is `1` and upgrade path is guarded | Inspect `AppDatabase.migration` | `schemaVersion == 1`; `onUpgrade` throws `StateError` rather than silently no-op'ing |
| V11 | Sanctioned new runtime dependencies only | Diff `app/pubspec.yaml` vs `master` | Exactly five **new** runtime entries: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `path`. Exactly two **new** dev entries: `drift_dev`, `build_runner`. **No** `shared_preferences`, **no** `hive`, **no** other persistence libs |
| V12 | Web SQLite assets are committed and version-pinned | `git ls-files app/web/sqlite3.wasm app/web/drift_worker.js`; check the PR description for SHA-256 sums | Both files are tracked; the PR body includes the matching `drift` version and the SHA-256 of each binary |

## 3. Seed & reconciliation (D7 / R5)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V13 | Seed is idempotent | After first launch (V3), force-quit and relaunch. Inspect `tasks` row count. | Still exactly the 34 catalog rows — no duplicates, no PK conflicts surfaced in logs |
| V14 | Reconciliation upserts on every launch | Temporarily edit `staticTaskCatalog` (in a throwaway diff) to bump `points` on the `qiyam_witr` task (l10n key `taskQiyamWitr`; was 1 → 3). Hot-restart. | Row for `qiyam_witr` in `tasks` now shows `points = 3`. Revert the edit and re-launch — the row reverts to `points = 1` |
| V15 | Orphans are filtered, not deleted | Temporarily *remove* an entry from `staticTaskCatalog` (e.g. `misc_riding_traveling_adhkar`). Hot-restart. | The row remains in `tasks` (no DELETE issued); the row is **not** rendered on the screen (filtered at presentation). Revert the edit. |
| V16 | Static catalog point sum guard fires | In a debug build with an intentional drift (e.g. `points: 1` → `points: 9` on one task in the static catalog), launch the app. | The `assert` in `seedAndReconcile` triggers a clear failure message about the 74-point invariant. Revert the edit before merge. |

## 4. Active day & day picker

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V17 | Active day defaults to today on cold launch | Relaunch the app. | Day picker label reads `Today` (EN) / `اليوم` (AR); the rows are editable |
| V18 | Previous-day navigation works | Tap `‹` from `Today`. | Label changes to `Yesterday`; rows are visibly disabled; tapping a row does **nothing** (no state change, no snackbar) |
| V19 | Next-day arrow is disabled at today | Visual inspection on `Today`. | `›` is greyed and `onPressed: null` (no tap response) |
| V20 | Previous-day arrow is disabled at the history bound | Tap `‹` 30 times. | At day `today - 30`, `‹` becomes disabled; tapping does nothing |
| V21 | Calendar picker honors the bounds | Tap the middle label to open the calendar. | First selectable date is `today - 30`; last selectable date is today; dates outside the window are not selectable |
| V22 | Read-only pill is shown only on past days | Toggle between today and any past day. | Pill is absent on today, present on every past day; uses `AppLocalizations.readOnlyBadge` (so it localizes) |
| V23 | `kMaxHistoryDays = 30` is the **only** number tuning the window | `rg "kMaxHistoryDays" app/lib/` | Single declaration point (`const kMaxHistoryDays` in `checklist_repositories_provider.dart`); other files import it (e.g. `day_picker_bar.dart`); no bare `30` or `Duration(days: 30)` for the history window elsewhere under `app/lib/features/checklist/` |

## 5. Midnight rollover (D12)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V24 | Timer-based rollover (foreground) | With the app open and viewing `Today`, set OS clock to 23:59:55, wait 10 seconds. | At 00:00 the label flips; rows reset (new empty day); no manual interaction needed |
| V25 | Resume-based rollover (background) | With the app open and viewing `Today`, background the app (alt-tab on web, home button on mobile). Advance OS clock to a few minutes past the next midnight. Bring the app to foreground. | Within one frame of resume the active day rebases to the new `Today`; previous day's data is intact under `‹` |
| V26 | Rollover does **not** yank the user off a past day | Tap `‹` to view yesterday. Hold the app open across simulated midnight (advance OS clock). | The active day remains the day the user was viewing; the picker bar's `›` is now active and the historical-today is reachable in one tap |

## 6. Locale persistence (D9 / R9)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V27 | Locale override persists across launches | From an EN system locale, tap the AppBar toggle to AR. Force-quit. Relaunch. | First frame renders Arabic + RTL — no flash of English; the toggle reflects AR |
| V28 | Locale override is stored in `app_settings` | Inspect `app_settings` table via Drift DevTools or a small debug query in dev tools | Row exists with `key = 'app.locale.override'`, `value = 'ar'` |
| V29 | Clearing the override falls back to system locale | Toggle through AR → system (the `null` slot in the cycle). Force-quit. Relaunch with system locale = EN. | App opens in English; `app_settings` row for `app.locale.override` is **deleted** (not stored as the string `"null"`) |
| V30 | No new top-level dep introduced for settings | `rg "shared_preferences" app/pubspec.yaml app/pubspec.lock` | Zero matches |

## 7. The one mandatory automated test (R8 / D15)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V31 | `resetDay` is narrowly scoped | From `/app`: `flutter test test/data/drift_checklist_repository_test.dart` | Test passes: seeded `2026-05-11` and `2026-05-12`, `resetDay(DayKey(year: 2026, month: 5, day: 12))` empties only `2026-05-12`, `2026-05-11`'s 3 rows untouched. The test runs against `NativeDatabase.memory()` |

## 8. Read-only past days

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V32 | Past-day checkboxes are inert | On any past day, tap a row. | No state change in DB (`SELECT * FROM daily_logs WHERE date = '<past>'` is unchanged); no snackbar; no haptic ping |
| V33 | Reset-today is hidden on past days | Navigate to a past day. Long-press the progress header. | Nothing happens; the dialog does **not** appear |
| V34 | Read-only state survives a day change | Pick a past day. Force-quit. Relaunch. | The app opens on Today (the default), **not** the last-viewed past day. (Picker selection is session-only by design; only completions persist.) |

## 9. Reset today (D13)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V35 | Long-press on today opens the confirm dialog | On `Today`, long-press the progress header (≥ 600 ms). | Material `AlertDialog` appears with all four localized strings (title/body/cancel/confirm) |
| V36 | Cancel preserves state | Open the dialog with some tasks checked, tap `Cancel`. | All checks remain; no DB writes occur |
| V37 | Confirm wipes today only | Open the dialog with some tasks checked, tap `Reset`. | Today's rows in `daily_logs` are deleted; **any other day's rows are unchanged** (re-verify V5's previously-seeded yesterday is still intact); header reads `0 / 74 points`; `0%` |
| V38 | Tone is encouraging, not alarming | Read the four strings. | No "danger", "delete", "warning" copy; "Reset" action button uses the Material 3 primary (soft-green) — **no red** |

## 10. UX / visual quality bar (continuity with Phase 1)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V39 | Material 3 + soft-green theme reused | Inspect `app/lib/main.dart` | `useMaterial3: true` and the Phase 0 seed color are **unchanged**; no new theming code in Phase 2 |
| V40 | Day picker arrows mirror correctly in RTL | Switch to Arabic. Visual inspection. | `chevron_left` / `chevron_right` glyphs are mirrored by Material 3; the **logical** previous/next actions stay correct (tapping the "back-in-time" arrow still goes back in time regardless of glyph direction); tooltips read the localized `dayPickerPreviousLabel` / `dayPickerNextLabel` |
| V41 | First-frame skeleton is gentle | Cold-launch on Web (slowest path). | Skeleton state shows the localized `loadingChecklist` string; no jarring "white flash" → "full UI" transition |
| V42 | Accessibility labels updated for read-only rows | Inspect `Semantics` debugger or grep `task_row.dart` | Past-day rows announce the localized read-only context; today's rows announce as toggleable |

## 11. Static analysis & CI

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V43 | `flutter analyze` clean | From `/app`: `flutter analyze` | `No issues found!` |
| V44 | `dart format` clean | From `/app`: `dart format --output=none --set-exit-if-changed .` | Exit code 0 |
| V45 | No hard-coded directional padding/alignment | From `/app`: `rg "EdgeInsets\.only\(left\|right" lib/features/ lib/core/` and `rg "Alignment\.(centerLeft\|centerRight)" lib/features/ lib/core/` | Zero matches outside generated files |
| V46 | `resetDay` WHERE clause is a single equality (R8 defense-in-depth) | Inspect `DriftChecklistRepository.resetDay` in `lib/features/checklist/data/checklist_repository.dart` (optional: `rg "_db\\.dailyLogs" lib/features/checklist/data/checklist_repository.dart`) | Exactly one `delete` on `dailyLogs`, with a single `r.date.equals(day.toIsoDate())` predicate — **no** `isBetweenValues`, `isIn`, or compound conditions |
| V47 | `app-lint` CI job green on the PR | GitHub Actions tab on the PR | Job passes |
| V48 | `api-lint` CI job still green | GitHub Actions tab on the PR | Job passes — Phase 2 must not regress the backend lint |
| V49 | No new workflow needed | Diff `.github/workflows/` | No changes (committed `*.g.dart` + committed web assets keep CI lint-only per D3 / D4) |

## 12. i18n & RTL (continuity with Phase 1)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V50 | New ARB keys are present in both locales | `rg "dayLabelToday\|dayLabelYesterday\|dayPickerPreviousLabel\|dayPickerNextLabel\|readOnlyBadge\|resetTodayDialogTitle\|resetTodayDialogBody\|resetTodayDialogCancel\|resetTodayDialogConfirm\|loadingChecklist" app/l10n/app_en.arb app/l10n/app_ar.arb` | All 10 keys appear in **both** files |
| V51 | English path renders day picker + reset dialog + read-only pill | Run on Chrome in EN | All three render with English strings |
| V52 | Arabic path renders the same | Toggle to Arabic | All three render with Arabic strings; RTL flips correctly per V40 |
| V53 | **All Arabic `TODO:` placeholders filled** (merge-blocking, V36-equivalent) | From `/app`: `rg "TODO:" l10n/app_ar.arb` | **Zero matches.** Non-zero blocks merge per Phase 1 D11's gate, now extended to Phase 2's new keys |

## 13. Spec hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V54 | Decisions D1–D15 are reflected in code | PR diff review | Each decision is observable in code, config, schema, or folder structure |
| V55 | README "Status" line updated | Inspect repo-root `README.md` | Reads `Phase 2 ✅ — local persistence (Drift / SQLite, EN + AR)` |
| V56 | This spec folder is linked from the PR | Inspect PR description | Link to `specs/2026-05-12-local-persistence-sqlite/` is present |
| V57 | Phase 3 hand-off note is recorded | Inspect PR description | Single sentence flagging that R6's deferred test harness should land alongside Phase 3's streak work |

## 14. Definition of Done (merge gate)

The PR is mergeable when:

- [ ] V1 – V7 (roadmap exit criteria) pass on the reviewer's machine.
- [ ] V8 – V12 (Drift wiring & schema) verified by code + asset inspection.
- [ ] V13 – V16 (seed & reconciliation) verified by manual hot-restart tests.
- [ ] V17 – V23 (active day & day picker) verified on the running app.
- [ ] V24 – V26 (midnight rollover) verified by OS-clock manipulation.
- [ ] V27 – V30 (locale persistence) verified on cold restart.
- [ ] **V31 (the one automated test) passes locally and in CI.**
- [ ] V32 – V34 (read-only past days) verified.
- [ ] V35 – V38 (reset today) verified.
- [ ] V39 – V42 (UX / visual quality bar) verified.
- [ ] V43 – V49 (lint + CI) green on the PR; V45 + V46 (RTL + reset-WHERE) grep guards pass.
- [ ] V50 – V52 (i18n & RTL) verified on the running app in both locales.
- [ ] **V53 verified: zero `TODO:` placeholders remain in `app_ar.arb`.** Hard merge-block.
- [ ] V54 – V57 (spec hygiene) confirmed.
- [ ] No new runtime dependencies beyond the five listed in V11 — without an inline justification in the PR description.

When all boxes are checked: **squash-merge to `master`** and proceed to Phase 3 (History & Streaks). The first ticket of Phase 3 should be "land the deferred test harness alongside the new streak repository methods" (R6 hand-off).
