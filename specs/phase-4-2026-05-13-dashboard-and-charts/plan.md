# Phase 4 — Dashboard & Charts · Plan

> Numbered task groups. Each group is self-contained and ordered for least-rework. Adjacent groups may be collapsed into one commit, but ordering should be preserved. Budget: **4 days** per `spec/roadmap.md`.

---

## 1. Branch & sanity

1.1. Confirm you are on `feature/phase-4-dashboard-and-charts` (branched off `master` after the Phase 3 merge `b528acb`).
1.2. From `/app`: `flutter pub get` then `flutter analyze` — must report `No issues found!` before any code lands. Regression check that Phase 3's committed state is clean.
1.3. From `/app`: `flutter test` — confirm `test/data/drift_checklist_repository_test.dart`, `test/data/drift_history_repository_test.dart`, `test/domain/streak_calculator_test.dart`, and `test/widget_test.dart` all still pass. Phase 4's diff must not regress any prior gate.
1.4. Open `app/lib/features/checklist/presentation/providers/checklist_repositories_provider.dart` and confirm `kMaxHistoryDays = 30` and `kMaxEditableDays = 2` are the current values. They are the only constants we will edit in the checklist tree.

## 2. New dependency — `fl_chart`

2.1. From `/app`: `flutter pub add fl_chart`. This appends a `fl_chart: ^X.Y.Z` line to `dependencies:` in `pubspec.yaml` and resolves to the latest stable in `pubspec.lock`.
2.2. From `/app`: `flutter pub get` — confirm no transitive conflicts with `flutter_riverpod`, `drift`, `go_router`, or `intl`.
2.3. From `/app`: `flutter analyze` — must still be `No issues found!`. If `fl_chart` brings new lint hits in its public API, **do not** silence them with `// ignore_for_file:` — wrap the call site in the type you need so the surface stays clean.
2.4. Commit message convention for this single commit: `chore(app): add fl_chart for Phase 4 charts`.

## 3. Retention bump — `kMaxHistoryDays` 30 → 90

3.1. Open `app/lib/features/checklist/presentation/providers/checklist_repositories_provider.dart`. Change:
   ```dart
   const kMaxHistoryDays = 30;
   ```
   to:
   ```dart
   /// Phase 4 D3: bumped from 30 → 90 to power the Dashboard's 90-day range
   /// option. The day picker, streak window, and dashboard window all read
   /// from this single source of truth.
   const kMaxHistoryDays = 90;
   ```
3.2. **No other code changes are required** — `ActiveDayNotifier.goToDay`, `ActiveDayNotifier.goToPreviousDay`, `streak_window_provider.dart`'s `_streakStart`, and Phase 3's strip provider all consume the constant by reference.
3.3. Open `app/l10n/app_en.arb`. Locate the existing Phase 3 entry:
   ```json
   "streakLongestWindowQualifier": "(last 30 days)",
   "@streakLongestWindowQualifier": {}
   ```
   Replace it with:
   ```json
   "streakLongestWindowQualifier": "(last {days} days)",
   "@streakLongestWindowQualifier": {
     "placeholders": { "days": { "type": "int" } }
   },
   ```
3.4. Open `app/l10n/app_ar.arb`. Locate the matching key and replace its value with a `TODO:` placeholder that preserves the new `{days}` placeholder:
   ```json
   "streakLongestWindowQualifier": "TODO: (آخر {days} يومًا)",
   ```
   Keep the `@streakLongestWindowQualifier` metadata block identical to the English file.
3.5. From `/app`: `flutter pub get` — re-runs `gen-l10n`. Confirm `AppLocalizations.streakLongestWindowQualifier` now takes an `int` parameter.
3.6. Update Phase 3's call site in `app/lib/features/checklist/presentation/widgets/streak_pills.dart`:
   ```diff
   - if (streak.longest >= streak.windowDays && streak.windowDays >= kMaxHistoryDays) {
   -   base = '$base ${l.streakLongestWindowQualifier}';
   - }
   + if (streak.longest >= streak.windowDays && streak.windowDays >= kMaxHistoryDays) {
   +   base = '$base ${l.streakLongestWindowQualifier(kMaxHistoryDays)}';
   + }
   ```
   Add the import for `kMaxHistoryDays` if not already present (it lives in `checklist_repositories_provider.dart`).
3.7. From `/app`: `flutter analyze` — must be clean. The build will fail compilation if any other call site of the qualifier was missed; `rg "streakLongestWindowQualifier" app/lib/` should show exactly one Dart call site (the line edited in 3.6) plus the two ARB declarations.
3.8. From `/app`: `flutter test test/domain/streak_calculator_test.dart` — must still pass. The retention bump expands the streak calculator's input window but doesn't change its algorithm.

## 4. Shell — `RootShell` with `StatefulShellRoute.indexedStack`

4.1. Create `app/lib/features/shell/presentation/root_shell.dart`:
   ```dart
   import 'package:app/l10n/app_localizations.dart';
   import 'package:flutter/material.dart';
   import 'package:go_router/go_router.dart';

   class RootShell extends StatelessWidget {
     const RootShell({super.key, required this.shell});
     final StatefulNavigationShell shell;

     @override
     Widget build(BuildContext context) {
       final l = AppLocalizations.of(context)!;
       return Scaffold(
         body: shell,
         bottomNavigationBar: NavigationBar(
           selectedIndex: shell.currentIndex,
           onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
           destinations: [
             NavigationDestination(
               icon: const Icon(Icons.checklist),
               selectedIcon: const Icon(Icons.checklist_rounded),
               label: l.navChecklistLabel,
             ),
             NavigationDestination(
               icon: const Icon(Icons.insights),
               selectedIcon: const Icon(Icons.insights_rounded),
               label: l.navDashboardLabel,
             ),
           ],
         ),
       );
     }
   }
   ```
