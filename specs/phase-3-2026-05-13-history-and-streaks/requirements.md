# Phase 3 — History & Streaks · Requirements

> **Roadmap reference:** [`spec/roadmap.md`](../../spec/roadmap.md) — Phase 3 (History & Streaks, 3 days).
> **Guiding docs:** [`spec/mission.md`](../../spec/mission.md), [`spec/tech-stack.md`](../../spec/tech-stack.md).
> **Prior phase:** [`specs/2026-05-12-local-persistence-sqlite/`](../2026-05-12-local-persistence-sqlite/) — Phase 2 (Local Persistence with Drift/SQLite).

## 1. Goal

Make daily consistency **visible at a glance** by layering three new affordances on top of the Phase 2 data layer:

1. **7-day history strip** on the home screen — a rolling, color-coded heatmap of the last seven days (today on the logical end).
2. **Streak counters** — a "current streak" and "longest streak" pill driven by completion of the fard anchor set.
3. **"On this day" editing** — past-day rows become tappable for **yesterday only**; days older than yesterday remain read-only (Phase 2 pill preserved for them).

This phase introduces **no schema changes**. All new state is computed live from the `daily_logs` rows already written by Phase 2. The Riverpod surface gains derived providers; no existing provider's public contract changes meaning.

## 2. Phase Exit Criteria (from roadmap)

- 7-day strip on the home screen (color-coded by completion %).
- Current streak + longest streak counters.
- "On this day" navigation to view/edit past days (configurable window — this phase uses **today + yesterday** for editing).
- **Exit:** User sees their last 7 days at a glance and a live streak counter.

## 3. In Scope

### 3.1 Streak definition (D1)

A **streak day** is a calendar day on which **every task in the fard anchor set** is marked complete. The fard anchor set is the smallest catalog-grounded mapping of the roadmap's "5 daily prayers + Fajr/Asr Quran" intent against the Phase 1 static catalog:

| Task ID | Catalog title (EN) | Points | Notes |
|---|---|---|---|
| `fajr_first_congregation` | First Congregation (Jama'ah) | 2 | Fajr fard via congregation |
| `dhuhr_first_congregation` | First Congregation (Jama'ah) | 2 | Dhuhr fard |
| `asr_first_congregation` | First Congregation (Jama'ah) | 2 | Asr fard |
| `maghrib_first_congregation` | First Congregation (Jama'ah) | 2 | Maghrib fard |
| `isha_first_congregation` | First Congregation (Jama'ah) | 2 | Isha fard |
| `quran_read_six_quarters` | Reading six quarters (~1.5 Juz') | 2 | Stand-in for "Fajr/Asr Quran"; the catalog's daily Wird task |

Total fard anchor points: **12** out of 74. Anchor cardinality: **6**.

The set is exposed as `const Set<String> fardAnchorTaskIds` in a new `app/lib/features/checklist/domain/fard_anchor_set.dart`. **No persistence column** is introduced for "is fard" in Phase 3 — the set is a code-level constant. Phase 7 (custom tasks) is the right phase to introduce a column (`is_fard`) on `tasks` and migrate this constant onto a query.

### 3.2 Streak math (D4 / D5)

`Streak compute(List<DayCompletion> days, {required DayKey today})` returns:

- `int currentStreak` — the longest run of consecutive `fardMet == true` days **ending at today or yesterday**:
  - If `today.fardMet == true`, count back from today.
  - Else if `yesterday.fardMet == true`, count back from yesterday (today is "in progress", no penalty yet — the **grace window**).
  - Else `currentStreak == 0`.
- `int longestStreak` — the maximum run length of consecutive `fardMet == true` days anywhere in the input window.

The window fed into the calculator is the **last `kMaxHistoryDays` (30) days** — the same window Phase 2 already retains. The longest-streak number is therefore bounded by available data; this is documented to the user via a small qualifier label (see §3.7).

### 3.3 Day-completion summaries (the unit of read-side history)

A new `DayCompletion` value object (`app/lib/features/checklist/domain/day_completion.dart`):

```dart
class DayCompletion {
  final DayKey day;
  final int completedPoints;
  final int totalPoints;       // sum of catalog points (constant 74 in this phase)
  final int completedTasks;
  final int totalTasks;        // catalog cardinality (constant 34)
  final bool fardMet;          // fardAnchorTaskIds ⊆ completedTaskIds
  double get fraction => totalPoints == 0 ? 0.0 : completedPoints / totalPoints;
}
```

`DayCompletion` is computed by joining the read-side `daily_logs` rows for a given date with the in-memory catalog (filtered to the static catalog's known IDs — preserves the Phase 2 D7 "filter, don't delete" rule).

### 3.4 New repository — `HistoryRepository`

A new layer in `app/lib/features/checklist/data/`:

- **`history_repository.dart`** — abstract:
  ```dart
  abstract class HistoryRepository {
    Future<List<DayCompletion>> readRange(DayKey start, DayKey end);
    Stream<List<DayCompletion>> watchRange(DayKey start, DayKey end);
  }
  ```
- **`drift_history_repository.dart`** — concrete impl backed by `AppDatabase`:
  - One SQL read: `SELECT date, task_id, completed FROM daily_logs WHERE date BETWEEN ? AND ? AND completed = 1`.
  - Group by `date` in Dart.
  - Join against the in-memory `staticTaskCatalog` to compute points + fard-met flag.
  - **Returns one `DayCompletion` per calendar day in `[start, end]` inclusive**, even if no rows exist for a given day (those are returned with `completedPoints = 0`, `fardMet = false`).
  - `watchRange` uses Drift's `.watch()` on the same query, re-emitting whenever any `daily_logs` row in the range changes.

The existing `ChecklistRepository` is **not modified**.

### 3.5 Editable past-day window (D2 / D11)

Phase 3 introduces a single new constant alongside the existing `kMaxHistoryDays`:

- `const kMaxEditableDays = 2;` — today + yesterday are editable.

Behavior changes:

- `TaskRow` becomes editable when `activeDay` is **today or yesterday**. Previously (Phase 2) only today was.
- `ChecklistController.toggle` and `ChecklistController.resetDay` accept yesterday as well as today.
- The Phase 2 "Read-only" pill is shown only when `activeDay` is **at least 2 days in the past** (i.e., `today.daysSince(activeDay) >= 2`). It is **hidden** on today and yesterday.
- The long-press "reset" affordance is available on **today and yesterday** (was today-only in Phase 2).
- The 30-day calendar picker is unchanged in range — only the *editability* of the selected day changes.

Both constants live in `checklist_repositories_provider.dart` so the Phase 2 V22 single-source-of-truth guard still holds for `kMaxHistoryDays`; `kMaxEditableDays` is its sibling.

### 3.6 7-day history strip (D3 / D6)

A new widget `app/lib/features/checklist/presentation/widgets/history_strip.dart`:

- Shows **7 cells**, one per day, for `[today - 6, today]` inclusive — today is on the **logical end** (right in LTR, left in RTL — uses `EdgeInsetsDirectional` and standard row order to defer to `Directionality`).
- Each cell:
  - Rounded square ~36×36 logical px with 6 px gaps; total strip ~54 px tall (cell + day-of-week label).
  - **Background color** by completion bin (5 bins, D3):

    | Bin | Range | Color |
    |---|---|---|
    | 0 | `fraction == 0` | `colorScheme.surfaceVariant` |
    | 1 | `0 < fraction < 0.25` | `colorScheme.primary` @ alpha 0.20 |
    | 2 | `0.25 ≤ fraction < 0.50` | `colorScheme.primary` @ alpha 0.40 |
    | 3 | `0.50 ≤ fraction < 0.75` | `colorScheme.primary` @ alpha 0.65 |
    | 4 | `fraction ≥ 0.75` | `colorScheme.primary` @ alpha 1.00 |

  - **Fard ring**: when `fardMet == true`, draw a 2 px ring in `colorScheme.tertiary` around the cell (the "streak-day" signal — decoupled from the completion bin so a fard-only day still shows the ring even if `fraction ≈ 0.16`).
  - **Today's cell** gets an additional outer ring in `colorScheme.outline` (Material 3 emphasis) regardless of completion.
  - **Active-day highlight**: if `activeDayProvider == cellDay`, fill is replaced by `colorScheme.primaryContainer` for visual continuity with the day picker bar.
  - Below each cell: one-letter day-of-week label (`Mon` → `M`, `Tue` → `T`, etc.) localized via `DateFormat.E(locale).format(...).characters.first` — RTL-safe.
- **Tap target**: the full cell + label area is one tap region (≥ 44×44 logical px effective), wired to `activeDayProvider.notifier.goToDay(cellDay)`.
- **Semantics**: each cell announces `historyStripCellA11y(date, percent, fardState)` — e.g., `"Wednesday, 13 May, 50 percent complete, fard complete"`.

**Placement**: between the `DayPickerBar` and the `ChecklistProgressHeader` — as its own `SliverToBoxAdapter`.

### 3.7 Streak counters (D7)

A new widget `app/lib/features/checklist/presentation/widgets/streak_pills.dart`:

- Two side-by-side pills in a `Row`:
  - **Current**: flame icon (`Icons.local_fire_department_rounded`) + `streakCurrentLabel(count)` (e.g., `"Current: 3 days"`). If `currentStreak == 0`, copy is `streakCurrentEmpty` (`"Start a streak today"`) — mission-aligned, encouraging.
  - **Longest**: trophy icon (`Icons.workspace_premium_rounded`) + `streakLongestLabel(count)` (e.g., `"Best: 7 days"`). When the available window caps the value, append a small qualifier — `streakLongestWindowQualifier` (`"(last 30 days)"`) — to keep the user honest.
- Both pills use `colorScheme.secondaryContainer` background, `onSecondaryContainer` foreground; soft-green per mission. **No** red, **no** exclamation marks, **no** "you missed" copy.
- Pills wrap below the progress header in their own `SliverToBoxAdapter`. They share horizontal padding with the header so they line up visually.

### 3.8 Riverpod providers

New providers in `app/lib/features/checklist/presentation/providers/`:

| Provider | Type | Source |
|---|---|---|
| `historyRepositoryProvider` | `Provider<HistoryRepository>` | `DriftHistoryRepository(ref.watch(appDatabaseProvider))` |
| `historyStripWindowProvider` | `StreamProvider.autoDispose<List<DayCompletion>>` | `historyRepository.watchRange(today - 6, today)` — sized for the 7-day strip |
| `streakWindowProvider` | `StreamProvider.autoDispose<List<DayCompletion>>` | `historyRepository.watchRange(today - 29, today)` — sized for streak math |
| `streakProvider` | `Provider<AsyncValue<Streak>>` | derives from `streakWindowProvider`; uses `StreakCalculator.compute(...)` |

Both `historyStripWindowProvider` and `streakWindowProvider` recompute their `today` bound by watching `activeDayProvider` — but only the **calendar today**, not the user-selected `activeDay`. We achieve this via a small helper provider `calendarTodayProvider` that exposes `DayKey.today()` and re-emits when the midnight ticker rolls (Phase 2's `MidnightTickerService` already calls `goToDay(newToday)`; Phase 3 adds a side-emit to this provider).

`checklistStateProvider`, `dailyProgressProvider`, `taskCatalogProvider`, `activeDayProvider` — **unchanged in contract**. `ChecklistController.toggle` and `resetDay` widen their guard from "today only" to "today or yesterday".

### 3.9 Feature folder layout (delta from Phase 2)

```
app/
  l10n/
    app_en.arb                                # +7 new keys (see §3.10)
    app_ar.arb                                # +7 new keys with TODO: placeholders
  lib/
    features/
      checklist/
        data/
          history_repository.dart             # NEW — abstract
          drift_history_repository.dart       # NEW — concrete
        domain/
          fard_anchor_set.dart                # NEW — const Set<String>
          day_completion.dart                 # NEW — value object
          streak.dart                         # NEW — { current, longest, windowDays }
          streak_calculator.dart              # NEW — pure-Dart math
        presentation/
          providers/
            calendar_today_provider.dart      # NEW — pushes DayKey.today() on rollover
            history_repository_provider.dart  # NEW
            history_strip_window_provider.dart# NEW
            streak_window_provider.dart       # NEW
            streak_provider.dart              # NEW
            checklist_repositories_provider.dart # MODIFIED — adds kMaxEditableDays + widens ChecklistController guard
          widgets/
            history_strip.dart                # NEW
            streak_pills.dart                 # NEW
            task_row.dart                     # MODIFIED — editable when activeDay ∈ {today, yesterday}
            checklist_progress_header.dart    # MODIFIED — read-only pill gate updated; long-press allowed on yesterday
          checklist_screen.dart               # MODIFIED — inserts strip + streak pills slivers
  test/
    domain/
      streak_calculator_test.dart             # NEW — mandatory (see §3.12)
    data/
      drift_history_repository_test.dart      # NEW — mandatory (see §3.12)
```

### 3.10 New localization keys

Added to **both** `app_en.arb` and `app_ar.arb` (Arabic values ship as `TODO: …` placeholders again — V36-equivalent gate; see Phase 2 D9 / R9 convention):

| Key | English value | Notes |
|---|---|---|
| `historyStripCellA11y(date, percent, fardState)` | `{date}, {percent} percent complete, {fardState}` | `date` is a localized full weekday + day; `fardState` ∈ {`fard complete`, `fard not complete`} (two more keys below) |
| `historyStripFardComplete` | `fard complete` | Inserted into the a11y string |
| `historyStripFardIncomplete` | `fard not complete` | Inserted into the a11y string |
| `streakCurrentLabel(count)` | `Current: {count} {count, plural, one{day} other{days}}` | |
| `streakCurrentEmpty` | `Start a streak today` | When current == 0; mission-aligned encouragement |
| `streakLongestLabel(count)` | `Best: {count} {count, plural, one{day} other{days}}` | |
| `streakLongestWindowQualifier` | `(last 30 days)` | Honesty qualifier; static — see D5 |

Total: **7** new keys.

### 3.11 No new top-level dependencies

Phase 3 ships **no new entries** in `app/pubspec.yaml`. Everything is built from the Phase 2 stack (Drift + Riverpod + intl + Material 3). The validation suite explicitly checks for this.

### 3.12 Mandatory automated tests (R6 settle from Phase 2)

Phase 2 D15 / R6 flagged that the first phase touching the repository layer must budget half a day for test backfill. Phase 3 settles part of that debt with **two** mandatory tests:

1. **`app/test/domain/streak_calculator_test.dart`** (pure-Dart, no Flutter binding):
   - Empty window → `current = 0`, `longest = 0`.
   - All-fard for 3 consecutive days ending today → `current = 3`, `longest = 3`.
   - All-fard for 5 consecutive days ending **yesterday**, today is empty → `current = 5` (grace window), `longest = 5`.
   - All-fard for 2 days, gap, then 4 more days ending today → `current = 4`, `longest = 4`.
   - All-fard for 7 days but **not** today and **not** yesterday → `current = 0`, `longest = 7`.
   - Partial completion (≥75% but fard set incomplete) → counts as `fardMet = false`; does not advance the streak.

2. **`app/test/data/drift_history_repository_test.dart`** (Drift `NativeDatabase.memory()`):
   - Seed `daily_logs` for `2026-05-08`, `2026-05-10`, `2026-05-12` with mixed completion patterns (one day fard-complete, one day partial, one day with only non-fard tasks).
   - Call `readRange(DayKey(2026, 5, 7), DayKey(2026, 5, 13))` → expect exactly **7** `DayCompletion` rows, dates `2026-05-07` … `2026-05-13`, with the seeded days having correct `completedPoints` / `fardMet` and the unseeded days reporting `0` / `false`.
   - Assert `watchRange` emits a new `List<DayCompletion>` when a new row is inserted into the range.

These two are the **only** mandatory automated gates this phase. Other tests are welcome but not required.

### 3.13 Localization completeness gate (re-applied)

Same as Phase 2 §3.13:
- Every new ARB key must exist in both `app_en.arb` and `app_ar.arb`.
- `app_ar.arb` ships `TODO: …` placeholders that **must be filled before merge**.
- `rg "TODO:" app/l10n/app_ar.arb` must return **zero matches** before squash-merge.

## 4. Out of Scope (explicitly deferred)

- Dashboard screen, weekly bar chart, monthly heatmap, per-category breakdown → **Phase 4**.
- Notifications (any kind) → **Phase 5**.
- Auth, cloud sync, sync queue, conflict resolution → **Phase 6**.
- User-custom tasks (CRUD), hide/disable default tasks, `is_fard` column on `tasks` → **Phase 7**.
- Weekly challenges → **Phase 8**.
- Extending the editable window beyond yesterday (e.g., a "fix last week" affordance) — explicitly rejected this phase; documented under D2.
- Extending the longest-streak data window beyond 30 days (would require a settings-driven retention policy or a backend) — Phase 6 or later.
- Backfilling tests for `ChecklistController` / `ActiveDayNotifier` (Phase 2 R6 leftover) — partial backfill via the two mandatory tests in §3.12; full coverage remains owned by a future polish phase.

## 5. Decisions Recorded This Phase

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Streak threshold | A streak day = **all fard tasks complete**, where the fard anchor set is the 6 specific catalog IDs in §3.1 | User-selected option in spec scoping ("All fard tasks done — 5 daily prayers + Fajr/Asr Quran"). The catalog has no per-prayer Quran row; `quran_read_six_quarters` (daily Wird) is the closest fit and is what the user implicitly meant — documented here so reviewers can audit the mapping. |
| D2 | Edit window | Today **and** yesterday are editable; days 2–30 stay read-only | User-selected option in spec scoping ("edit today and yesterday and other is view-only"). Keeps the Phase 2 30-day view window intact; the read-only pill carries over for days ≥ 2. |
| D3 | 7-day strip layout | Rolling last 7 days, today on logical-end; 5-bin color (0% / <25% / <50% / <75% / ≥75%) + tertiary-color ring overlay when `fardMet == true` | User-selected option in spec scoping ("rolling_5bins"). The fard ring is decoupled from the % bin so a fard-only day (low %) is still visually marked as a streak day. |
| D4 | Streak grace window | `currentStreak` counts back from **today if today.fardMet, else from yesterday** — today's pending fard does not break the streak | Mission's "niyyah-first, not guilt-first" — the user must not see their streak drop to 0 at 12:01 AM. |
| D5 | Longest-streak data window | Bounded by `kMaxHistoryDays = 30`; longest-streak counter appends a `(last 30 days)` qualifier | Phase 2's data retention is the source of truth; we do not invent a longer retention here. The qualifier keeps the user informed without overpromising. |
| D6 | History strip placement | Between `DayPickerBar` and `ChecklistProgressHeader`, as its own sliver | Visual flow: navigate (picker) → glance (strip) → details (progress + tasks). Avoids redundancy between picker label and strip cells. |
| D7 | Streak pills placement | Own sliver below `ChecklistProgressHeader`, shared horizontal padding | Keeps vertical density low; pills are a glance affordance, not the primary header. |
| D8 | Test harness scope | Two mandatory tests: `streak_calculator_test.dart` + `drift_history_repository_test.dart` | Settles **part** of Phase 2 R6 — covers the two new high-risk surfaces (streak math off-by-one + range query semantics). Full coverage remains future-phase work. |
| D9 | Color tokens | Reuse Material 3 `primary` (with alpha) for bins, `tertiary` for fard ring, `secondaryContainer` for streak pills | No new color tokens in the theme — keeps mission "calm by design" intact. |
| D10 | Reset-today affordance scope | Long-press the progress header opens the reset dialog on **today or yesterday** (Phase 2: today only) | Symmetry with D2 — anything editable is also resettable. The dialog body copy stays the same; the `resetDay` call targets `activeDay`, not hard-coded today. |
| D11 | Read-only pill gate | Shown when `activeDay.daysSince(today) <= -2`; hidden otherwise | Phase 2 V22 used `activeDay != today`; Phase 3 widens the "editable" side. |
| D12 | Fard anchor identity | Code-level `const Set<String>` in `domain/fard_anchor_set.dart`; **no** schema change to `tasks` | Schema stability — Phase 3 ships no migrations. Phase 7 owns the data-layer evolution (`is_fard` column). |
| D13 | A11y for strip cells | Each cell is a button with `Semantics(label: ..., button: true)`; ≥ 44×44 logical-px tap area | Mission's "frictionless logging" + Material 3 a11y guidance. |
| D14 | Strip cells before app install | Render as bin 0 (empty/grey); visually identical to a "missed day" | We **cannot** distinguish "user didn't have the app" from "user missed the day" without a settings-stored install date. Accepting visual ambiguity; the streak counter is the authoritative signal for "missed". Documented under R5. |
| D15 | Calendar today vs active day | New `calendarTodayProvider` exposes `DayKey.today()` reactively; strip + streak window providers watch it, not `activeDayProvider` | The strip should anchor to **wall-clock today** regardless of which day the user is reviewing. Midnight rollover triggers a single emit on this provider. |
| D16 | No new ARB sections | New keys live alongside Phase 2 keys in the existing files; no nested section markers | The ARB format is flat by design; reviewers diff against the previous keys in order. |

## 6. Context & Assumptions

- Phase 0, 1, and 2 deliverables are on `master`. The most recent merge to `master` is `6894b42` (Phase 2 PR).
- This branch is `feature/phase-3-history-and-streaks`, branched off `master` post-Phase-2 merge.
- The Drift schema is at version `1`. Phase 3 does **not** bump it.
- The static catalog has **34 tasks** summing to **74 points**, with the fard anchor set summing to **12 points** across **6 tasks**. These constants will be assert-checked at boot per the Phase 2 D7 / V16 convention (existing assert) — Phase 3 adds a sibling assert that the fard anchor set IDs all exist in `staticTaskCatalog` (debug builds only).
- No backend changes; `/api` remains green on `api-lint`.
- Phase 2 R6 budget ("half a day in arrears for tests") is consumed by §3.12.
- This spec folder (`specs/phase-3-2026-05-13-history-and-streaks/`) is the source of truth for the feature and will be linked from the PR description.

## 7. Risks / Open Questions

- **R1 — Fard anchor mapping is opinionated.** `quran_read_six_quarters` stands in for "Fajr/Asr Quran"; a user who reads Quran but not via this specific task will see their streak break. *Mitigation:* documented in D1; Phase 7 will introduce per-task `is_fard` to let users tag their own anchor set. The roadmap exit criterion ("live streak counter") is met regardless of the exact mapping.
- **R2 — Longest-streak is bounded by 30 days.** A user with a 31-day streak will see `Best: 30 days (last 30 days)` — technically truthful but underwhelming. *Mitigation:* the qualifier copy `(last 30 days)` is mandatory (V18). Phase 6's cloud sync or a future settings-driven retention bump can lift this.
- **R3 — Editable-yesterday + midnight rollover interaction.** At 23:59 the user edits "yesterday" (which is calendar day N-1). At 00:01 the user is still on the same screen — Phase 2's ticker now considers calendar day N the new today, so what was "yesterday" is still N-1 (no change in `activeDay`) and remains editable for **one more day** (until N+1's midnight). *This is the intended behavior* (D2 / D4 grace), but the edge case must be tested (V22).
- **R4 — Strip cell tap and the calendar picker both navigate.** Three navigation surfaces now coexist (chevrons, strip cells, calendar picker). *Mitigation:* documented; all three call `goToDay(...)` on the same notifier so semantics are identical. The strip is a glance + 1-tap shortcut for the recent window; the picker remains the path for older days.
- **R5 — Strip cells before install look identical to missed days.** *Mitigation:* accepted ambiguity (D14); streak counter is authoritative for "missed". A future enhancement could store `first_use_date` in `app_settings` and dim pre-install cells, but it's out of scope this phase.
- **R6 — Stream provider re-emission storm.** `historyStripWindowProvider` watches a 7-day Drift range; toggling a single task today emits a new list every keystroke. *Mitigation:* Drift's `.watch()` already debounces at the connection level; Riverpod's `StreamProvider` only rebuilds listeners on distinct values — `DayCompletion` overrides `==`/`hashCode` by field-equality so identical re-emissions are filtered.
- **R7 — `quran_read_six_quarters` is fard-anchored but worth only 2 points.** A user who skips it but completes all 5 prayers gets fraction ≈ 0.135 and `fardMet = false`. *Mitigation:* this is **the intended interpretation** — D1 says all fard anchors must be ticked. The user can revisit the anchor set in Phase 7.
- **R8 — RTL strip ordering.** Today must appear on the **logical end** of the row, which is the right in LTR and the left in RTL. *Mitigation:* the strip's `Row` lists cells from oldest → newest and lets `Directionality` flip the visual order. A widget test verifies this against both `TextDirection.ltr` and `TextDirection.rtl`. *(Optional widget test — not mandatory per §3.12 — but the manual verification in `validation.md` §6 covers it.)*
