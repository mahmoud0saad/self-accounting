# Phase 4 — Dashboard & Charts · Validation

> This phase merges when **every** check below passes. Two automated tests (V20, V21) are the mandatory gates; the rest are manual but expected to be verified end-to-end before opening the PR for review.

## 1. Roadmap exit criteria

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V1 | Dedicated Dashboard screen exists | Launch the app; tap the second bottom-nav destination. | A new full-screen route resolves at `/dashboard`; its AppBar title reads `Dashboard` (or the localized equivalent); no checklist content bleeds in. |
| V2 | Weekly bar chart of daily % renders from real data | Complete a varied mix of tasks across yesterday and today on the Checklist tab. Switch to Dashboard with `Week` selected. | The bar chart inside the `dashboardWeeklyBarsTitle` section card renders **7 bars**. Today's bar height matches `(today_completed_points / 74) × 100` to within rounding. Yesterday's bar matches similarly. Empty days render as zero-height bars. |
| V3 | Monthly heatmap (GitHub-contributions style) renders from real data | With `Month` selected, scroll to the `dashboardHeatmapTitle` section card. | The heatmap renders a 7-row × ⌈30/7⌉-column grid of cells. Today's cell shows the tertiary fard ring if `fardMet`. Empty days render as `surfaceContainerHighest`. |
| V4 | Per-category breakdown renders from real data | With `Week` selected on a non-empty DB, scroll to the `dashboardCategoriesTitle` section card. | The default horizontal-bars view shows 8 rows (one per `TaskCategory`); each row's progress bar matches the category's hand-computed fraction across the 7-day window. |
| V5 | Empty state renders before any data exists | Cold-launch on a fresh DB; tap the Dashboard tab without touching the Checklist. | The empty state renders (icon + `dashboardEmptyTitle` + `dashboardEmptyBody` + `dashboardEmptyCtaLabel` button) instead of zero-filled charts. |
| V6 | Loading state renders during the first stream emission | Throttle the Drift stream (insert a synthetic 500 ms delay in `dashboardWindowProvider` for the test). Tap the Dashboard tab. | All three section cards show `surfaceContainerHighest`-colored skeleton boxes of the final heights (180 / 140 / 200 px) before the data arrives. No spinner. |

## 2. Navigation (bottom nav)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V7 | Bottom navigation bar mounts at the app root | Inspect any screen — Checklist or Dashboard. | A Material 3 `NavigationBar` with exactly **two** destinations (Checklist, Dashboard) is fixed at the bottom of the viewport; both icons + labels are visible. |
| V8 | Each tab preserves state across switches | Scroll the Checklist halfway down, switch to Dashboard, switch back. | Checklist's scroll position is **identical** to where it was; providers were not torn down (Phase 2's `seedAndReconcile` doesn't re-run). |
| V9 | Tab labels localize | Toggle to Arabic via the Checklist AppBar; confirm both nav labels switch to the Arabic copy (or TODO copy before V37 clears). | Labels reflect the active locale. |
| V10 | Routes resolve directly | Open `http://localhost:<port>/#/dashboard` in Chrome from a cold session. | The app boots into the Dashboard tab; bottom nav shows tab 1 selected. The Checklist branch is **also** mounted underneath (indexedStack) — tap the Checklist nav destination to confirm it renders without reload. |

## 3. Data window bump

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V11 | `kMaxHistoryDays` is exactly `90` | `rg "kMaxHistoryDays" app/lib/` | Single declaration `const kMaxHistoryDays = 90;` in `checklist_repositories_provider.dart`. No literal `30` remains anywhere referencing this concept. |
| V12 | Day picker can navigate up to 90 days back | On the Checklist tab, tap the day picker's "previous day" chevron 90 times (or use the calendar picker if Phase 3 exposed one). | The day picker accepts navigation down to `today - 89` (inclusive) and stops at `today - 90` (exclusive). Tapping previous after the bound is a no-op. |
| V13 | Streak window now considers up to 90 days | Inspect `app/lib/features/checklist/presentation/providers/streak_window_provider.dart`. | The window's start is `today - (kMaxHistoryDays - 1)` and resolves to a 90-day input for `StreakCalculator.compute`. |
| **V10'** | **Streak qualifier copy honors the new window** | (Supersedes Phase 3 V10.) Synthesize 90 consecutive fard-met days. Inspect the Streak Pills on the Checklist. | Longest-streak pill reads exactly `Best: 90 days (last 90 days)` in EN — i.e., the `{days}` placeholder of `streakLongestWindowQualifier` is filled with `90`, not the static `30`. |
| V14 | `streakLongestWindowQualifier` ARB key is parametric | `rg "streakLongestWindowQualifier" app/l10n/` | Both `app_en.arb` and `app_ar.arb` declare the key with a `placeholders.days` of type `int`. The English value is `(last {days} days)` (no literal `30`). |