4.2. Rewrite `app/lib/core/routing/app_router.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:go_router/go_router.dart';

   import '../../features/checklist/presentation/checklist_screen.dart';
   import '../../features/dashboard/presentation/dashboard_screen.dart';
   import '../../features/shell/presentation/root_shell.dart';

   final _checklistKey = GlobalKey<NavigatorState>(debugLabel: 'checklist');
   final _dashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');

   final GoRouter appRouter = GoRouter(
     initialLocation: '/',
     routes: [
       StatefulShellRoute.indexedStack(
         builder: (context, state, shell) => RootShell(shell: shell),
         branches: [
           StatefulShellBranch(
             navigatorKey: _checklistKey,
             routes: [
               GoRoute(path: '/', builder: (_, __) => const ChecklistScreen()),
             ],
           ),
           StatefulShellBranch(
             navigatorKey: _dashboardKey,
             routes: [
               GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
             ],
           ),
         ],
       ),
     ],
   );
   ```
4.3. Add the two nav ARB keys now (the rest will follow in group 12). In `app/l10n/app_en.arb` append:
   ```json
   "navChecklistLabel": "Checklist",
   "@navChecklistLabel": {},
   "navDashboardLabel": "Dashboard",
   "@navDashboardLabel": {},
   ```
   And in `app/l10n/app_ar.arb`:
   ```json
   "navChecklistLabel": "TODO: قائمة المهام",
   "@navChecklistLabel": {},
   "navDashboardLabel": "TODO: لوحة المعلومات",
   "@navDashboardLabel": {},
   ```
4.4. Create a placeholder `DashboardScreen` so the router compiles. In `app/lib/features/dashboard/presentation/dashboard_screen.dart`:
   ```dart
   import 'package:flutter/material.dart';

   class DashboardScreen extends StatelessWidget {
     const DashboardScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return const Scaffold(
         body: Center(child: Text('Dashboard placeholder')),
       );
     }
   }
   ```
4.5. From `/app`: `flutter run -d chrome`. Confirm:
   - Bottom nav appears with two tabs.
   - Tab 0 shows the existing Checklist screen (with `LanguageToggleButton` AppBar action intact).
   - Tab 1 shows the placeholder.
   - Switching tabs and back preserves Checklist scroll position (`indexedStack` guarantee).
4.6. From `/app`: `flutter analyze` — clean.

## 5. Dashboard domain — `DashboardRange`, `DashboardData`, `CategoryChartType`

5.1. Create `app/lib/features/dashboard/domain/dashboard_range.dart`:
   ```dart
   enum DashboardRange {
     week7(7),
     month30(30),
     days90(90);
     const DashboardRange(this.days);
     final int days;
   }
   ```
5.2. Create `app/lib/features/dashboard/domain/category_chart_type.dart`:
   ```dart
   enum CategoryChartType { horizontalBars, radar, stackedBar, donut }
   ```
5.3. Create `app/lib/features/dashboard/domain/dashboard_data.dart`. Define `DailyBar`, `HeatmapCell`, `CategoryCompletion`, and `DashboardData` per `requirements.md` §3.3. All four classes:
   - Are `class` (not `record`) so they get clean `==` / `hashCode` overrides — Riverpod's selector providers need value equality.
   - Override `==` and `hashCode` by all fields.
   - Have a `const` constructor.
5.4. **No** integration with Drift here — these are pure value objects.

## 6. Dashboard domain — `DashboardAggregator`

6.1. Create `app/lib/features/dashboard/domain/dashboard_aggregator.dart`. Skeleton:
   ```dart
   import 'package:flutter/material.dart' show Locale, MaterialLocalizations;
   import 'package:flutter_localizations/flutter_localizations.dart';

   import '../../../core/time/day_key.dart';
   import '../../checklist/domain/day_completion.dart';
   import '../../checklist/domain/task.dart';
   import 'category_chart_type.dart';
   import 'dashboard_data.dart';
   import 'dashboard_range.dart';

   class DashboardAggregator {
     const DashboardAggregator();

     DashboardData compute({
       required List<DayCompletion> days,
       required Iterable<Task> catalog,
       required DashboardRange range,
       required DayKey today,
       required Locale locale,
     }) { /* ... */ }
   }
   ```
