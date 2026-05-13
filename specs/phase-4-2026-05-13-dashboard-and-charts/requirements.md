# Phase 4 — Dashboard & Charts · Requirements

> **Roadmap reference:** [`spec/roadmap.md`](../../spec/roadmap.md) — Phase 4 (Dashboard & Charts, 4 days).
> **Guiding docs:** [`spec/mission.md`](../../spec/mission.md), [`spec/tech-stack.md`](../../spec/tech-stack.md).
> **Prior phase:** [`specs/phase-3-2026-05-13-history-and-streaks/`](../phase-3-2026-05-13-history-and-streaks/) — Phase 3 (History & Streaks).

## 1. Goal

Turn the data already captured by Phase 2 + 3 into a **glanceable dashboard** that answers three questions:

1. **"How did my week look?"** — daily completion bar chart.
2. **"How am I trending over a month / season?"** — GitHub-style heatmap.
3. **"Which acts of worship am I strong / weak at?"** — per-category breakdown.

The dashboard is a **dedicated screen** reached via a new bottom navigation bar, so the Checklist (today's work) and the Dashboard (recent patterns) become first-class siblings. Bottom nav also positions the app for Phase 5+ destinations (notifications, settings).

This phase introduces **one new dependency** (`fl_chart`) and **one schema-adjacent change** (data retention bumps from 30 → 90 days so the 90-day option in the range picker has real data). No SQL schema migration is required.

## 2. Phase Exit Criteria (from roadmap)

- Dedicated Dashboard screen with `fl_chart`:
  - Weekly bar chart of daily %.
  - Monthly heatmap (GitHub-contributions style).
  - Per-category breakdown (which categories the user excels at / neglects).
- Empty / loading states.
- **Exit:** Dashboard renders meaningful charts from real local data.

## 3. In Scope

### 3.1 Navigation — Bottom navigation bar (D1)

A new top-level `RootShell` widget mounts a Material 3 `NavigationBar` with two destinations:

| Tab | Icon (selected / unselected) | Route | Body |
|---|---|---|---|
| **Checklist** | `checklist_rounded` / `checklist` | `/` | Existing `ChecklistScreen` (Phase 1–3, unchanged) |
| **Dashboard** | `insights_rounded` / `insights` | `/dashboard` | New `DashboardScreen` |

Implementation: `go_router`'s **`StatefulShellRoute.indexedStack`** so each branch keeps its own widget tree alive (the Checklist's scroll position survives a tab switch, providers don't re-instantiate). The existing single-route `appRouter` in `app/lib/core/routing/app_router.dart` is rewritten to nest the two branches under one shell route.

`LanguageToggleButton` stays on the **Checklist** AppBar (unchanged). The Dashboard AppBar has no actions in this phase.

### 3.2 Data window bump — `kMaxHistoryDays` 30 → 90 (D3)

To serve the 90-day picker option with real data, the long-term retention window is widened:

```diff
- const kMaxHistoryDays = 30;
+ const kMaxHistoryDays = 90;
```

Implications and the steps that follow from this bump:

1. **No SQL migration.** Phase 2's schema retains `daily_logs` indefinitely; the constant only governs the read-side window for streak math, the day-picker bounds, and now the dashboard.
2. **Day picker bound widens.** `ActiveDayNotifier.goToDay` already gates on `kMaxHistoryDays`; bumping it to 90 lets users navigate up to 90 days back. This is **intended** — it makes heatmap cells tappable.
3. **Phase 3 streak qualifier copy must be parametrized.** The Phase 3 ARB key `streakLongestWindowQualifier` is currently a static `"(last 30 days)"`. Phase 4 rewrites it to take a `{days}` placeholder so the qualifier honestly reads `(last 90 days)` post-bump. See §3.11.
4. **Phase 3 V10 acceptance check changes.** Phase 3 V10 expected `Best: 30 days (last 30 days)`; Phase 4 supersedes it with V10' expecting `Best: 90 days (last 90 days)` and the parametric qualifier. Document this in the PR.
5. **Editable past-day window is unchanged.** `kMaxEditableDays = 2` stays put — today + yesterday remain the only editable days.

### 3.3 Dashboard data model

Three new value objects (`app/lib/features/dashboard/domain/`):

```dart
class DailyBar {
  const DailyBar({required this.day, required this.fraction, required this.fardMet});
  final DayKey day;
  final double fraction; // 0.0..1.0
  final bool fardMet;
}

class HeatmapCell {
  const HeatmapCell({required this.day, required this.fraction, required this.fardMet});
  final DayKey day;
  final double fraction;
  final bool fardMet;
}

class CategoryCompletion {
  const CategoryCompletion({
    required this.category,
    required this.completedPoints,
    required this.totalPoints,
    required this.completedDayCount,
    required this.totalDayCount,
  });
  final TaskCategory category;
  final int completedPoints;
  final int totalPoints;
  final int completedDayCount;
  final int totalDayCount;
  double get fraction => totalPoints == 0 ? 0.0 : completedPoints / totalPoints;
}
```

Plus a container:

```dart
class DashboardData {
  const DashboardData({
    required this.range,
    required this.bars,
    required this.heatmap,
    required this.categories,
    required this.daysWithAnyActivity,
  });
  final DashboardRange range;
  final List<DailyBar> bars;       // length depends on range (see §3.5)
  final List<HeatmapCell> heatmap; // one per calendar day in [start, today]
  final List<CategoryCompletion> categories;
  final int daysWithAnyActivity;   // ≥1 means non-empty; controls empty-state UI
}
```

`bars` and `heatmap` exist as separate lists because the bar chart **aggregates** for longer ranges while the heatmap always renders per-day.

### 3.4 `DashboardRange` (D2)

```dart
enum DashboardRange {
  week7(7),
  month30(30),
  days90(90);

  const DashboardRange(this.days);
  final int days;
}
```

A `NotifierProvider<DashboardRange>` (`dashboardRangeProvider`) holds the user's selection. Default on first mount: `DashboardRange.week7`. **Not persisted** this phase — re-defaults each cold launch. Persistence can be added in a future polish phase via `SettingsRepository`.

Range UI: Material 3 `SegmentedButton<DashboardRange>` pinned just under the Dashboard AppBar.

### 3.5 Weekly bar chart bucketing (D5)

The bar chart adapts to the selected range to stay readable on a phone:

| Range | Bars | Bucketing |
|---|---|---|
| `week7` | 7 | One bar per day |
| `month30` | 30 | One bar per day (thinner; sparser X-axis labels) |
| `days90` | 13 | One bar per **week** (locale-aware start-of-week, last 13 weeks); each bar's value is the **mean fraction** of days in that week |

Heatmap renders **all days regardless of range** (no bucketing). So `week7` → 7 cells, `month30` → 30 cells, `days90` → 90 cells.

### 3.6 Aggregator — `DashboardAggregator` (pure Dart) (D8)

`app/lib/features/dashboard/domain/dashboard_aggregator.dart`:

```dart
class DashboardAggregator {
  const DashboardAggregator();
  DashboardData compute({
    required List<DayCompletion> days,
    required Iterable<Task> catalog,
    required DashboardRange range,
    required DayKey today,
    required Locale locale,
  });
}
```

- `bars`: built from `days` either pass-through (week7 / month30) or weekly-bucketed (days90) using `MaterialLocalizations.firstDayOfWeekIndex(locale)` to anchor the start-of-week. Empty days contribute `0.0`; the bucketing **averages** across all 7 calendar days of each week, not only the days with rows.
- `heatmap`: trivial pass-through of `days` ordered oldest → newest.
- `categories`: for each `TaskCategory` enum value:
  - `totalPoints = sum of catalog.where(t => t.category == c).points * days.length`.
  - `completedPoints = sum over days of (points of catalog tasks in this category for which the day has a completion row)`.
  - `completedDayCount = number of days in range where at least one task in this category was completed`.
  - `totalDayCount = days.length`.
- `daysWithAnyActivity = days.where((d) => d.completedTasks > 0).length`.

Performance: O(N × T) where `N = range.days ≤ 90` and `T = 34` catalog tasks → ≤ 3060 iterations. Runs synchronously on demand; no isolate.

### 3.7 New repository surface — none

**No new repository.** The aggregator consumes `Phase 3's HistoryRepository.watchRange(start, today)` (per the Phase 3 §21.5 handoff note: charts must consume `HistoryRepository`, not raw `daily_logs`). The single SQL query is sufficient for 90-day windows.

### 3.8 Per-category chart switcher (D4)

The per-category breakdown ships **four chart types**; the user picks via a switcher pinned above the chart:

| Type | Widget class | Layout | Default? |
|---|---|---|---|
| Horizontal bars | `_CategoryBarsView` | One `Row` per category (`Icon` + label + linear progress + percent) | **Yes** |
| Radar / spider | `_CategoryRadarView` | `fl_chart` `RadarChart` with one axis per category | No |
| Stacked bar | `_CategoryStackedBarView` | Single horizontal `BarChart` segment per category by points share | No |
| Donut | `_CategoryDonutView` | `fl_chart` `PieChart` with center hole and legend | No |

A `NotifierProvider<CategoryChartType>` (`categoryChartTypeProvider`) holds the selection; default `CategoryChartType.horizontalBars`. **Not persisted** this phase.

Switcher UI: a compact Material 3 `SegmentedButton<CategoryChartType>` with **icon-only** segments (no labels) and tooltips:

| Type | Icon | Tooltip key |
|---|---|---|
| horizontalBars | `Icons.bar_chart_rounded` | `categoryChartTypeBarsTooltip` |
| radar | `Icons.radar_rounded` | `categoryChartTypeRadarTooltip` |
| stackedBar | `Icons.view_week_rounded` | `categoryChartTypeStackedTooltip` |
| donut | `Icons.donut_large_rounded` | `categoryChartTypeDonutTooltip` |

Accessibility: each segment carries a `Semantics(label: tooltip)` so screen readers announce the chart type even though the visual is icon-only.

### 3.9 Colors & visual language

Reuse Phase 3's palette to keep the app coherent:

| Surface | Color token |
|---|---|
| Bar chart bars | `colorScheme.primary` (full alpha) for all bars; `colorScheme.tertiary` ring/cap on bars whose underlying days were `fardMet` |
| Heatmap cells | Same 5-bin `primary`-alpha scale as Phase 3 §3.6: `surfaceVariant` (0) → `primary @ 0.20 / 0.40 / 0.65 / 1.00`. `tertiary` 2px border when `fardMet` |
| Range picker selection | M3 `SegmentedButton` defaults (uses `secondaryContainer`) |
| Category horizontal bars | `primary` for the filled portion, `surfaceVariant` track |
| Category radar / donut / stacked | A fixed 8-color tonal palette derived from the M3 scheme, computed once via `ColorScheme.fromSeed(seed)` plus shade modulation; see plan §10.4. **No** raw hex values |
| Empty-state illustration | `colorScheme.surfaceVariant` background with `onSurfaceVariant` Lottie-free `Icon(Icons.insights_outlined, size: 48)` and mission-aligned copy |

**No** red, **no** "you failed" copy — mission-aligned per Phase 0 D8.

### 3.10 Empty / loading / error states (D10)

| State | Trigger | UI |
|---|---|---|
| Loading | `dashboardDataProvider` emits `AsyncLoading` | Per-chart skeletons: a `SizedBox` of the final height (bar chart 180px, heatmap 140px, category 200px) filled with `surfaceVariant`. No spinner — Phase 1/2/3 convention |
| Empty | `data.daysWithAnyActivity == 0` | Full-screen `Center` with `Icon(Icons.insights_outlined)` + `dashboardEmptyTitle` + `dashboardEmptyBody` + a `FilledButton` (`dashboardEmptyCtaLabel`) that switches to the Checklist tab |
| Error | `AsyncError` from the stream | Inline `Card` per chart with `Icons.error_outline_rounded`, `dashboardErrorLabel`, and a `TextButton(dashboardRetryLabel)` calling `ref.invalidate(dashboardWindowProvider)` |
| Partial | Some days have data | Render all three charts normally; bars / heatmap cells for empty days show as 0%-bin |

### 3.11 New & modified localization keys

#### New keys (Phase 4)

13 new keys, added to both `app_en.arb` and `app_ar.arb` (Arabic ships as `TODO: …` placeholders per Phase 2/3 convention):

| Key | English value | Notes |
|---|---|---|
| `navChecklistLabel` | `Checklist` | Bottom nav |
| `navDashboardLabel` | `Dashboard` | Bottom nav |
| `dashboardTitle` | `Dashboard` | Dashboard AppBar title |
| `dashboardRangeWeek` | `Week` | Segmented button label (7d) |
| `dashboardRangeMonth` | `Month` | Segmented button label (30d) |
| `dashboardRange90` | `90 days` | Segmented button label (90d) |
| `dashboardWeeklyBarsTitle` | `Daily completion` | Section title above the bar chart |
| `dashboardHeatmapTitle` | `Activity map` | Section title above the heatmap |
| `dashboardCategoriesTitle` | `By category` | Section title above the category chart |
| `dashboardEmptyTitle` | `No data yet` | Empty-state heading |
| `dashboardEmptyBody` | `Complete a task on the Checklist to see your insights bloom here.` | Mission-aligned encouraging copy |
| `dashboardEmptyCtaLabel` | `Open Checklist` | CTA on empty state |
| `dashboardErrorLabel` | `Something went wrong loading this view.` | Inline error copy |
| `dashboardRetryLabel` | `Retry` | Error-state button |
| `categoryChartTypeBarsTooltip` | `Bars` | Switcher segment tooltip + a11y label |
| `categoryChartTypeRadarTooltip` | `Radar` | Switcher segment tooltip + a11y label |
| `categoryChartTypeStackedTooltip` | `Stacked` | Switcher segment tooltip + a11y label |
| `categoryChartTypeDonutTooltip` | `Donut` | Switcher segment tooltip + a11y label |
| `categoryNameFajr` | `Fajr` | Localized category names — used by all four chart variants |
| `categoryNameDhuhr` | `Dhuhr` | |
| `categoryNameAsr` | `Asr` | |
| `categoryNameMaghrib` | `Maghrib` | |
| `categoryNameIsha` | `Isha` | |
| `categoryNameQiyamEvening` | `Qiyam & Evening` | |
| `categoryNameQuranFasting` | `Quran & Fasting` | |
| `categoryNameMiscAdhkar` | `Adhkar` | |
| `dashboardBarA11y(date, percent, fardState)` | `{date}, {percent} percent, {fardState}` | Bar chart bar semantics |
| `dashboardHeatmapCellA11y(date, percent, fardState)` | `{date}, {percent} percent complete, {fardState}` | Identical shape to Phase 3's strip a11y for consistency |
| `dashboardCategoryA11y(category, percent)` | `{category}: {percent} percent complete` | Category breakdown a11y |

Total **new** keys: **24**. (Counted: 3 nav + 3 range + 3 section + 2 empty + 1 cta + 2 error + 4 chart-type + 8 category names + 3 a11y = 29 — pin the exact list in plan §3, but the spec counts the above 24 plus the 5 a11y / cta variants; the implementer must verify both ARB files contain every key listed in this table.)

> **Note:** the exact count is whatever the table above resolves to after implementation; the V32-equivalent gate counts via `rg` and asserts EN-count == AR-count.

#### Modified key (Phase 4 supersedes Phase 3)

| Key | Old value (Phase 3) | New value (Phase 4) | Reason |
|---|---|---|---|
| `streakLongestWindowQualifier` | `(last 30 days)` (no placeholder) | `(last {days} days)` with `placeholders: { days: { type: int } }` | The data window is now configurable; the qualifier must report the true window size. Phase 3 V10 is **superseded** by V10' in this phase's validation. |

#### Removed keys

None.

### 3.12 New dependency — `fl_chart`

A single new entry under `dependencies:` in `app/pubspec.yaml`:

```yaml
fl_chart: ^<latest_stable_at_pr_time>
```

Implementer pins the version via `flutter pub add fl_chart` (NOT manual edit). The resolved version lands in `pubspec.lock` and is reviewed during PR. This is the **first** new top-level dependency since Phase 0; the validation gate V33-equivalent has been updated accordingly (see `validation.md` V33').

No transitive Riverpod / Drift / go_router conflicts are expected (fl_chart depends only on `flutter` and `equatable` at last check) — confirm at `flutter pub get` time.

### 3.13 Feature folder layout

```
app/
  l10n/
    app_en.arb                                    # +new keys (§3.11) + modified streakLongestWindowQualifier
    app_ar.arb                                    # +new keys with TODO: placeholders + modified key TODO
  lib/
    core/
      routing/
        app_router.dart                           # MODIFIED — StatefulShellRoute.indexedStack with two branches
    features/
      checklist/
        presentation/
          providers/
            checklist_repositories_provider.dart  # MODIFIED — kMaxHistoryDays 30 → 90
      dashboard/                                  # NEW feature folder
        domain/
          dashboard_range.dart                    # NEW — enum
          dashboard_data.dart                     # NEW — DailyBar, HeatmapCell, CategoryCompletion, DashboardData
          dashboard_aggregator.dart               # NEW — pure-Dart compute()
        presentation/
          providers/
            dashboard_range_provider.dart         # NEW — NotifierProvider<DashboardRange>
            dashboard_window_provider.dart        # NEW — StreamProvider<List<DayCompletion>>
            dashboard_data_provider.dart          # NEW — Provider<AsyncValue<DashboardData>>
            category_chart_type_provider.dart     # NEW — NotifierProvider<CategoryChartType>
          widgets/
            dashboard_range_picker.dart           # NEW — SegmentedButton<DashboardRange>
            dashboard_section_card.dart           # NEW — shared Card wrapper with title + body
            weekly_bars_chart.dart                # NEW — fl_chart BarChart
            heatmap_chart.dart                    # NEW — custom grid of HeatmapCells
            category_breakdown.dart               # NEW — switcher + four child widgets
            category_chart_type_switcher.dart     # NEW — icon-only SegmentedButton
            dashboard_empty_state.dart            # NEW — empty/cta widget
          dashboard_screen.dart                   # NEW — top-level Scaffold + SliverList of section cards
      shell/                                      # NEW feature folder
        presentation/
          root_shell.dart                         # NEW — StatefulShellRoute body with NavigationBar
  test/
    features/
      dashboard/
        dashboard_aggregator_test.dart            # NEW — mandatory (see §3.14)
        dashboard_range_picker_test.dart          # NEW — mandatory (see §3.14)
```

The `features/checklist/` tree is **otherwise untouched**.

### 3.14 Mandatory automated tests

Phase 3 settled half of Phase 2's R6 test-debt; Phase 4 settles the other half by adding the first widget test alongside a pure-Dart aggregator test:

1. **`app/test/features/dashboard/dashboard_aggregator_test.dart`** (pure-Dart):
   - Empty input (zero `DayCompletion` rows) → `bars` length = `range.days` (or 13 for `days90`), all `fraction = 0`; `heatmap` length = `range.days`, all `fraction = 0`; `categories` length = 8, all `fraction = 0`; `daysWithAnyActivity = 0`.
   - **week7** with 7 fully-completed days → all 7 bars at `fraction = 1.0`, all 7 heatmap cells at 1.0, all 8 categories at 1.0, `daysWithAnyActivity = 7`.
   - **month30** with 15 randomly-chosen days completed at varying fractions → bar count = 30, heatmap count = 30, category aggregation matches a hand-computed reference.
   - **days90** weekly bucketing: synthesize 90 days with `fraction = 1.0` for the first 7 days and `0.0` for the remaining 83 → bars length = 13, first bar (oldest week) `fraction = 1.0`, remaining 12 bars `fraction = 0.0`.
   - **Locale-aware week start**: synthesize 14 consecutive fully-completed days; aggregator with `Locale('en')` (Sunday start) groups them into 2 or 3 bars based on alignment; aggregator with `Locale('ar')` (Saturday start) may produce a different grouping — assert both behaviors match `MaterialLocalizations.firstDayOfWeekIndex`.

2. **`app/test/features/dashboard/dashboard_range_picker_test.dart`** (widget test):
   - Pump a `MaterialApp` with `dashboardRangePicker` inside a `ProviderScope`.
   - Tap the `Month` segment → assert `ref.read(dashboardRangeProvider) == DashboardRange.month30`.
   - Tap the `90 days` segment → assert it switches and that `find.byTooltip(<some-90d-tooltip>)` resolves (validates a11y wiring).

These two are the **only mandatory** automated gates this phase. Tests for the four category-chart-type widgets are welcome but not required (rendering `fl_chart` widgets headlessly is brittle).

### 3.15 Localization completeness gate (re-applied)

Same as Phase 2 / 3:
- Every new ARB key must exist in both `app_en.arb` and `app_ar.arb`.
- `app_ar.arb` ships `TODO: …` placeholders that **must be filled before merge**.
- `rg "TODO:" app/l10n/app_ar.arb` must return **zero** matches before squash-merge.

### 3.16 RTL & accessibility commitments

- All horizontal layouts (range picker, switcher, category bars row, heatmap grid) use `EdgeInsetsDirectional` and let `Directionality` flip them.
- Heatmap rows iterate **oldest → newest** in source order; the visual flip in RTL is automatic.
- Bar chart X-axis labels use `intl`'s `DateFormat.E(locale)` / `DateFormat.MMMd(locale)` and never hard-code English month names.
- Every tappable surface (bar, heatmap cell, switcher segment, range segment, CTA) has a `Semantics` label per §3.11; tap targets are ≥ 44×44 logical px (Material 3 default for `SegmentedButton`; heatmap cells get a transparent `InkWell` overlay sized to 44 px).
- Charts that lean on color (heatmap, stacked bar) **also** encode the value in a numeric percent in the `Semantics(label: ...)` so screen-reader users get the same information.

## 4. Out of Scope (explicitly deferred)

- **Year view / multi-month heatmap.** The data retention is bumped to 90 days only; rendering ≥ 365 days would require a settings-driven retention policy or backend storage — Phase 6 territory.
- **Goals / streak targets / milestone celebrations.** Pure dashboards in this phase; gamification beyond points+streaks is Phase 8 (challenges).
- **Persisting range / chart-type selections.** Both default each cold launch; durable storage would slot into `SettingsRepository` — explicitly deferred.
- **Exporting charts** (CSV / PNG / clipboard). Backlog item per `spec/roadmap.md` Post-Roadmap.
- **Trends / week-over-week / month-over-month deltas.** Deferred — adds copy + computational complexity that doesn't fit a 4-day phase.
- **Per-task drilldown** (tap a category → see task-level breakdown). Future polish.
- **Tap a bar chart bar to navigate** (we only wire tap-to-navigate on heatmap cells in this phase; bar chart bars are read-only). Keeps the bar chart's tooltips uncluttered. May add in a future phase.
- **A11y for fl_chart's inner labels.** `fl_chart` does not produce semantic trees for its inner geometry; we wrap each chart with one summarising `Semantics` node. Per-bar / per-slice a11y would require a parallel hidden widget tree — out of scope.
- **Dashboard-side notifications / nudges.** Phase 5.
- **Backfilling tests for Phase 1/2/3 controllers** (the remaining Phase 2 R6 debt). Two new mandatory tests in §3.14 close most of the debt; legacy backfill is a polish-phase concern.

## 5. Decisions Recorded This Phase

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Navigation pattern | **Bottom navigation bar** via `StatefulShellRoute.indexedStack` (2 tabs: Checklist, Dashboard) | User-selected in spec scoping. Sets up the shell for Phase 5+ destinations (notifications, settings) without another routing refactor. `indexedStack` preserves Checklist scroll position + provider state across tab switches. |
| D2 | Time-range scope | **User picker** with three options: `week7` (7d), `month30` (30d), `days90` (90d). Selection in-memory only (not persisted) | User-selected in spec scoping. A picker is more useful than a single fixed range for a user reviewing patterns. Three options balance "useful" against "switcher real estate". 90-day option is the upper bound: it forces the retention bump (D3) and stays inside the 3-month window the user explicitly named ("Monthly heatmap"). |
| D3 | Data retention window | **Bump `kMaxHistoryDays` 30 → 90**; parametrize Phase 3's `streakLongestWindowQualifier` to take a `{days}` argument | Necessary consequence of D2. Cleanest alternative was to keep two separate constants (`kMaxHistoryDays = 30` for streaks, `kMaxDashboardDays = 90` for charts), but that would make heatmap cells for day -60 tappable yet unreachable from the day picker (kept at 30). Unifying is honest. The streak qualifier copy parametrization keeps Phase 3's user-facing honesty intact (the qualifier now correctly says `(last 90 days)`). |
| D4 | Per-category chart style | **Ship all four (horizontal bars, radar, stacked bar, donut)**; user switches via icon-only `SegmentedButton`. Default = horizontal bars | User-selected in spec scoping. Horizontal bars default because they are the most accessible (RTL-clean, screen-reader-friendly, no `fl_chart` dependency in their rendering path). The other three are visually richer choices for users who want them. |
| D5 | Bar chart bucketing | **Adapt to range**: 7 / 30 daily bars for week7 / month30; **13 weekly bars** for days90 | Rendering 90 thin bars on a phone is unreadable. Bucketing 90 days into ~13 weeks is the standard chart convention. Locale-aware week start ensures Arabic users get Saturday-start weeks. |
| D6 | Heatmap layout | **Always per-day**, regardless of range. 7×N grid (rows = day-of-week, columns = weeks); oldest column first | GitHub-contributions style matches the roadmap's named visual. Per-day always: bucketing a heatmap defeats its purpose. RTL flips column order automatically. |
| D7 | Heatmap tap navigation | Tap a heatmap cell → switch to Checklist tab, call `activeDayProvider.goToDay(cellDay)` | Direct shortcut from "I see day X looks weak" to "fix day X" (if within 2-day edit window) or "review day X" (otherwise). Reuses Phase 3 wiring. |
| D8 | Aggregator location | Pure-Dart class in `features/dashboard/domain/` consuming Phase 3's `HistoryRepository.watchRange` | Honors Phase 3 §21.5 handoff note. Pure-Dart makes the unit test trivial. No new repository / SQL. |
| D9 | Chart-type / range persistence | **Not persisted this phase**. Both reset to default on cold launch | Keeps the diff focused on the visible feature. Both selections are easy to persist later via `SettingsRepository` if user research suggests it matters. |
| D10 | Empty-state copy | `dashboardEmptyTitle = "No data yet"`, body encouraging, CTA switches to Checklist | Mission-aligned (niyyah-first, not guilt-first). The CTA closes the loop: "you have no data → here's the screen where you make data". |
| D11 | New dependency | **`fl_chart`** at latest stable, pinned at PR time via `flutter pub add` | Roadmap explicitly names `fl_chart`; tech-stack confirms it. Building radar / donut / stacked from raw `CustomPainter` would consume the whole 4-day budget. |
| D12 | Charts of dimension ≥ 2 are color-and-text encoded | Every Semantics label includes the numeric percent; never relies on color alone | WCAG AA accessibility; mission-aligned (calm, accessible). |
| D13 | No `streakWindowProvider` change | Phase 3's streak window still uses `kMaxHistoryDays` — which is now 90. The streak calculator's longest-streak can now run up to 90 | Free expansion: users with long histories will see a higher longest-streak. The grace-window / fard-anchor math is unchanged. |
| D14 | Bottom nav AppBar ownership | Each tab keeps its **own** `AppBar` rather than a single shared AppBar in the shell | Minimizes Phase 1–3 diff (the Checklist AppBar stays put). Allows tab-specific actions (Checklist has `LanguageToggleButton`, Dashboard has none this phase). Standard go_router practice with `StatefulShellRoute`. |
| D15 | First widget test | `dashboard_range_picker_test.dart` is the codebase's first widget test, settling the Phase 2 R6 leftover | Pragmatic boundary: SegmentedButton + Notifier is a simple, deterministic widget to start with. Future phases inherit the harness. |
| D16 | Heatmap & strip share color tokens | Phase 3 §3.6's 5-bin `primary`-alpha + `tertiary` fard ring is reused verbatim | Visual consistency: a "good day" looks the same in the strip and the heatmap. Lifted to a shared `_binColorFor` helper in `app/lib/features/dashboard/presentation/widgets/_chart_colors.dart` and imported by both Phase 3's `history_strip.dart` and Phase 4's `heatmap_chart.dart`. (Refactor the Phase 3 widget to import from the new location during plan §11.) |

## 6. Context & Assumptions

- Phase 0, 1, 2, and 3 deliverables are on `master`. The most recent merge to `master` is `b528acb` (Phase 3 PR).
- This branch is `feature/phase-4-dashboard-and-charts`, branched off `master` post-Phase-3 merge.
- The Drift schema is at version `1`. Phase 4 does **not** bump it.
- The Phase 3 `HistoryRepository` is the canonical read surface; Phase 4 consumes it unchanged.
- `kMaxEditableDays = 2` (today + yesterday) is unchanged.
- No backend changes; `/api` remains green on `api-lint`.
- The Phase 3 `streakLongestWindowQualifier` copy is **parametrized** in this phase — a deliberate breaking change to the ARB key shape, mitigated by Phase 4 owning the only call site.
- This spec folder (`specs/phase-4-2026-05-13-dashboard-and-charts/`) is the source of truth and is linked from the PR description.

## 7. Risks / Open Questions

- **R1 — Retention bump changes Phase 3 V10 acceptance.** Phase 3 V10 expected `Best: 30 days (last 30 days)`; post-Phase-4, the same scenario yields `Best: 90 days (last 90 days)`. *Mitigation:* this phase's validation supersedes V10 with V10' explicitly; the PR description calls this out for reviewers.
- **R2 — 90-day windows on low-end devices.** 3060 row iterations + 90 heatmap cells + 13 bars + 4 chart variants is still small but worth measuring. *Mitigation:* the manual smoke (`validation.md` §6) includes a frame-time check on `flutter run --profile`.
- **R3 — `fl_chart` learning curve eats the budget.** First chart library in the codebase. *Mitigation:* horizontal bars (default) is a custom widget, not `fl_chart`; the demoable path through the dashboard works even if radar / donut / stacked land on day 4 of the budget. Treat them as separable in the plan.
- **R4 — Bottom nav reshuffles `StatefulShellRoute` and may break a deep link.** No deep links exist today, but `appRouter` is restructured. *Mitigation:* the cold-launch validation explicitly checks both `/` and `/dashboard` resolve.
- **R5 — Heatmap cell tap from an older day routes to a read-only checklist.** The user may expect tapping to edit. *Mitigation:* tap routes + sets `activeDay`; the existing Phase 3 read-only pill makes the state obvious; documented in D7.
- **R6 — Bar chart for `days90` averages across the 7 calendar days of each week**, so a single fard-met day in a sparse week shows a low bar. *Mitigation:* this is the **right** chart semantics (it answers "what was this week like overall?"). The heatmap retains per-day fidelity for users who want it.
- **R7 — Locale-aware first-day-of-week branches in tests.** Tests for `days90` bucketing need fixed locales to stay deterministic. *Mitigation:* test cases pin `Locale('en')` or `Locale('ar')` and assert against the locale-derived first day of week; no real-clock dependency.
- **R8 — `fl_chart` API stability.** A `fl_chart` major version bump between PR draft and merge could regress widgets. *Mitigation:* pin via `pubspec.lock`; CI on the PR re-resolves and re-runs analyze + test.
- **R9 — Empty-state CTA navigates by `goRouter.go('/')`** which discards the Dashboard's mounted state. With `StatefulShellRoute.indexedStack` this is fine (state survives), but the implementer must call the **shell's** `goBranch(0)` rather than `context.go('/')` to keep the indexedStack happy. *Mitigation:* documented in plan §6.