## 4. Range picker

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V15 | Range picker has exactly three options | Inspect the picker on the Dashboard. | Three `ButtonSegment`s: `Week`, `Month`, `90 days` (or their localized equivalents). Default selection is `Week`. |
| V16 | Selecting `Month` re-aggregates all three charts | Tap `Month`. | Bar chart updates to 30 bars; heatmap updates to 30 cells; category breakdown updates its percentages to the 30-day window. |
| V17 | Selecting `90 days` switches the bar chart to 13 weekly buckets | Tap `90 days`. | Bar chart renders **13** (or close — ⌈90/7⌉) weekly bars, not 90 daily bars. Heatmap renders 90 daily cells. |
| V18 | Selection does **not** persist across cold launches | Switch to `Month`, hot-restart the app. | On restart, the Dashboard re-defaults to `Week`. (Documented behavior — D9.) |

## 5. Mandatory automated tests

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V19 | Phase 3's tests still pass | From `/app`: `flutter test test/data/drift_history_repository_test.dart test/domain/streak_calculator_test.dart test/data/drift_checklist_repository_test.dart` | All three suites pass unchanged. |
| V20 | `dashboard_aggregator_test.dart` passes | From `/app`: `flutter test test/features/dashboard/dashboard_aggregator_test.dart` | All five test groups (empty / week7-full / month30-mixed / days90-bucketing / locale-aware) pass. |
| V21 | `dashboard_range_picker_test.dart` passes | From `/app`: `flutter test test/features/dashboard/dashboard_range_picker_test.dart` | Tapping each segment updates `dashboardRangeProvider` to the expected value. |

## 6. Chart correctness

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V22 | Bar chart Y-axis is bounded to `[0, 100]` | Inspect the chart with a 100%-day. | The tallest bar reaches the chart's top gridline; no overshoot. Empty days show as flat. |
| V23 | Heatmap cell colors match Phase 3's strip palette | On a day with `fraction ≈ 0.30`, sample the heatmap cell color vs. the same day's strip cell on the Checklist tab. | The two cells render the **same** background color (both use `completionBinColor` via `_chart_colors.dart`). |
| V24 | Fard ring shows on heatmap cells when `fardMet == true` | Complete the 6 fard-anchor tasks for today. Switch to Dashboard. | Today's heatmap cell shows the 2-px `tertiary` ring. Uncheck one fard task → ring disappears within one frame. |
| V25 | Heatmap tap switches to Checklist + sets `activeDay` | Tap a heatmap cell 3 days back. | Bottom nav transitions to tab 0 (Checklist); the Checklist's `DayPickerBar` label reads the tapped date; the rows for that day render (read-only since it's beyond `kMaxEditableDays`). |
| V26 | Category breakdown horizontal-bar percentages match the aggregator | For a known fingerprint (e.g., all 5 fard prayers done today, nothing else), compute expected per-category fractions and compare to the rendered values. | The on-screen percent rounds to the same integer as the hand-computed value. |
| V27 | Chart-type switcher swaps the category view | Tap each of the 4 icon segments. | The category section's `child` changes between `_CategoryBarsView`, `_CategoryRadarView`, `_CategoryStackedBarView`, `_CategoryDonutView` without remounting the surrounding card. |
| V28 | Each chart-type segment has a tooltip | Long-press / hover each segment. | Tooltip shows the localized `categoryChartType*Tooltip` value (or TODO copy before V37). |

## 7. Empty / loading / error states

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V29 | Empty CTA switches branches (not loses state) | On the empty state, tap the CTA. Then switch back to Dashboard. | The CTA calls `StatefulNavigationShell.goBranch(0)` (NOT `context.go('/')`). After completing a task and switching back, the Dashboard re-renders with charts; the empty state does not reappear. |
| V30 | Error state surfaces an inline retry | Force `dashboardWindowProvider` to throw (test-only override). | The Dashboard renders a single `Card` with `Icons.error_outline_rounded` + `dashboardErrorLabel` + a `Retry` button that calls `ref.invalidate(dashboardWindowProvider)`. |
| V31 | Loading state has no spinner | Observe the very first frame of the Dashboard tab on a cold launch. | Skeleton boxes appear; no `CircularProgressIndicator` is anywhere in the tree (`find.byType(CircularProgressIndicator)` returns zero). |