6.2. Inside `compute`:
   1. **Trim** `days` to the last `range.days` calendar days ending at `today` (the upstream provider already supplies a `range.days`-sized list, but enforce defensively — `assert(days.length == range.days)` in debug).
   2. **Catalog buckets**: `final byCategory = <TaskCategory, List<Task>>{}` grouped from `catalog`. Compute `catalogPointsByCategory[c] = byCategory[c]!.fold(0, (s, t) => s + t.points)`.
   3. **Heatmap**: map each `DayCompletion` to a `HeatmapCell`, oldest → newest.
   4. **Bars**: branch on `range`:
      - `week7` / `month30`: one `DailyBar` per `DayCompletion`.
      - `days90`: bucket into weeks. Use a helper `_weeklyBuckets(days, today, locale)`:
        - Determine `firstDayOfWeekIndex` from `MaterialLocalizations.of` — but since this is a domain class, accept `locale` and call a small helper that reads `MaterialLocalizations` indirectly. **Implementation**: pass the `firstDayOfWeekIndex` as an argument from the provider layer (the provider has a `BuildContext`-equivalent via `WidgetsBinding`); the aggregator stays pure-Dart and takes `int firstDayOfWeekIndex` instead of `Locale`. **Revise §6.1**: the aggregator's signature becomes `required int firstDayOfWeekIndex` (defaulted to `6` = Saturday for unit tests pinned to AR; `0` = Sunday for EN).
        - Walk the 90 days in order; emit a new bucket every time `day.weekday == firstDayOfWeek`. Trim leading partial bucket if shorter than 7 (or include it — the test pinning will lock the choice; see §13.1.4).
        - Each bucket's `fraction = days.fold(0.0, (s, d) => s + d.fraction) / 7.0` (always divide by 7 to flatten the average across all calendar days of the week, per requirements §3.5).
   5. **Categories**: iterate `TaskCategory.values`; for each, count completions across `days` by checking which task ids fall in `byCategory[c]`. Build `CategoryCompletion`.
      - For `completedDayCount`: a day counts if **any** task in the category was completed.
   6. **`daysWithAnyActivity`**: `days.where((d) => d.completedTasks > 0).length`.
6.3. **Revise** §6.1 to drop `Locale` and accept `int firstDayOfWeekIndex`. Update §5.3 / §13 accordingly.
6.4. Total file size budget: ≤ 180 lines. If it grows beyond, factor `_weeklyBuckets` into a private top-level function in the same file.

## 7. Providers — range, window, data, chart type

7.1. Create `app/lib/features/dashboard/presentation/providers/dashboard_range_provider.dart`:
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import '../../domain/dashboard_range.dart';

   class DashboardRangeNotifier extends Notifier<DashboardRange> {
     @override
     DashboardRange build() => DashboardRange.week7;
     void select(DashboardRange r) => state = r;
   }

   final dashboardRangeProvider =
       NotifierProvider<DashboardRangeNotifier, DashboardRange>(DashboardRangeNotifier.new);
   ```
7.2. Create `app/lib/features/dashboard/presentation/providers/category_chart_type_provider.dart` — same shape, default `CategoryChartType.horizontalBars`.
7.3. Create `app/lib/features/dashboard/presentation/providers/dashboard_window_provider.dart`:
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import '../../../checklist/domain/day_completion.dart';
   import '../../../checklist/presentation/providers/calendar_today_provider.dart';
   import '../../../checklist/presentation/providers/history_repository_provider.dart';
   import '../../../../core/time/day_key.dart';
   import '../../domain/dashboard_range.dart';
   import 'dashboard_range_provider.dart';

   DayKey _startOfRange(DayKey today, DashboardRange range) {
     var cursor = today;
     for (var i = 0; i < range.days - 1; i++) {
       cursor = cursor.previousDay();
     }
     return cursor;
   }

   final dashboardWindowProvider = StreamProvider.autoDispose<List<DayCompletion>>((ref) {
     final today = ref.watch(calendarTodayProvider);
     final range = ref.watch(dashboardRangeProvider);
     final start = _startOfRange(today, range);
     return ref.watch(historyRepositoryProvider).watchRange(start, today);
   });
   ```
7.4. Create `app/lib/features/dashboard/presentation/providers/dashboard_data_provider.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';

   import '../../../checklist/domain/task.dart';
   import '../../../checklist/presentation/providers/task_catalog_provider.dart';
   import '../../../checklist/presentation/providers/calendar_today_provider.dart';
   import '../../domain/dashboard_aggregator.dart';
   import '../../domain/dashboard_data.dart';
   import 'dashboard_range_provider.dart';
   import 'dashboard_window_provider.dart';

   final dashboardFirstDayOfWeekProvider = Provider<int>((ref) {
     // Default to Sunday-start for code paths without a BuildContext (tests).
     // Real value is overridden in DashboardScreen via ProviderScope.override
     // with MaterialLocalizations.of(context).firstDayOfWeekIndex.
     return 0;
   });

   final dashboardDataProvider = Provider.autoDispose<AsyncValue<DashboardData>>((ref) {
     final daysAsync = ref.watch(dashboardWindowProvider);
     final catalogAsync = ref.watch(taskCatalogProvider);
     final range = ref.watch(dashboardRangeProvider);
     final today = ref.watch(calendarTodayProvider);
     final firstDayOfWeek = ref.watch(dashboardFirstDayOfWeekProvider);

     return daysAsync.when(
       loading: () => const AsyncLoading(),
       error: (e, s) => AsyncError(e, s),
       data: (days) => catalogAsync.when(
         loading: () => const AsyncLoading(),
         error: (e, s) => AsyncError(e, s),
         data: (catalog) => AsyncData(const DashboardAggregator().compute(
           days: days,
           catalog: catalog,
           range: range,
           today: today,
           firstDayOfWeekIndex: firstDayOfWeek,
         )),
       ),
     );
   });
   ```
7.5. Note: `dashboardFirstDayOfWeekProvider` is a `Provider<int>` overridden at the `DashboardScreen` level using a `ProviderScope` wrapper that reads `MaterialLocalizations.of(context).firstDayOfWeekIndex`. This keeps the aggregator pure-Dart while letting the widget tree inject the locale-aware value.

