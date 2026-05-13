# Phase 3 — History & Streaks · Validation

> This phase merges when **every** check below passes. Two automated tests (V14, V15) are the mandatory gates; the rest are manual but expected to be verified end-to-end before opening the PR for review.

## 1. Roadmap exit criteria

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V1 | 7-day strip is on the home screen | Launch the app. Inspect the sliver order between `AppBar` and the first category section. | The strip sits as its own `SliverToBoxAdapter` between `DayPickerBar` and `ChecklistProgressHeader`; renders 7 cells horizontally; today is on the logical-end of the row. |
| V2 | Strip is color-coded by completion % | Tick a varying number of tasks across 3 different days (today, yesterday, day -3). | Each cell's background color matches the bin table in `requirements.md` §3.6: `surfaceVariant` for 0%, progressively saturated `primary` at alpha 0.20/0.40/0.65/1.00 for the 1–24 / 25–49 / 50–74 / ≥75 brackets. |
| V3 | Current streak counter is visible and live | Complete all 6 fard anchor tasks today on a clean DB. | Current-streak pill renders `Current: 1 day` (singular). Untick one fard task → pill drops to `Start a streak today` (or `Current: 0` per the empty copy, see V11). Re-tick → pill returns to `Current: 1 day`. |
| V4 | Longest streak counter is visible and live | Complete fard for today and yesterday (use editable-yesterday from V5). | Longest-streak pill renders `Best: 2 days` (plural). |
| V5 | "On this day" navigation lets the user **view and edit** past days within the configured window | Tap a strip cell or use the day picker to navigate to yesterday. | Yesterday's task rows are editable (tap toggles; no read-only pill). Days older than yesterday are read-only (Phase 2 pill shows). |

## 2. Streak math correctness

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V6 | Streak day definition | Inspect `app/lib/features/checklist/domain/fard_anchor_set.dart` | `fardAnchorTaskIds` is exactly `{ fajr_first_congregation, dhuhr_first_congregation, asr_first_congregation, maghrib_first_congregation, isha_first_congregation, quran_read_six_quarters }` — 6 ids, **no extras**. |
| V7 | Grace window: today's pending fard does not break the streak | With a 3-day fard streak ending today, untick **one** fard task today. | Today's strip ring disappears. Current-streak pill remains `Current: 2 days` (anchors to yesterday). Re-ticking → snaps back to `3 days`. |
| V8 | Streak resets when both today and yesterday miss fard | With a 5-day fard streak ending two days ago (i.e., today and yesterday both miss), inspect the pill. | Current-streak pill reads `Start a streak today` (`0`). Longest-streak pill still reads `Best: 5 days`. |
| V9 | Partial completion (≥75%) without full fard is **not** a streak day | Tick all 28 non-fard tasks today (fraction ≈ 0.78 = 58/74) but leave one fard task unticked. | Today's strip cell is bin-4 (saturated green) **without** a tertiary fard ring. Current-streak pill reads `Start a streak today` (assuming no prior streak). |
| V10 | Longest streak honors the 30-day window qualifier | Synthesize 30 consecutive fard-met days (e.g., via Drift DevTools insertion). | Longest-streak pill reads `Best: 30 days (last 30 days)`. Without hitting the cap (e.g., longest run = 12 in the window), the qualifier is **absent**. |
| V11 | Empty-streak copy is mission-aligned | Open the app on a brand-new DB. | Current-streak pill reads exactly `Start a streak today` (no `0`, no `!`, no shaming copy). |

## 3. Editable past-day window

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V12 | `kMaxEditableDays = 2` is the single source of truth | `rg "kMaxEditableDays" app/lib/` | Single declaration in `checklist_repositories_provider.dart`; all guard logic in `ChecklistController.toggle` / `ChecklistController.resetActiveDay` references it. The literal `2` in `task_row.dart` is annotated with a comment linking back to the constant. |
| V13 | Day -2 → -30 stay read-only | From any past day older than yesterday, tap a task row. | No state change in `daily_logs`. The read-only pill is visible on the progress header. Long-press the header → no dialog. |