## 8. Provider plumbing

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V32 | New providers exist with documented contracts | Inspect `app/lib/features/dashboard/presentation/providers/`. | These files exist: `dashboard_range_provider.dart`, `dashboard_window_provider.dart`, `dashboard_data_provider.dart`, `category_chart_type_provider.dart`. |
| V33 | `dashboardWindowProvider` watches `calendarTodayProvider` | Inspect `dashboard_window_provider.dart`. | The provider body calls `ref.watch(calendarTodayProvider)` and never references `activeDayProvider`. Navigating the active day on the Checklist tab does **not** rebuild the Dashboard window. |
| V34 | `dashboardDataProvider` composes window + catalog | Inspect `dashboard_data_provider.dart`. | The provider reads both `dashboardWindowProvider` and `taskCatalogProvider` and only emits `AsyncData` when both are ready. |
| V35 | `dashboardFirstDayOfWeekProvider` is overridden at the screen level | Inspect `dashboard_screen.dart`. | The screen wraps its body in `ProviderScope(overrides: [dashboardFirstDayOfWeekProvider.overrideWithValue(...)])` using `MaterialLocalizations.of(context).firstDayOfWeekIndex`. |

## 9. Localization & dependency hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V36 | All Phase 4 ARB keys exist in both locales | `rg '"dashboardTitle"|"navChecklistLabel"|"navDashboardLabel"|"dashboardRangeWeek"|"dashboardRangeMonth"|"dashboardRange90"|"dashboardWeeklyBarsTitle"|"dashboardHeatmapTitle"|"dashboardCategoriesTitle"|"dashboardEmptyTitle"|"dashboardEmptyBody"|"dashboardEmptyCtaLabel"|"dashboardErrorLabel"|"dashboardRetryLabel"|"categoryChartTypeBarsTooltip"|"categoryChartTypeRadarTooltip"|"categoryChartTypeStackedTooltip"|"categoryChartTypeDonutTooltip"|"categoryNameFajr"|"categoryNameDhuhr"|"categoryNameAsr"|"categoryNameMaghrib"|"categoryNameIsha"|"categoryNameQiyamEvening"|"categoryNameQuranFasting"|"categoryNameMiscAdhkar"|"dashboardBarA11y"|"dashboardHeatmapCellA11y"|"dashboardCategoryA11y"' app/l10n/` | Each key appears **once** in `app_en.arb` and **once** in `app_ar.arb`. Total counts match between the two files. |
| V37 | Zero pending Arabic placeholders | `rg "TODO:" app/l10n/app_ar.arb` | **Zero** matches. |
| V38 | Plural / placeholder keys use correct ICU metadata | Inspect the `@dashboardBarA11y`, `@dashboardHeatmapCellA11y`, `@dashboardCategoryA11y`, and `@streakLongestWindowQualifier` metadata blocks. | Each block declares its placeholders with the right `type` (`String` for date / category / fardState, `int` for percent / days). |
| **V33'** | **Exactly one new top-level dependency** (`fl_chart`) | `git diff master -- app/pubspec.yaml` | The only new line under `dependencies:` is `fl_chart: ^X.Y.Z`. `pubspec.lock` shows the matching resolved version plus transitively-introduced packages. (Supersedes Phase 3 V33, which expected zero deltas.) |
| V39 | No raw hex colors in dashboard widgets | `rg "Color\(0x" app/lib/features/dashboard/` | **Zero** matches. All colors flow from `ColorScheme`. |

## 10. Lints, format & RTL guard

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V40 | `flutter analyze` is clean | From `/app`: `flutter analyze` | `No issues found!` |
| V41 | `dart format` is clean | From `/app`: `dart format --output=none --set-exit-if-changed .` | Exit code `0`. |
| V42 | RTL guards still hold for the new feature folders | `rg "EdgeInsets\.only\(left|right" app/lib/features/dashboard/ app/lib/features/shell/` and `rg "Alignment\.(centerLeft|centerRight)" app/lib/features/dashboard/ app/lib/features/shell/` | **Zero** hits in both. |
| V43 | Heatmap row order is locale-aware | Inspect `heatmap_chart.dart`. Switch to AR at runtime. | The grid's row order respects the locale's `firstDayOfWeekIndex` (e.g., Sat-first in AR); the visual horizontal flip is driven by `Directionality`, not hard-coded. |