## 8. Mandatory test 1 — `dashboard_aggregator_test.dart`

8.1. Create `app/test/features/dashboard/dashboard_aggregator_test.dart`. Imports:
   ```dart
   import 'package:app/features/checklist/domain/day_completion.dart';
   import 'package:app/features/checklist/domain/task.dart';
   import 'package:app/features/checklist/data/static_task_catalog.dart';
   import 'package:app/features/dashboard/domain/dashboard_aggregator.dart';
   import 'package:app/features/dashboard/domain/dashboard_data.dart';
   import 'package:app/features/dashboard/domain/dashboard_range.dart';
   import 'package:app/core/time/day_key.dart';
   import 'package:flutter_test/flutter_test.dart';
   ```
8.2. Test groups (matching `requirements.md` §3.14 verbatim):
   1. **Empty input** — feed `range.days` `DayCompletion`s with all-zero fields:
      - `week7` → 7 bars at 0, 7 heatmap cells, 8 categories at 0, `daysWithAnyActivity == 0`.
      - `month30` → 30/30/8.
      - `days90` → 13 weekly bars, 90 heatmap cells, 8 categories at 0.
   2. **week7 fully complete** — 7 `DayCompletion`s with `fardMet = true`, `completedPoints = 74`, `completedTasks = 34`, `totalPoints = 74`, `totalTasks = 34`. Expect all bars + heatmap cells `fraction = 1.0`; all 8 categories `fraction = 1.0`; `daysWithAnyActivity == 7`.
   3. **month30 mixed** — 15 days at `fraction = 1.0`, 15 days at `fraction = 0.0`. Hand-compute expected category averages and assert against `compute().categories`.
   4. **days90 first-week-only** — 7 days at `fraction = 1.0`, 83 days at `fraction = 0.0`. With `firstDayOfWeekIndex = 0` (Sunday start), assert exactly one bucket has `fraction = 1.0` and 12 buckets have `fraction = 0.0`. (Note: this assumes day 0 of the synthetic data starts on a Sunday — pin the `today` value to a known Sunday-ending date to be deterministic.)
   5. **Locale-aware**: same 14-day fully-complete fixture, `firstDayOfWeekIndex = 0` vs `firstDayOfWeekIndex = 6`. Assert the bar counts differ (or assert specific bucket boundaries shift).
8.3. From `/app`: `flutter test test/features/dashboard/dashboard_aggregator_test.dart` — must pass.

## 9. UI — `DashboardRangePicker` widget

9.1. Create `app/lib/features/dashboard/presentation/widgets/dashboard_range_picker.dart`:
   ```dart
   class DashboardRangePicker extends ConsumerWidget {
     const DashboardRangePicker({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final l = AppLocalizations.of(context)!;
       final selected = ref.watch(dashboardRangeProvider);
       return Padding(
         padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
         child: SegmentedButton<DashboardRange>(
           segments: [
             ButtonSegment(value: DashboardRange.week7, label: Text(l.dashboardRangeWeek)),
             ButtonSegment(value: DashboardRange.month30, label: Text(l.dashboardRangeMonth)),
             ButtonSegment(value: DashboardRange.days90, label: Text(l.dashboardRange90)),
           ],
           selected: {selected},
           onSelectionChanged: (s) => ref.read(dashboardRangeProvider.notifier).select(s.first),
         ),
       );
     }
   }
   ```
9.2. Add ARB keys `dashboardRangeWeek`, `dashboardRangeMonth`, `dashboardRange90` to both `app_en.arb` and `app_ar.arb` (English: `Week`, `Month`, `90 days`; Arabic: `TODO: ...`).
9.3. Build and visual-check: temporarily mount `DashboardRangePicker` inside the placeholder `DashboardScreen.body`. Confirm three segments render and the selection updates the provider.

## 10. Mandatory test 2 — `dashboard_range_picker_test.dart`

10.1. Create `app/test/features/dashboard/dashboard_range_picker_test.dart`:
   ```dart
   testWidgets('range picker updates dashboardRangeProvider', (tester) async {
     await tester.pumpWidget(
       ProviderScope(
         child: MaterialApp(
           localizationsDelegates: AppLocalizations.localizationsDelegates,
           supportedLocales: AppLocalizations.supportedLocales,
           home: Scaffold(body: Builder(builder: (_) => const DashboardRangePicker())),
         ),
       ),
     );
     await tester.pumpAndSettle();

     // Default is week7.
     final container = ProviderScope.containerOf(tester.element(find.byType(DashboardRangePicker)));
     expect(container.read(dashboardRangeProvider), DashboardRange.week7);

     await tester.tap(find.text('Month'));
     await tester.pumpAndSettle();
     expect(container.read(dashboardRangeProvider), DashboardRange.month30);

     await tester.tap(find.text('90 days'));
     await tester.pumpAndSettle();
     expect(container.read(dashboardRangeProvider), DashboardRange.days90);
   });
   ```
10.2. From `/app`: `flutter test test/features/dashboard/dashboard_range_picker_test.dart` — must pass.

## 11. Shared color helper — lifting Phase 3's bin colors