## 4. Mandatory automated tests

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V14 | `streak_calculator_test.dart` passes | From `/app`: `flutter test test/domain/streak_calculator_test.dart` | All six cases (empty, 3-ending-today, 5-ending-yesterday grace, gap-then-4, 7-not-recent, partial-no-fard) pass. |
| V15 | `drift_history_repository_test.dart` passes | From `/app`: `flutter test test/data/drift_history_repository_test.dart` | `readRange` returns exactly 7 `DayCompletion` rows for a 7-day window; seeded days have correct points + fard flags; unseeded days have `0` / `false`. `watchRange` emits a new list when a new row is inserted. |
| V16 | Phase 2's mandatory test still passes | From `/app`: `flutter test test/data/drift_checklist_repository_test.dart` | Test passes unchanged — Phase 3 must not regress the Phase 2 V31 gate. |

## 5. Strip & cell behavior

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V17 | Strip cell tap navigates the active day | Tap any of the 7 cells. | `activeDayProvider` updates to that day; the cell's fill swaps to `primaryContainer`; the picker bar label updates; the checklist body reloads for that day. |
| V18 | Today's cell has an emphasis ring | Visual inspection of the rightmost cell (LTR) / leftmost cell (RTL) on cold launch. | Today's cell shows either the tertiary fard ring (if all fard tasks done) **or** a thin `outline` ring (if not). Other cells have neither emphasis ring (only the fard ring when applicable). |
| V19 | Fard ring is decoupled from completion bin | Complete only the 6 fard tasks today (fraction ≈ 0.16). | Today's cell is bin-1 (palest green) **with** the tertiary fard ring. The ring is visible even at low saturation. |
| V20 | Strip cell semantics announce date + percent + fard | Enable TalkBack / VoiceOver / desktop screen reader. Focus a strip cell. | Reader speaks the full localized weekday + date, the integer percent, and `"fard complete"` or `"fard not complete"`. |
| V21 | Strip cell hit area is ≥ 44×44 logical px | Inspect via Flutter Inspector or simulated touch on a high-DPI device. | Each cell's tap target (cell + label area) is at least 44 logical px in both dimensions. |

## 6. Midnight rollover (Phase 2 D12 + Phase 3 D15)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V22 | Strip rebases at local midnight while viewing **today** | With the app open on today and at least one fard task ticked, set OS clock to 23:59:50, wait 20 seconds. | At 00:00 the rightmost cell becomes a new "today" (bin 0, empty); the previous day's record slides one slot to the left; the active highlight follows the new today; the streak pill recomputes within one frame. |
| V23 | Strip rebases on resume after a missed midnight | While on today, background the app; advance OS clock to 5 minutes past next midnight; foreground the app. | Strip reflects the new "today" within one frame of resume; no flash of stale data. |
| V24 | Midnight does **not** snap the user off a past day | While viewing day -3 with no edits, advance OS clock across midnight. | `activeDayProvider` remains on the same `DayKey` (now day -4 relative to the new today); strip cells re-render but the user stays on their chosen day. |
| V25 | Yesterday remains editable across midnight | At 23:55 navigate to yesterday with one fard task ticked. Advance clock to 00:05 of the next day. | Yesterday (still calendar day N-1; now `today - 2`) is **no longer** editable — the read-only pill appears; tapping does nothing. The previously checked rows remain in `daily_logs`. *(This is the deliberate "edit window slides at midnight" behavior — document in the PR if a reviewer flags it as surprising.)* |

## 7. Provider plumbing & UI wiring

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V26 | New providers exist with documented contracts | Inspect `app/lib/features/checklist/presentation/providers/` | These files exist: `calendar_today_provider.dart`, `history_repository_provider.dart`, `history_strip_window_provider.dart`, `streak_window_provider.dart`, `streak_provider.dart`. |
| V27 | `historyStripWindowProvider` watches `calendarTodayProvider`, not `activeDayProvider` | Inspect `history_strip_window_provider.dart` | The provider body calls `ref.watch(calendarTodayProvider)` and never references `activeDayProvider`. Navigating to a past day does **not** cause the strip's data to rebase. |
| V28 | `streakProvider` derives from the 30-day window | Inspect `streak_provider.dart` | It reads `streakWindowProvider` (which uses `kMaxHistoryDays`), not `historyStripWindowProvider`. |
| V29 | `ChecklistController.toggle` widens to today + yesterday | Inspect the new guard in `checklist_state_provider.dart` (or wherever it lives) | The guard uses `today.daysSince(day) < kMaxEditableDays` (or equivalent), not `day == DayKey.today()`. |
| V30 | `ChecklistController.resetToday` is renamed / aliased to `resetActiveDay` | `rg "resetActiveDay" app/lib/` | Method exists; targets `activeDay` not hard-coded today. If the old name is kept as an alias, both resolve to the same body. |

