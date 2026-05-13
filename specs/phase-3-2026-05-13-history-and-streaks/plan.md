# Phase 3 — History & Streaks · Plan

> Numbered task groups. Each group is self-contained and ordered for least-rework. Adjacent groups may be collapsed into one commit, but ordering should be preserved. Budget: **3 days** per `spec/roadmap.md`.

---

## 1. Branch & sanity

1.1. Confirm you are on `feature/phase-3-history-and-streaks` (branched off `master` after the Phase 2 merge `6894b42`).
1.2. From `/app`: `flutter pub get` then `flutter analyze` — must report `No issues found!` before any code lands. Regression check that Phase 2's committed state is clean.
1.3. From `/app`: `flutter test` — confirm `test/data/drift_checklist_repository_test.dart` and `test/widget_test.dart` both still pass (Phase 2's mandatory test must stay green).
1.4. No `pubspec.yaml` changes this phase. Confirm by `git diff master -- app/pubspec.yaml app/pubspec.lock` → empty. Validation V20 will re-check this at the end.

## 2. Localization keys (do this first so codegen runs once)

2.1. Open `app/l10n/app_en.arb`. Append the **7 new keys** from `requirements.md` §3.10 with their English values + `@`-metadata blocks. Keep the existing trailing key (`loadingChecklist`) and add new keys after it, **inside** the outermost `{...}`.
2.2. The plural keys (`streakCurrentLabel`, `streakLongestLabel`) need explicit ICU metadata:
   ```json
   "streakCurrentLabel": "Current: {count} {count, plural, one{day} other{days}}",
   "@streakCurrentLabel": {
     "placeholders": { "count": { "type": "int" } }
   },
   ```
2.3. The placeholder-heavy a11y key:
   ```json
   "historyStripCellA11y": "{date}, {percent} percent complete, {fardState}",
   "@historyStripCellA11y": {
     "placeholders": {
       "date":      { "type": "String" },
       "percent":   { "type": "int" },
       "fardState": { "type": "String" }
     }
   },
   ```
2.4. Open `app/l10n/app_ar.arb`. Append the **same 7 keys** with `TODO: …` placeholder values (e.g., `"streakCurrentLabel": "TODO: الحالي: {count} يوم"`). Keep the placeholder declarations identical so the generated Dart compiles.
2.5. From `/app`: `flutter pub get` — triggers `gen-l10n`. Confirm in the IDE that `AppLocalizations.historyStripCellA11y`, `streakCurrentLabel`, etc., resolve. **Do not** fill the Arabic values yet — that's a pre-merge gate (group 14).

## 3. Domain: fard anchor set

3.1. Create `app/lib/features/checklist/domain/fard_anchor_set.dart`:
   ```dart
   const Set<String> fardAnchorTaskIds = <String>{
     'fajr_first_congregation',
     'dhuhr_first_congregation',
     'asr_first_congregation',
     'maghrib_first_congregation',
     'isha_first_congregation',
     'quran_read_six_quarters',
   };

   const int fardAnchorPointsTotal = 12; // sum of catalog points across the anchor set
   ```
3.2. Add a debug assert at the catalog level: open `app/lib/features/checklist/data/static_task_catalog.dart` and, **below** the `staticTaskCatalog` list, add:
   ```dart
   void assertFardAnchorIntegrity() {
     assert(() {
       final ids = staticTaskCatalog.map((t) => t.id).toSet();
       for (final f in fardAnchorTaskIds) {
         if (!ids.contains(f)) {
           throw StateError('fardAnchorTaskIds contains $f but catalog lacks it');
         }
       }
       final pts = staticTaskCatalog
           .where((t) => fardAnchorTaskIds.contains(t.id))
           .fold<int>(0, (s, t) => s + t.points);
       if (pts != fardAnchorPointsTotal) {
         throw StateError('fard anchor points drifted: got $pts, expected $fardAnchorPointsTotal');
       }
       return true;
     }());
   }
   ```
   Import the new file at the top of `static_task_catalog.dart`.
3.3. Call `assertFardAnchorIntegrity()` from `AppDatabase.seedAndReconcile()` **after** the existing 74-point assert — keep both in the same `assert((){...}())` envelope to ensure debug-only.

## 4. Domain: `DayCompletion` + `Streak`

4.1. Create `app/lib/features/checklist/domain/day_completion.dart`:
   ```dart
   import '../../../core/time/day_key.dart';

   class DayCompletion {
     const DayCompletion({
       required this.day,
       required this.completedPoints,
       required this.totalPoints,
       required this.completedTasks,
       required this.totalTasks,
       required this.fardMet,
     });

     final DayKey day;
     final int completedPoints;
     final int totalPoints;
     final int completedTasks;
     final int totalTasks;
     final bool fardMet;

     double get fraction => totalPoints == 0 ? 0.0 : completedPoints / totalPoints;
     int get percentInt => (fraction * 100).round();

     @override
     bool operator ==(Object other) =>
         other is DayCompletion &&
         other.day == day &&
         other.completedPoints == completedPoints &&
         other.totalPoints == totalPoints &&
         other.completedTasks == completedTasks &&
         other.totalTasks == totalTasks &&
         other.fardMet == fardMet;

     @override
     int get hashCode => Object.hash(day, completedPoints, totalPoints, completedTasks, totalTasks, fardMet);
   }
   ```
   `==` / `hashCode` are mandatory — Riverpod's `StreamProvider` uses them to suppress duplicate emissions (R6 in requirements).

4.2. Create `app/lib/features/checklist/domain/streak.dart`:
   ```dart
   class Streak {
     const Streak({required this.current, required this.longest, required this.windowDays});
     final int current;
     final int longest;
     final int windowDays;
   }
   ```

## 5. Domain: `StreakCalculator` (pure-Dart math)

5.1. Create `app/lib/features/checklist/domain/streak_calculator.dart`:
   ```dart
   import '../../../core/time/day_key.dart';
   import 'day_completion.dart';
   import 'streak.dart';

   class StreakCalculator {
     const StreakCalculator();

     Streak compute(List<DayCompletion> days, {required DayKey today}) {
       if (days.isEmpty) return const Streak(current: 0, longest: 0, windowDays: 0);

       final sorted = [...days]..sort((a, b) => a.day.compareTo(b.day));
       final byKey = {for (final d in sorted) d.day: d};

       int longest = 0;
       int run = 0;
       for (final d in sorted) {
         if (d.fardMet) {
           run += 1;
           if (run > longest) longest = run;
         } else {
           run = 0;
         }
       }

       int current = 0;
       DayKey anchor;
       final todayDC = byKey[today];
       final yesterdayDC = byKey[today.previousDay()];
       if (todayDC?.fardMet == true) {
         anchor = today;
       } else if (yesterdayDC?.fardMet == true) {
         anchor = today.previousDay();
       } else {
         return Streak(current: 0, longest: longest, windowDays: sorted.length);
       }

       var cursor = anchor;
       while (byKey[cursor]?.fardMet == true) {
         current += 1;
         cursor = cursor.previousDay();
       }

       return Streak(current: current, longest: longest, windowDays: sorted.length);
     }
   }
   ```
5.2. Note: `DayKey.compareTo` already exists per Phase 2; if not, audit `app/lib/core/time/day_key.dart` and add it (`int compareTo(DayKey o)` deferring to `toIsoDate()` lexicographic comparison since `YYYY-MM-DD` sorts correctly).

## 6. Data: `HistoryRepository`

6.1. Create `app/lib/features/checklist/data/history_repository.dart`:
   ```dart
   import '../../../core/time/day_key.dart';
   import '../domain/day_completion.dart';

   abstract class HistoryRepository {
     Future<List<DayCompletion>> readRange(DayKey start, DayKey end);
     Stream<List<DayCompletion>> watchRange(DayKey start, DayKey end);
   }
   ```

6.2. Create `app/lib/features/checklist/data/drift_history_repository.dart`:
   ```dart
   import 'package:drift/drift.dart';

   import '../../../core/db/app_database.dart';
   import '../../../core/time/day_key.dart';
   import '../domain/day_completion.dart';
   import '../domain/fard_anchor_set.dart';
   import 'static_task_catalog.dart';
   import 'history_repository.dart';

   class DriftHistoryRepository implements HistoryRepository {
     DriftHistoryRepository(this._db);
     final AppDatabase _db;

     @override
     Future<List<DayCompletion>> readRange(DayKey start, DayKey end) async {
       final rows = await (_db.select(_db.dailyLogs)
             ..where((r) => r.date.isBetweenValues(start.toIsoDate(), end.toIsoDate()))
             ..where((r) => r.completed.equals(true)))
           .get();
       return _summarize(rows, start, end);
     }

     @override
     Stream<List<DayCompletion>> watchRange(DayKey start, DayKey end) {
       return (_db.select(_db.dailyLogs)
             ..where((r) => r.date.isBetweenValues(start.toIsoDate(), end.toIsoDate()))
             ..where((r) => r.completed.equals(true)))
           .watch()
           .map((rows) => _summarize(rows, start, end));
     }

     // _summarize: groups rows by date, joins against staticTaskCatalog by id (skipping ids absent from catalog),
     // builds one DayCompletion per calendar day in [start, end] inclusive.
   }
   ```
6.3. Implement `_summarize`:
   - Build `catalogById = {for (t in staticTaskCatalog) t.id: t}`.
   - Group rows by `r.date` into `Map<String, List<DailyLog>>`.
   - For each day in `[start, end]` inclusive (use `DayKey.daysSince` for the loop):
     - `final logs = byDate[day.toIsoDate()] ?? const [];`
     - Filter to those with `catalogById.containsKey(log.taskId)` (Phase 2 D7 — orphans don't count).
     - `completedPoints = filtered.fold(0, (s, l) => s + catalogById[l.taskId]!.points)`.
     - `completedTasks = filtered.length`.
     - `fardMet = fardAnchorTaskIds.every((id) => filtered.any((l) => l.taskId == id))`.
     - `totalPoints = staticTaskCatalog.fold(0, (s, t) => s + t.points)` (constant 74; precompute once outside the loop).
     - `totalTasks = staticTaskCatalog.length` (constant 34; same).
   - Return list ordered oldest → newest.

6.4. Style: keep the SQL **simple** (one query, one `.where(...)`). Avoid `GROUP BY` — Drift's typed-query DSL doesn't model it cleanly for our case, and doing the grouping in Dart is trivial at this volume (≤ 30 days × 34 tasks = 1020 rows worst case).

## 7. Mandatory test 1 — `streak_calculator_test.dart`

7.1. Create `app/test/domain/streak_calculator_test.dart`:
   - Import `flutter_test`, the calculator, `DayCompletion`, `DayKey`.
   - Helper `DayCompletion _dc(DayKey d, {required bool fardMet, double fraction = 0.5})`:
     - Builds a `DayCompletion` with `completedPoints = (74 * fraction).round()`, `totalPoints = 74`, etc., overriding only `fardMet`.
   - Test cases (matching `requirements.md` §3.12 list verbatim):
     1. Empty → `current = 0, longest = 0`.
     2. 3 fard-met days ending today → `current = 3, longest = 3`.
     3. 5 fard-met days ending yesterday, today empty → `current = 5, longest = 5` (grace).
     4. 2 fard, gap of 1, 4 fard ending today → `current = 4, longest = 4`.
     5. 7 fard days, **not** today and **not** yesterday → `current = 0, longest = 7`.
     6. Partial day (75% fraction but `fardMet = false`) → `current = 0`.
7.2. From `/app`: `flutter test test/domain/streak_calculator_test.dart` — must pass.

## 8. Mandatory test 2 — `drift_history_repository_test.dart`

8.1. Create `app/test/data/drift_history_repository_test.dart`:
   - Spin up `AppDatabase(NativeDatabase.memory())`.
   - Call `db.seedAndReconcile()` so `tasks` is populated.
   - Insert into `daily_logs` for:
     - `2026-05-08`: all 6 fard anchor ids + 2 non-fard ids → `fardMet = true`, `completedPoints = 12 + 4 = 16`.
     - `2026-05-10`: 3 fard anchor ids only → `fardMet = false` (set incomplete), `completedPoints = 6`.
     - `2026-05-12`: 4 non-fard ids only → `fardMet = false`, `completedPoints = 8`.
   - Call `readRange(DayKey(2026,5,7), DayKey(2026,5,13))` and assert:
     - Length is exactly **7**.
     - Dates in order: 5-07, 5-08, 5-09, 5-10, 5-11, 5-12, 5-13.
     - 5-07, 5-09, 5-11, 5-13 → `fardMet = false`, `completedPoints = 0`, `completedTasks = 0`.
     - 5-08 → `fardMet = true`, `completedPoints = 16`, `completedTasks = 8`.
     - 5-10 → `fardMet = false`, `completedPoints = 6`.
     - 5-12 → `fardMet = false`, `completedPoints = 8`.
   - `watchRange` smoke: subscribe to `watchRange(..., ...)`, capture first emission, insert a new row in the range, capture second emission, assert the count differs.
8.2. From `/app`: `flutter test test/data/drift_history_repository_test.dart` — must pass.

## 9. Providers — calendar today + history + streak

9.1. Create `app/lib/features/checklist/presentation/providers/calendar_today_provider.dart`:
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import '../../../../core/time/day_key.dart';

   class CalendarTodayNotifier extends Notifier<DayKey> {
     @override
     DayKey build() => DayKey.today();
     void rebase(DayKey newToday) { state = newToday; }
   }

   final calendarTodayProvider =
       NotifierProvider<CalendarTodayNotifier, DayKey>(CalendarTodayNotifier.new);
   ```

9.2. Wire the midnight ticker. Open the place where `MidnightTickerService.start(...)` is wired (per Phase 2, this is the top-level shell in `main.dart`). In its callback, **also** call `ref.read(calendarTodayProvider.notifier).rebase(newToday)` — **before** the existing `activeDayProvider.goToDay(newToday)` call to ensure the strip/streak providers see the new "today" by the time the active day shifts. (If Phase 2 inlined the callback in a closure that didn't have `ref`, refactor to a `ConsumerStatefulWidget` that holds the ref.)

9.3. Create `app/lib/features/checklist/presentation/providers/history_repository_provider.dart`:
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import '../../../../core/db/app_database_provider.dart';
   import '../../data/drift_history_repository.dart';
   import '../../data/history_repository.dart';

   final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
     return DriftHistoryRepository(ref.watch(appDatabaseProvider));
   });
   ```

9.4. Create `app/lib/features/checklist/presentation/providers/history_strip_window_provider.dart`:
   - `final kHistoryStripDays = 7;` (top of file, exported).
   - `StreamProvider.autoDispose<List<DayCompletion>>` that:
     - `final today = ref.watch(calendarTodayProvider);`
     - `final start = _addDays(today, -(kHistoryStripDays - 1));` (helper using `DayKey.previousDay()` in a loop, mirroring `DayPickerBar._oldestAllowed`).
     - `return ref.read(historyRepositoryProvider).watchRange(start, today);`

9.5. Create `app/lib/features/checklist/presentation/providers/streak_window_provider.dart`:
   - Same shape but uses `kMaxHistoryDays` (already exported from `checklist_repositories_provider.dart`) so the streak math sees up to 30 days.

9.6. Create `app/lib/features/checklist/presentation/providers/streak_provider.dart`:
   ```dart
   final streakProvider = Provider<AsyncValue<Streak>>((ref) {
     final today = ref.watch(calendarTodayProvider);
     final daysAsync = ref.watch(streakWindowProvider);
     return daysAsync.whenData((days) =>
         const StreakCalculator().compute(days, today: today));
   });
   ```

## 10. Provider tweaks — editable yesterday

10.1. Open `app/lib/features/checklist/presentation/providers/checklist_repositories_provider.dart`. Add **next to** `kMaxHistoryDays`:
   ```dart
   const kMaxEditableDays = 2; // today + yesterday
   ```
10.2. In `ChecklistController.toggle`:
   ```dart
   Future<void> toggle(String taskId) async {
     final day = _ref.read(activeDayProvider);
     final today = DayKey.today();
     final daysAgo = today.daysSince(day); // 0 for today, 1 for yesterday, ≥2 for older
     if (daysAgo < 0 || daysAgo >= kMaxEditableDays) {
       return; // future or too-old → no-op
     }
     final repo = _ref.read(checklistRepositoryProvider);
     final current = await repo.readDay(day);
     final next = !(current[taskId] ?? false);
     await repo.setCompletion(day: day, taskId: taskId, completed: next);
   }
   ```
   Replace the existing single-day guard.
10.3. In `ChecklistController.resetToday` — **rename** to `resetActiveDay()` and target `activeDay` rather than hard-coded today:
   ```dart
   Future<void> resetActiveDay() async {
     final day = _ref.read(activeDayProvider);
     final today = DayKey.today();
     final daysAgo = today.daysSince(day);
     if (daysAgo < 0 || daysAgo >= kMaxEditableDays) return;
     await _ref.read(checklistRepositoryProvider).resetDay(day);
   }
   ```
   Keep an alias `Future<void> resetToday() => resetActiveDay();` if any caller still uses the old name (e.g., a test) — but search and rewire all callers to `resetActiveDay()`.

## 11. UI — `TaskRow` editable on yesterday

11.1. Open `app/lib/features/checklist/presentation/widgets/task_row.dart`. Replace:
   ```dart
   final readOnly = activeDay != today;
   ```
   with:
   ```dart
   final daysAgo = today.daysSince(activeDay);
   final readOnly = daysAgo < 0 || daysAgo >= 2; // V12: kMaxEditableDays bound
   ```
   *(Use a literal `2` here to avoid a circular import on `kMaxEditableDays`; the constant is the source of truth in the controller, and a comment links them.)*
11.2. Confirm the existing semantics + dimming logic still composes — no further changes needed; the `readOnly` flag flows through unchanged.

## 12. UI — `checklist_progress_header` read-only pill + long-press

12.1. Open `app/lib/features/checklist/presentation/widgets/checklist_progress_header.dart`.
12.2. Replace the `isToday`-based pill gate with:
   ```dart
   final daysAgo = today.daysSince(activeDay);
   final isReadOnly = daysAgo >= 2;
   final isEditable = daysAgo >= 0 && daysAgo < 2;
   ```
12.3. The read-only pill renders when `isReadOnly == true` (was `!isToday`).
12.4. The long-press handler attaches when `isEditable == true` (was `isToday`). Its `onLongPress` calls `ref.read(checklistControllerProvider).resetActiveDay()` (was `resetToday()`).
12.5. The dialog body copy is **unchanged**; the dialog acts on `activeDay`, which is correct because the controller targets it. No ARB-string changes needed.

## 13. UI — History strip widget

13.1. Create `app/lib/features/checklist/presentation/widgets/history_strip.dart` — a `ConsumerWidget`.
13.2. Watch:
   - `final daysAsync = ref.watch(historyStripWindowProvider);`
   - `final activeDay = ref.watch(activeDayProvider);`
   - `final today = ref.watch(calendarTodayProvider);`
   - `final l = AppLocalizations.of(context)!;`
   - `final locale = Localizations.localeOf(context);`
   - `final scheme = Theme.of(context).colorScheme;`
13.3. `daysAsync.when(...)`:
   - **loading / error / empty** → render a 7-cell shimmer of `surfaceVariant` boxes (no fard ring, no labels) so layout doesn't jump.
   - **data** → continue.
13.4. Build the row of 7 cells. The data list is ordered oldest → newest; render in that order so `Directionality` flips it correctly for RTL (R8).
13.5. Per-cell helper widget `_HistoryCell` taking `(DayCompletion dc, bool isToday, bool isActive)`:
   - Bin → background color via a private `_binColorFor(double fraction, ColorScheme s)` switch.
   - If `isActive`, override background with `scheme.primaryContainer`.
   - If `dc.fardMet`, wrap in a `Container(decoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(8), border: Border.all(color: scheme.tertiary, width: 2)))`.
   - If `isToday` and **not** `dc.fardMet`, use a thinner `scheme.outline` border (1 px) for emphasis. If both `isToday` and `fardMet`, prefer the tertiary fard ring — fard wins.
   - Below the cell: `Text(_dayLetter(dc.day, locale))` — see step 13.6 — in `textTheme.labelSmall` with `colorScheme.onSurfaceVariant`.
   - Wrap the cell + label in a single `InkWell(onTap: () => ref.read(activeDayProvider.notifier).goToDay(dc.day))` with `borderRadius: BorderRadius.circular(8)`.
   - Add `Semantics(label: l.historyStripCellA11y(_a11yDate(dc.day, locale), dc.percentInt, dc.fardMet ? l.historyStripFardComplete : l.historyStripFardIncomplete), button: true, excludeSemantics: true, child: ...)`.
13.6. Helpers:
   - `_dayLetter(DayKey d, Locale locale) => DateFormat.E(locale.toLanguageTag()).format(d.toLocalDateTime()).characters.first;`
   - `_a11yDate(DayKey d, Locale locale) => DateFormat.yMMMMEEEEd(locale.toLanguageTag()).format(d.toLocalDateTime());`
13.7. Outer layout:
   ```dart
   return Padding(
     padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 8),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [for (final dc in days) Expanded(child: _HistoryCell(...))],
     ),
   );
   ```
   `Expanded` ensures the 7 cells share width equally regardless of font scaling.

## 14. UI — Streak pills widget

14.1. Create `app/lib/features/checklist/presentation/widgets/streak_pills.dart` — a `ConsumerWidget`.
14.2. Read `final streakAsync = ref.watch(streakProvider);` and the localizations.
14.3. Render:
   - `loading / error` → a single `SizedBox.shrink()` (pills are non-essential; don't show skeletons here, the strip's skeleton already telegraphs loading).
   - `data` → `Row(children: [_Pill(current), const SizedBox(width: 8), _Pill(longest)])`.
14.4. `_Pill` is a private widget building a `Container` with `colorScheme.secondaryContainer` background, 999 radius, soft padding (8h × 6v), an `Icon` (flame for current, `Icons.workspace_premium_rounded` for longest), and the localized label.
14.5. Current pill label logic:
   - If `streak.current == 0`, render `l.streakCurrentEmpty`.
   - Else `l.streakCurrentLabel(streak.current)`.
14.6. Longest pill label logic:
   - `final base = l.streakLongestLabel(streak.longest);`
   - If `streak.longest >= streak.windowDays && streak.windowDays >= kMaxHistoryDays`, append `' ${l.streakLongestWindowQualifier}'` (i.e., the user has hit the data-window cap; honesty qualifier per D5).
14.7. Wrap the whole `Row` in a `Padding(padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12), child: ...)` so it lines up with the progress header.

## 15. Screen composition

15.1. Open `app/lib/features/checklist/presentation/checklist_screen.dart`.
15.2. Insert two new slivers in the existing `CustomScrollView`:
   - After `SliverToBoxAdapter(child: DayPickerBar())`:
     - `const SliverToBoxAdapter(child: HistoryStrip()),`
   - After `SliverToBoxAdapter(child: ChecklistProgressHeader())`:
     - `const SliverToBoxAdapter(child: StreakPills()),`
15.3. Final sliver order:
   1. `DayPickerBar`
   2. `HistoryStrip` *(new)*
   3. `ChecklistProgressHeader`
   4. `StreakPills` *(new)*
   5. Category sections
   6. Bottom inset padding

## 16. Lints, format, RTL guard, source-of-truth guard

16.1. From `/app`: `dart format .` — must produce a clean diff on the second run.
16.2. From `/app`: `flutter analyze` — must report `No issues found!`.
16.3. From `/app`: `dart format --output=none --set-exit-if-changed .` — must exit 0.
16.4. **RTL guard** (same as Phase 1/2): `rg "EdgeInsets\.only\(left|right" app/lib/features/checklist/ app/lib/core/` and `rg "Alignment\.(centerLeft|centerRight)" app/lib/features/checklist/ app/lib/core/` must return **zero** hits in new code. (Phase 2 already enforces this; re-run to verify no regression.)
16.5. **`kMaxEditableDays` single-source-of-truth guard**: `rg "kMaxEditableDays" app/lib/` should yield a single declaration in `checklist_repositories_provider.dart`. The literal `2` in `task_row.dart` (step 11.1) is documented as a deliberate exception with an inline comment referencing the canonical constant.
16.6. **`fardAnchorTaskIds` single-source-of-truth guard**: `rg "fardAnchorTaskIds" app/lib/ app/test/` should show one `const` declaration (`fard_anchor_set.dart`) and ≤ 3 import sites (`drift_history_repository.dart`, `static_task_catalog.dart`, test files). No string literals duplicating the IDs.

## 17. Manual verification on Web

17.1. From `/app`: `flutter run -d chrome --web-header=Cross-Origin-Embedder-Policy=require-corp --web-header=Cross-Origin-Opener-Policy=same-origin`.
17.2. **Cold launch**: confirm the home screen renders all four new layers (picker, strip, header, pills) without flicker. Phase 2's `loadingChecklist` may still appear briefly on first frame.
17.3. **Strip cell tap**: tap the 4th cell from the right (= `today - 3`). Confirm:
   - The active-day label in `DayPickerBar` updates to that calendar date.
   - The tapped cell visually swaps to the `primaryContainer` highlight; the previous active highlight clears.
   - The checklist body shows that day's rows (likely empty or partial) **read-only** with the Phase 2 pill.
17.4. **Yesterday is editable**: tap the 2nd cell from the right (= yesterday). Confirm:
   - Cell becomes active-highlighted.
   - The Phase 2 read-only pill is **absent**.
   - Tapping a task row toggles its checkbox; the strip's yesterday-cell color rebins in real time (Drift `.watch()` → provider → widget).
   - The long-press reset dialog opens; confirming "Reset" wipes yesterday's `daily_logs`; the strip cell drops to bin 0 immediately.
17.5. **Older days are read-only**: tap the leftmost cell (= `today - 6`). Confirm:
   - Cell active-highlights.
   - Read-only pill **shows** on the progress header.
   - Tapping a task row does nothing.
   - Long-press the header — dialog does **not** open.
17.6. **Streak counters with a known fingerprint**: from a clean DB, complete all 6 fard tasks today. Confirm:
   - Today's strip cell gets the `tertiary` fard ring.
   - Current streak pill reads `Current: 1 day` (singular form via ICU `plural`).
   - Longest streak pill reads `Best: 1 day`.
   - Now navigate to yesterday and complete all 6 fard tasks. Confirm:
     - Yesterday's strip cell gains the ring.
     - Current streak rebases to `2 days` (plural).
     - Longest matches `2 days`.
17.7. **Grace window check**: with a 3-day fard streak ending today (synthetic via repeated visits / edits), uncheck **one** fard task today. Confirm:
   - Today's strip ring **disappears**.
   - Current streak pill drops to `2 days` (yesterday-anchored grace) — **not** `0`.
   - Re-check the fard task → current snaps back to `3 days`.
17.8. **Strip empty cells**: cells before the first day with `daily_logs` rows render as bin 0 (surfaceVariant). This is the documented D14 ambiguity — record a screenshot in the PR description so reviewers can sanity-check the visual.
17.9. **Locale**: switch to AR via the AppBar toggle. Confirm:
   - Strip cells reorder so today is on the **left** (RTL logical end).
   - Day letters use Arabic abbreviations (`ث`, `ر`, etc., per `intl`).
   - Pill labels show TODO copy (expected before the V19 gate clears).
   - Read-only pill (on older days) shows TODO copy.
17.10. **Midnight rollover** (simulated): set the OS clock 20 seconds before local midnight while viewing **today** with one fard task done. Wait. Confirm:
   - At 00:00, the strip's right-most cell shifts: yesterday's record (the partial day) moves one slot left; today's new cell is empty (bin 0).
   - The streak pill recomputes — current likely drops if the partial day didn't complete fard.
   - The active-day highlight follows to the new today's cell (Phase 2's `MidnightTickerService` already snaps).

## 18. (Optional) Mobile spot-check

18.1. If an Android emulator is available: `flutter run -d <android-emulator-id>`. Repeat §17.2 / §17.4 / §17.6.
18.2. Verify haptics on toggle still fire for yesterday's edits (the `HapticFeedback.selectionClick()` in `task_row.dart` is unguarded; it should ride along with the new editable-window).

## 19. Pre-merge: fill Arabic translations

19.1. Open `app/l10n/app_ar.arb`. For each of the **7** new keys (and any prior pending), replace `TODO: …` with the reviewed final Arabic translation. Use Arabic numerals (٠–٩) only if Phase 1 D13 has been lifted — otherwise stick with Western digits for plural counts.
19.2. From `/app`: `rg "TODO:" l10n/app_ar.arb` — must return **zero matches**.
19.3. Re-run group 16 (analyze + format) and §17.9 (Arabic smoke).

## 20. CI

20.1. The existing `app-lint` job runs `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, and `flutter analyze`. **No workflow changes** required for Phase 3.
20.2. The two new tests (groups 7 and 8) run under the existing `flutter test` invocation if `app-test` is wired. If `app-test` does not yet exist in `.github/workflows/`, add a small job that runs `flutter test` from `/app` in the same matrix as `app-lint`. (This is the half-day budgeted in Phase 2 R6 to add a real test job — Phase 3 is a justified place for it because we now have non-trivial tests.)
20.3. Confirm `api-lint` is still green — Phase 3 doesn't touch `/api`.

## 21. Wrap-up & handoff

21.1. Re-read `validation.md`; tick every acceptance check.
21.2. Update root `README.md` "Status" line to `Phase 3 ✅ — history strip + streaks (EN + AR, today/yesterday editable)`.
21.3. Add a "Specs" reference for this folder in `README.md` alongside Phase 0 / 1 / 2.
21.4. Open PR `feature/phase-3-history-and-streaks → master`; paste a link to `specs/phase-3-2026-05-13-history-and-streaks/` in the description; reference Phase 4 (Dashboard & Charts) as the next planned phase.
21.5. **Flag for the Phase 4 plan:** the `HistoryRepository` introduced here is the canonical read-side surface for charts. Phase 4's bar chart and heatmap should consume it (or its widened cousin) — they should **not** re-query `daily_logs` directly.
21.6. **Flag for the Phase 7 plan:** Phase 7 should introduce an `is_fard` boolean on `tasks` and migrate `fardAnchorTaskIds` from a code constant to a query (D12 forward path).
21.7. Squash-merge once CI is green and `validation.md` checks pass (including the V19 zero-TODO gate).