11.1. Create `app/lib/features/dashboard/presentation/widgets/_chart_colors.dart`:
   ```dart
   import 'package:flutter/material.dart';

   /// Maps a [0.0..1.0] completion fraction to the 5-bin palette shared by the
   /// Phase 3 history strip and the Phase 4 heatmap.
   Color completionBinColor(double fraction, ColorScheme scheme) {
     if (fraction <= 0) return scheme.surfaceContainerHighest;
     if (fraction < 0.25) return scheme.primary.withValues(alpha: 0.20);
     if (fraction < 0.50) return scheme.primary.withValues(alpha: 0.40);
     if (fraction < 0.75) return scheme.primary.withValues(alpha: 0.65);
     return scheme.primary;
   }
   ```
   (Use `surfaceContainerHighest` if the project's Phase 3 already migrated off the deprecated `surfaceVariant`; otherwise mirror whatever Phase 3 currently uses to keep the strip + heatmap visually identical.)
11.2. Open `app/lib/features/checklist/presentation/widgets/history_strip.dart`. Replace its private `_binColorFor` helper with an import of `completionBinColor` from `_chart_colors.dart`. Delete the now-unused local helper.
11.3. From `/app`: `flutter analyze` — clean. Manual smoke: cold-launch the Checklist tab; the strip cells render the same colors as before this refactor.

## 12. UI — Section card wrapper

12.1. Create `app/lib/features/dashboard/presentation/widgets/dashboard_section_card.dart`:
   ```dart
   class DashboardSectionCard extends StatelessWidget {
     const DashboardSectionCard({super.key, required this.title, required this.child, this.trailing});
     final String title;
     final Widget child;
     final Widget? trailing;

     @override
     Widget build(BuildContext context) {
       return Card(
         margin: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
         child: Padding(
           padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                   if (trailing != null) trailing!,
                 ],
               ),
               const SizedBox(height: 8),
               child,
             ],
           ),
         ),
       );
     }
   }
   ```
12.2. Three usages: weekly bars, heatmap, category breakdown.

## 13. UI — Weekly bars chart (`fl_chart` `BarChart`)

13.1. Create `app/lib/features/dashboard/presentation/widgets/weekly_bars_chart.dart`. Widget signature:
   ```dart
   class WeeklyBarsChart extends StatelessWidget {
     const WeeklyBarsChart({super.key, required this.bars, required this.range, required this.locale});
     final List<DailyBar> bars;
     final DashboardRange range;
     final Locale locale;
   }
   ```
13.2. Build `BarChartData`:
   - `barGroups`: one `BarChartGroupData` per `DailyBar`. `toY = bar.fraction * 100`. Color = `colorScheme.primary`. If `bar.fardMet`, overlay a `Rect`-style cap in `colorScheme.tertiary` via `BarChartRodData(borderSide: BorderSide(color: scheme.tertiary, width: 2))`.
   - `titlesData`: X-axis labels use `DateFormat.E(locale.toLanguageTag())` for `week7` (Mon/Tue/...), `DateFormat.MMMd(locale.toLanguageTag())` for `month30` (showing every 5th day to avoid clutter), and "Wk N" / `intl` week-of-year for `days90`.
   - `gridData`: horizontal lines at 25 / 50 / 75 / 100.
   - `maxY = 100`, `minY = 0`.
13.3. Wrap the chart in a `SizedBox(height: 180)`. Wrap the whole thing in a single `Semantics(label: l.dashboardWeeklyBarsTitle, value: '${bars.length} bars')` since per-bar a11y is out of scope (R8).
13.4. RTL: `fl_chart` does not honor `Directionality` natively — flip the X-axis programmatically in RTL: detect `Directionality.of(context) == TextDirection.rtl` and reverse `barGroups.toList().reversed.toList()` before passing.

## 14. UI — Heatmap chart

14.1. Create `app/lib/features/dashboard/presentation/widgets/heatmap_chart.dart`. Build a 7-row × N-column grid using `GridView.builder` is the wrong tool (no fixed cross-axis); use a `Table` or a series of nested `Column`s of `Row`s:
   ```dart
   class HeatmapChart extends ConsumerWidget {
     const HeatmapChart({super.key, required this.cells});
     final List<HeatmapCell> cells;
     // ...
   }
   ```
14.2. Layout strategy:
   - 7 rows × ⌈range.days / 7⌉ columns.
   - Bucket cells by `weekday` (using locale-aware day-of-week derived from `firstDayOfWeekIndex`).
   - Empty slots in the leading / trailing column are rendered as transparent boxes the same size as a cell.
14.3. Per-cell widget `_HeatmapCellView`:
   - 14×14 logical px square, 2 px gap, total grid height ≈ 7 × 16 = 112 px.
   - Background via `completionBinColor(cell.fraction, scheme)`.
   - If `cell.fardMet`, 2 px border in `scheme.tertiary`.
   - `InkWell` overlay sized to **44×44** logical px (transparent extension beyond the visible cell) wired to a callback:
     ```dart
     onTap: () {
       ref.read(activeDayProvider.notifier).goToDay(cell.day);
       GoRouter.of(context).go('/'); // or: StatefulNavigationShell.of(context)!.goBranch(0);
     }
     ```
   - `Semantics(label: l.dashboardHeatmapCellA11y(...), button: true, excludeSemantics: true, child: ...)`.
14.4. The "switch back to Checklist" call must use the **shell's** `goBranch(0)` to keep state, **not** `context.go('/')` which discards the Dashboard branch's state. Read the shell via `StatefulNavigationShell.of(context)` (go_router 17+).

## 15. UI — Category breakdown

15.1. Create `app/lib/features/dashboard/presentation/widgets/category_chart_type_switcher.dart`:
   ```dart
   class CategoryChartTypeSwitcher extends ConsumerWidget {
     const CategoryChartTypeSwitcher({super.key});
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final l = AppLocalizations.of(context)!;
       final selected = ref.watch(categoryChartTypeProvider);
       return SegmentedButton<CategoryChartType>(
         segments: [
           ButtonSegment(value: CategoryChartType.horizontalBars, icon: Tooltip(message: l.categoryChartTypeBarsTooltip, child: const Icon(Icons.bar_chart_rounded))),
           ButtonSegment(value: CategoryChartType.radar, icon: Tooltip(message: l.categoryChartTypeRadarTooltip, child: const Icon(Icons.radar_rounded))),
           ButtonSegment(value: CategoryChartType.stackedBar, icon: Tooltip(message: l.categoryChartTypeStackedTooltip, child: const Icon(Icons.view_week_rounded))),
           ButtonSegment(value: CategoryChartType.donut, icon: Tooltip(message: l.categoryChartTypeDonutTooltip, child: const Icon(Icons.donut_large_rounded))),
         ],
         selected: {selected},
         showSelectedIcon: false,
         onSelectionChanged: (s) => ref.read(categoryChartTypeProvider.notifier).select(s.first),
       );
     }
   }
   ```
15.2. Create `app/lib/features/dashboard/presentation/widgets/category_breakdown.dart`. It renders the switcher in the `trailing` slot of the `DashboardSectionCard`, then a `child` that dispatches on the current `CategoryChartType`:
   ```dart
   switch (type) {
     CategoryChartType.horizontalBars => _CategoryBarsView(categories: categories),
     CategoryChartType.radar          => _CategoryRadarView(categories: categories),
     CategoryChartType.stackedBar     => _CategoryStackedBarView(categories: categories),
     CategoryChartType.donut          => _CategoryDonutView(categories: categories),
   }
   ```
15.3. **`_CategoryBarsView`** (default, no `fl_chart`):
   - One `Row` per category: leading `Icon` (category-specific Material icon, e.g. `Icons.wb_twilight_rounded` for Fajr), localized category name (`l.categoryNameFajr` etc.), a `LinearProgressIndicator(value: c.fraction)` taking the remaining width, and a trailing `Text('${(c.fraction*100).round()}%')`.
   - `Semantics(label: l.dashboardCategoryA11y(name, percent))` on the row.
15.4. **`_CategoryRadarView`** (fl_chart `RadarChart`):
   - 8 axes (one per `TaskCategory`).
   - `RadarDataSet` with one entry per category, value = `c.fraction * 100`.
   - `radarBackgroundColor = scheme.surfaceContainerHighest`; `borderColor = scheme.primary`; `fillColor = scheme.primary.withValues(alpha: 0.30)`.
   - Title widgets at each axis use the localized category name.
15.5. **`_CategoryStackedBarView`** (custom `Row` of `Expanded`-flex Containers):
   - For each category, compute `flex = c.totalPoints` (catalog points, so flex represents the catalog weight, not the achieved points).
   - Each cell paints two layers: track in `scheme.surfaceContainerHighest`, fill in `scheme.primary.withValues(alpha: c.fraction)`.
   - Below the bar: a legend `Wrap` with one chip per category showing the localized name + percent.
   - No `fl_chart` dependency here either — this view is essentially `Row + Container`.
15.6. **`_CategoryDonutView`** (fl_chart `PieChart`):
   - Sections: one `PieChartSectionData` per category. `value = c.totalPoints` (catalog weight) so slice angles are stable across days; `color = _categoryColor(c, scheme)`; `radius = (c.fraction * 36) + 12` so a stronger category protrudes further.
   - Center hole: 60% radius.
   - Surrounding legend below the donut.
15.7. **Category color palette**: a private helper `Color _categoryColor(TaskCategory c, ColorScheme scheme)` that returns 8 distinct shades derived from the M3 scheme:
   ```dart
   Color _categoryColor(TaskCategory c, ColorScheme scheme) {
     return switch (c) {
       TaskCategory.fajr         => scheme.primary,
       TaskCategory.dhuhr        => scheme.secondary,
       TaskCategory.asr          => scheme.tertiary,
       TaskCategory.maghrib      => Color.alphaBlend(scheme.primary.withValues(alpha: 0.6), scheme.secondary),
       TaskCategory.isha         => scheme.primary.withValues(alpha: 0.7),
       TaskCategory.qiyamEvening => scheme.secondary.withValues(alpha: 0.7),
       TaskCategory.quranFasting => scheme.tertiary.withValues(alpha: 0.7),
       TaskCategory.miscAdhkar   => scheme.outline,
     };
   }
   ```
   **No** raw hex values.

## 16. UI — Empty state

16.1. Create `app/lib/features/dashboard/presentation/widgets/dashboard_empty_state.dart`:
   ```dart
   class DashboardEmptyState extends StatelessWidget {
     const DashboardEmptyState({super.key, required this.onCheckListPressed});
     final VoidCallback onCheckListPressed;
     // ...
   }
   ```
   Layout: centered `Column` with `Icon(Icons.insights_outlined, size: 48)`, `Text(l.dashboardEmptyTitle, style: textTheme.titleLarge)`, `SizedBox(height: 8)`, `Text(l.dashboardEmptyBody, style: textTheme.bodyMedium)`, `SizedBox(height: 16)`, `FilledButton(onPressed: onCheckListPressed, child: Text(l.dashboardEmptyCtaLabel))`.
16.2. The `onCheckListPressed` callback is wired in `DashboardScreen` to `StatefulNavigationShell.of(context)!.goBranch(0)`.

## 17. Screen composition — `DashboardScreen`

17.1. Open `app/lib/features/dashboard/presentation/dashboard_screen.dart` and replace the placeholder. The screen:
   - `ConsumerWidget`.
   - At the top of `build`, read `MaterialLocalizations.of(context).firstDayOfWeekIndex` and use a `ProviderScope` override to push it into `dashboardFirstDayOfWeekProvider` for the subtree:
     ```dart
     return ProviderScope(
       overrides: [
         dashboardFirstDayOfWeekProvider.overrideWithValue(MaterialLocalizations.of(context).firstDayOfWeekIndex),
       ],
       child: const _DashboardBody(),
     );
     ```
   - `_DashboardBody` is a `ConsumerWidget` that reads `dashboardDataProvider` and renders accordingly.
17.2. AppBar: title is `l.dashboardTitle`. No actions.
17.3. Body branches on `dashboardDataProvider`:
   - `AsyncLoading` → `ListView` of three `DashboardSectionCard`s, each with a `SizedBox` of the right height containing a `surfaceContainerHighest`-filled box.
   - `AsyncError(e, _)` → `Center(child: Column(children: [Icon(Icons.error_outline_rounded), Text(l.dashboardErrorLabel), TextButton(onPressed: () => ref.invalidate(dashboardWindowProvider), child: Text(l.dashboardRetryLabel))]))`.
   - `AsyncData(data)`:
     - If `data.daysWithAnyActivity == 0`, render `DashboardEmptyState`.
     - Else render a `ListView` (not `CustomScrollView` — three fixed cards) with:
       1. `DashboardRangePicker` (not inside a card, sits between AppBar and the first card).
       2. `DashboardSectionCard(title: l.dashboardWeeklyBarsTitle, child: WeeklyBarsChart(bars: data.bars, range: data.range, locale: Localizations.localeOf(context)))`.
       3. `DashboardSectionCard(title: l.dashboardHeatmapTitle, child: HeatmapChart(cells: data.heatmap))`.
       4. `DashboardSectionCard(title: l.dashboardCategoriesTitle, trailing: const CategoryChartTypeSwitcher(), child: CategoryBreakdown(categories: data.categories))`.

## 18. Localization — fill all new ARB keys (EN)

18.1. Open `app/l10n/app_en.arb`. Confirm all keys from `requirements.md` §3.11 are present in English. The keys added in §4.3 (nav), §9.2 (range), and §15.1 (chart-type tooltips) should already exist; this group adds the rest:
   - `dashboardTitle`, `dashboardWeeklyBarsTitle`, `dashboardHeatmapTitle`, `dashboardCategoriesTitle`.
   - `dashboardEmptyTitle`, `dashboardEmptyBody`, `dashboardEmptyCtaLabel`.
   - `dashboardErrorLabel`, `dashboardRetryLabel`.
   - `categoryNameFajr` … `categoryNameMiscAdhkar` (8 keys).
   - `dashboardBarA11y(date, percent, fardState)`, `dashboardHeatmapCellA11y(date, percent, fardState)`, `dashboardCategoryA11y(category, percent)` with their `placeholders` metadata.
18.2. From `/app`: `flutter pub get` — re-runs `gen-l10n`. Confirm `AppLocalizations.dashboardEmptyBody` etc. resolve in the IDE.

## 19. Localization — Arabic placeholders

19.1. Open `app/l10n/app_ar.arb`. For every key added in group 18 (and groups 4 / 9 / 15 if not yet present), add a `"TODO: …"` value alongside identical `@key.placeholders` metadata.
19.2. Use Western digits for plural counts in TODO placeholders unless Phase 1 D13 has been explicitly lifted.

## 20. Lints, format, RTL guard, source-of-truth guard

20.1. From `/app`: `dart format .` — must produce a clean diff on the second run.
20.2. From `/app`: `flutter analyze` — must report `No issues found!`.
20.3. From `/app`: `dart format --output=none --set-exit-if-changed .` — must exit 0.
20.4. **RTL guard**: `rg "EdgeInsets\.only\(left|right" app/lib/features/dashboard/ app/lib/features/shell/` and `rg "Alignment\.(centerLeft|centerRight)" app/lib/features/dashboard/ app/lib/features/shell/` must return **zero** hits.
20.5. **`kMaxHistoryDays` single-source-of-truth guard**: `rg "kMaxHistoryDays" app/lib/` should yield a single declaration in `checklist_repositories_provider.dart` and ≤ 5 import sites (`active_day_notifier`, `streak_window_provider`, `dashboard_window_provider`, `streak_pills`, plus the test files).
20.6. **No raw hex colors guard**: `rg "Color\(0x" app/lib/features/dashboard/` must return zero hits. All palette comes from `ColorScheme`.

## 21. Manual verification on Web

21.1. From `/app`: `flutter run -d chrome --web-header=Cross-Origin-Embedder-Policy=require-corp --web-header=Cross-Origin-Opener-Policy=same-origin`.
21.2. **Cold launch on a fresh DB**: confirm the Dashboard tab renders the empty state with the CTA, not a chart with all-zero bars.
21.3. Tap the empty-state CTA → bottom nav switches to Checklist tab; Checklist screen retains its scroll position (verify by scrolling Checklist, switching tabs, tapping CTA — the position holds).
21.4. **Populate data**: from the Checklist tab, complete a varied mix of tasks for today and yesterday. Switch to Dashboard.
   - The empty state is gone; all three section cards render.
   - Range picker shows `Week` selected.
   - Bar chart shows 7 bars; today's bar reflects today's %.
   - Heatmap shows 7 cells with appropriate color bins; today has the tertiary ring if fard-met.
   - Category breakdown defaults to horizontal bars; each category shows the current period's %.
21.5. **Range picker switches**:
   - Tap `Month`. The window expands; bar chart now shows 30 bars; heatmap shows 30 cells; category percentages re-aggregate.
   - Tap `90 days`. Bar chart shows 13 weekly buckets; heatmap shows 90 cells in a 7-row grid.
21.6. **Heatmap tap**:
   - Tap today's cell → bottom nav switches to Checklist tab; Checklist's `activeDay` is today; rows are editable.
   - Tap yesterday's cell → switches to Checklist; `activeDay` is yesterday; rows are editable (Phase 3 D2).
   - Tap a cell 5 days back → switches to Checklist; `activeDay` is day -5; rows are read-only with the Phase 2 pill.
21.7. **Chart-type switcher**:
   - Tap each of the four icon segments in turn. Confirm the category section's child swaps without flicker. Horizontal bars → Radar → Stacked → Donut.
   - Confirm each chart type renders correctly for a non-trivial data fingerprint (e.g., 100% Fajr, 0% Maghrib).
21.8. **Locale toggle (Arabic)**:
   - Tap the AR language toggle on the Checklist AppBar. Switch back to Dashboard.
   - Bottom nav labels show TODO copy.
   - Range picker labels show TODO copy.
   - Section card titles show TODO copy.
   - Heatmap row ordering flips (top row is still the locale's first day of week; column visual order reverses via `Directionality`).
   - Bar chart X-axis labels show Arabic short weekday names.
   - Category names show TODO copy.
21.9. **Midnight rollover with Dashboard tab in foreground**: set OS clock to 23:59:50. Confirm at 00:00:
   - Heatmap cells slide (today's old cell becomes day -1; a new empty cell appears as today).
   - Bar chart updates accordingly.
   - Streak qualifier on the Checklist tab (verified separately) now reads `(last 90 days)`.
21.10. **Frame-time check** (`flutter run --profile`): switch range from `Week` → `90 days` and back several times. The Performance Overlay should not show frames above 16 ms during the range transition.

## 22. (Optional) Mobile spot-check

22.1. If an Android emulator is available: `flutter run -d <android-emulator-id>`. Repeat §21.2, §21.4, §21.6, §21.7.
22.2. Verify the bottom nav bar respects the safe area on a notched device — `NavigationBar` does this automatically; confirm visually.

## 23. Pre-merge — fill Arabic translations

23.1. Open `app/l10n/app_ar.arb`. For every new key added this phase, replace the `TODO: …` placeholder with the reviewed final Arabic translation.
23.2. Also re-translate the modified `streakLongestWindowQualifier` with its new `{days}` placeholder.
23.3. From `/app`: `rg "TODO:" app/l10n/app_ar.arb` — must return **zero** matches.
23.4. Re-run group 20 (analyze + format) and §21.8 (Arabic smoke).

## 24. CI

24.1. The existing `app-lint` job runs `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, and `flutter analyze`. **No workflow changes** required for the analyzer.
24.2. The two new tests (groups 8 and 10) run under the existing `flutter test` invocation. If `app-test` does not yet exist in `.github/workflows/`, add a small job that runs `flutter test` from `/app` in the same matrix as `app-lint`. (Phase 3 §20.2 budgeted this; if it landed there, no action; if it didn't, do it here.)
24.3. Confirm `api-lint` is still green — Phase 4 doesn't touch `/api`.

## 25. Wrap-up & handoff

25.1. Re-read `validation.md`; tick every acceptance check.
25.2. Update root `README.md` "Status" line to `Phase 4 ✅ — dashboard with weekly bars, heatmap, category breakdown (EN + AR, 4-way category chart switcher)`.
25.3. Add a "Specs" reference for this folder in `README.md` alongside Phase 0 / 1 / 2 / 3.
25.4. Open PR `feature/phase-4-dashboard-and-charts → master`; paste a link to `specs/phase-4-2026-05-13-dashboard-and-charts/` in the description.
25.5. **PR description must call out** the Phase 3 V10 supersession (validation.md V10') so reviewers know the qualifier copy intentionally changed.
25.6. **Flag for the Phase 5 plan:** the bottom nav shell has a place for a third destination (`/notifications` or `/settings`). The `NavigationBar` is the place to wire it; no shell refactor required.
25.7. **Flag for the Phase 6 plan:** if cloud sync introduces a longer retention than 90 days, the `streakLongestWindowQualifier({days})` already accommodates it. The `kMaxHistoryDays` constant becomes a settings-driven value at that point.
25.8. Squash-merge once CI is green and `validation.md` checks pass (including the zero-TODO gate from §23.3).