## 8. Localization & dependency hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V31 | 7 new ARB keys exist in both locales | `rg '"historyStripCellA11y"|"historyStripFardComplete"|"historyStripFardIncomplete"|"streakCurrentLabel"|"streakCurrentEmpty"|"streakLongestLabel"|"streakLongestWindowQualifier"' app/l10n/` | Exactly 7 matches in `app_en.arb` and 7 in `app_ar.arb`. |
| V32 | Zero pending Arabic placeholders | `rg "TODO:" app/l10n/app_ar.arb` | **Zero** matches. (V19-equivalent of Phase 2's pre-merge gate.) |
| V33 | No new top-level dependency | `git diff master -- app/pubspec.yaml` | Empty diff. (`pubspec.lock` may have minor churn from re-resolution but no new packages.) |
| V34 | Plural keys use ICU correctly | Render the app in EN at `current == 1` and `current == 5`. | UI shows `Current: 1 day` (singular) and `Current: 5 days` (plural). No `1 days` or `5 day` strings appear. |

## 9. Lints, format & RTL guard

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V35 | `flutter analyze` is clean | From `/app`: `flutter analyze` | `No issues found!` |
| V36 | `dart format` is clean | From `/app`: `dart format --output=none --set-exit-if-changed .` | Exit code `0`. |
| V37 | Phase 1/2 RTL guards still hold | `rg "EdgeInsets\.only\(left|right" app/lib/features/checklist/ app/lib/core/` and `rg "Alignment\.(centerLeft|centerRight)" app/lib/features/checklist/ app/lib/core/` | **Zero** hits in both. |
| V38 | `fardAnchorTaskIds` is single-source | `rg "fardAnchorTaskIds" app/lib/ app/test/` | Exactly one `const` declaration (`domain/fard_anchor_set.dart`); ≤ 3 import sites; no string literals duplicating the IDs. |
| V39 | Fard anchor integrity assert wired into boot | Run a debug build; force-edit `fardAnchorTaskIds` to add a fake id (e.g. `'not_real'`). Hot-restart. | The boot assert in `assertFardAnchorIntegrity()` throws a clear `StateError` referencing the missing id. Revert the edit and confirm the assert is silent. |

## 10. Manual smoke per platform

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V40 | Web (Chrome) — full UX path | Run the §17.1 invocation in `plan.md`. Walk through §17.2–§17.10. | Every sub-step passes without console errors or visible flicker. |
| V41 | Android (if emulator available) | Run §18 in `plan.md`. | §17.4 (edit yesterday) and §17.6 (streak counter) both behave identically to Web. Haptics fire on toggle. |
| V42 | iOS verification | — | Deferred — no macOS in the dev environment per Phase 0 convention. Note `deferred — no macOS` in the PR if applicable. |

## 11. PR hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V43 | PR description links the spec folder | Inspect the PR body | Body contains a link to `specs/phase-3-2026-05-13-history-and-streaks/`. |
| V44 | PR description records the fard anchor decision | Inspect the PR body | Body explicitly lists the 6 fard anchor IDs and acknowledges D1's mapping (`quran_read_six_quarters` stands in for "Fajr/Asr Quran") so reviewers can audit. |
| V45 | Phase 4 handoff note | Inspect the PR body | Body mentions: "Phase 4's bar chart and heatmap should consume `HistoryRepository` directly; do not re-query `daily_logs`" (plan §21.5). |
| V46 | Phase 7 handoff note | Inspect the PR body | Body mentions: "Phase 7 should introduce `tasks.is_fard` and migrate `fardAnchorTaskIds` to a query" (plan §21.6). |
| V47 | README status line updated | `git diff master -- README.md` | Status line reads `Phase 3 ✅ — history strip + streaks (EN + AR, today/yesterday editable)` (or equivalent), and a link to this spec folder is added alongside Phase 0 / 1 / 2. |
| V48 | CI is green | GitHub Actions PR checks | `app-lint`, `app-test` (if present), and `api-lint` all green at squash-merge time. |

---

### Notes for the reviewer

- Phase 3 ships **no schema migration**, **no new dependency**, and **no backend touch**. The diff is feature-folder + 2 tests + 7 ARB keys.
- The fard anchor mapping is the only judgment call worth scrutinizing — see D1 and V44.
- The "today is on the logical-end" strip layout is a `Directionality`-aware choice, not a hard `left` / `right` — see V37.
- Read-only behavior on days 2–30 is **unchanged** from Phase 2; the only behavioral widening is yesterday becoming editable (D2 / V13 / V29).