## 11. Accessibility

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V44 | Heatmap cells have ≥ 44×44 logical-px tap targets | Inspect via Flutter Inspector. | Each cell's `InkWell` extends a transparent overlay to 44 logical px in both dimensions even though the visible cell is 14 px. |
| V45 | Heatmap cells announce date + percent + fard state | Focus a heatmap cell with TalkBack / VoiceOver / desktop screen reader. | Reader speaks the full localized date, the integer percent, and `"fard complete"` or `"fard not complete"`. |
| V46 | Category-chart-type segments are accessible without seeing the icons | Focus each segment with a screen reader. | Reader speaks the tooltip text (`Bars` / `Radar` / `Stacked` / `Donut`). |
| V47 | Range picker segments announce their range | Focus each segment with a screen reader. | Reader speaks `Week` / `Month` / `90 days` (or the localized equivalents). |

## 12. Cross-tab edits propagate to the Dashboard

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V48 | Toggling a task on Checklist updates the Dashboard in real time | Have Dashboard open in profile mode; switch to Checklist, tick one task; switch back. | The Dashboard's affected day cell (heatmap), today's bar (bar chart), and the corresponding category's row (breakdown) all reflect the new state. No stale data flashes. |
| V49 | Long-press reset on Checklist propagates | Long-press the Checklist progress header → confirm reset for today. Switch to Dashboard. | Today's bar drops to 0; today's heatmap cell drops to `surfaceContainerHighest`; category rows reflect the reset. |

## 13. Manual smoke per platform

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V50 | Web (Chrome) — full UX path | Run §21 of `plan.md`. Walk through §21.2–§21.10. | Every sub-step passes without console errors or visible flicker. |
| V51 | Android (if emulator available) | Run §22 of `plan.md`. | §21.4 / §21.6 / §21.7 behave identically to Web. Safe-area is honored on the bottom nav. |
| V52 | iOS verification | — | Deferred — no macOS in the dev environment per Phase 0 convention. Note `deferred — no macOS` in the PR if applicable. |

## 14. PR hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V53 | PR description links the spec folder | Inspect the PR body. | Body contains a link to `specs/phase-4-2026-05-13-dashboard-and-charts/`. |
| V54 | PR description records the retention bump | Inspect the PR body. | Body explicitly notes: `kMaxHistoryDays bumped from 30 → 90` and `streakLongestWindowQualifier copy parametrized to {days}` — superseding Phase 3 V10 with V10'. |
| V55 | PR description records the new dependency | Inspect the PR body. | Body mentions `fl_chart` added at version X.Y.Z and the validation gate V33' supersession. |
| V56 | PR description records the chart-type matrix | Inspect the PR body. | Body lists all four category chart types (horizontal bars / radar / stacked / donut) and notes default = horizontal bars. |
| V57 | Phase 5 handoff note | Inspect the PR body. | Body mentions: "Phase 5 can wire a third bottom-nav destination at `/notifications`; the shell is reusable" (plan §25.6). |
| V58 | Phase 6 handoff note | Inspect the PR body. | Body mentions: "Phase 6 cloud sync can lift `kMaxHistoryDays` to a settings-driven value; the qualifier copy already accepts a variable `{days}`" (plan §25.7). |
| V59 | README status line updated | `git diff master -- README.md` | Status line reads `Phase 4 ✅ — dashboard with weekly bars, heatmap, category breakdown (EN + AR, 4-way category chart switcher)` (or equivalent), and a link to this spec folder is added alongside Phase 0 / 1 / 2 / 3. |
| V60 | CI is green | GitHub Actions PR checks | `app-lint`, `app-test`, and `api-lint` all green at squash-merge time. |

---

### Notes for the reviewer

- Phase 4 introduces one new dependency (`fl_chart`) and bumps `kMaxHistoryDays` from 30 to 90. Everything else is additive: a new feature folder (`features/dashboard`), a new shell folder (`features/shell`), and a rewritten `app_router.dart`.
- The Phase 3 V10 acceptance check is intentionally **superseded** by V10' in this phase. Reviewers will see the streak qualifier now reads `(last 90 days)` after the bump — this is the contract.
- The diff also lifts the strip's bin-color helper into a shared `_chart_colors.dart`. The Phase 3 strip's visual output is **identical** before and after this refactor; V23 verifies this end-to-end.
- The `dashboardFirstDayOfWeekProvider` is an intentionally simple `Provider<int>` with a Sunday-start default specifically so the aggregator stays pure-Dart and testable; the real value comes from `MaterialLocalizations` at the screen level (V35).
- Per-chart-element a11y inside `fl_chart` widgets is out of scope (R8); the wrapping `Semantics` on each section card carries the summary. The horizontal-bars view (default) provides full per-category a11y for users who depend on it.
