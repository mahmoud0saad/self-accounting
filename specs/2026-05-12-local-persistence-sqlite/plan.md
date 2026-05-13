# Phase 2 — Local Persistence with SQLite · Plan

> Numbered task groups. Each group is self-contained, ordered for least-rework. Adjacent groups may be collapsed into the same commit, but ordering should be preserved.

---

## 1. Branch & dependencies

1.1. Confirm working tree is clean and you are on `feature/phase-2-local-persistence-sqlite` (branched off `master` post-Phase-1 merge `2f4417c`).
1.2. From `/app`, add the Drift runtime stack:
   ```bash
   flutter pub add drift drift_flutter sqlite3_flutter_libs path_provider path
   ```
1.3. From `/app`, add the Drift codegen toolchain as **dev** deps:
   ```bash
   flutter pub add --dev drift_dev build_runner
   ```
1.4. Run `flutter pub get` and verify `pubspec.lock` was updated. Commit `pubspec.yaml` + `pubspec.lock` as a single bookkeeping commit before any code lands.
1.5. From `/app`, run `flutter analyze` — must report `No issues found!` before any code changes (regression check that the new deps don't pull in lint debt).

## 2. Web platform assets (`app/web/`)

2.1. Identify the exact version of `drift` resolved in `pubspec.lock` (e.g. `2.x.y`). Visit the matching Drift release on GitHub.
2.2. Download `sqlite3.wasm` (version-pinned to `drift`'s embedded `sqlite3` binding) and `drift_worker.dart.js`.
2.3. Place both files in `app/web/` and `git add` them. Capture their SHA-256 sums in the PR description (reviewers verify integrity).
2.4. Add a comment block (or `app/web/README.md` snippet) explaining where the files came from + the regeneration command for future bumps.
2.5. Confirm `flutter build web` (dry-run) still succeeds — no missing-asset errors.

## 3. Drift schema (`app/lib/core/db/`)

3.1. Create `app/lib/core/db/tables/tasks_table.dart`:
   ```dart
   class Tasks extends Table {
     TextColumn get id => text()();
     IntColumn get points => integer()();
     TextColumn get category => text()();
     IntColumn get sortOrder => integer().named('sort_order')();

     @override
     Set<Column> get primaryKey => {id};
   }
   ```
3.2. Create `app/lib/core/db/tables/daily_logs_table.dart`:
   ```dart
   class DailyLogs extends Table {
     TextColumn get date => text()();
     TextColumn get taskId => text().named('task_id').references(Tasks, #id)();
     BoolColumn get completed => boolean().withDefault(const Constant(false))();
     DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();

     @override
     Set<Column> get primaryKey => {date, taskId};
   }
   ```
3.3. Create `app/lib/core/db/tables/app_settings_table.dart` with `key` (PK) + `value` text columns.
3.4. Create `app/lib/core/db/app_database.dart`:
   - `@DriftDatabase(tables: [Tasks, DailyLogs, AppSettings])` on `class AppDatabase extends _$AppDatabase`.
   - Constructor: `AppDatabase(QueryExecutor e) : super(e);`.
   - `@override int get schemaVersion => 1;`.
   - `@override MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll(), onUpgrade: (m, from, to) { throw StateError('no migration path defined yet; bump schemaVersion deliberately'); });`.
   - `@override Future<void> beforeOpen(OpeningDetails details) async { await customStatement('PRAGMA foreign_keys = ON;'); }` — set the FK pragma every open.
   - Static `static Future<AppDatabase> open() async => AppDatabase(await _opener());` where `_opener()` calls `driftDatabase(name: 'muhasabah')` from `drift_flutter`.
3.5. Run `dart run build_runner build --delete-conflicting-outputs` from `/app`. Confirm `app_database.g.dart` is generated. **Commit it.**

## 4. Seed & reconciliation

4.1. Inside `AppDatabase`, add `Future<void> seedAndReconcile()`:
   - Open a transaction.
   - For each `Task t` in `staticTaskCatalog`, `into(tasks).insertOnConflictUpdate(TasksCompanion.insert(id: t.id, points: t.points, category: t.category.name, sortOrder: idx))` (idx = position in the static list — preserves catalog order).
   - Outside the transaction (still in the same method), in debug builds only: `assert((await (select(tasks)..where((t) => t.id.isIn(staticIds))).get()).fold(0, (s, r) => s + r.points) == 74, 'static catalog sum drifted from 74');`.
4.2. **Do not** delete rows whose `id` is not in the static catalog (D7 / R5). The presentation layer filters by intersection with `staticTaskCatalog` ids.

## 5. `DayKey` value class (`app/lib/core/time/day_key.dart`)

5.1. Implement the immutable `DayKey` with `final int year, month, day;`.
5.2. Factory `DayKey.fromLocalDateTime(DateTime now)` — call `now.toLocal()` then strip H/M/S.
5.3. `factory DayKey.today() => DayKey.fromLocalDateTime(DateTime.now());`.
5.4. `String toIsoDate()` — zero-pads month/day → `"YYYY-MM-DD"`.
5.5. `DayKey previousDay()`, `DayKey nextDay()` — go through `DateTime` arithmetic so month/year carry correctly (e.g. `DayKey(2026, 3, 1).previousDay()` → `DayKey(2026, 2, 28)` or `29` correctly).
5.6. `int daysSince(DayKey other)` — `DateTime` diff in whole days.
5.7. `operator ==`/`hashCode` over (year, month, day). Stable `toString()` for debug logs.

## 6. Midnight ticker (`app/lib/core/time/midnight_ticker_service.dart`)

6.1. Define `class MidnightTickerService extends WidgetsBindingObserver` with a method `void start(void Function(DayKey newToday) onTodayChanged)`.
6.2. On `start()`:
   - Register self via `WidgetsBinding.instance.addObserver(this);`.
   - Compute `Duration untilMidnight = …` (next local 00:00:00.001 minus `DateTime.now()`).
   - `Timer(untilMidnight, _onMidnight)` — on fire, compute the new today, call `onTodayChanged(...)`, reschedule.
6.3. `@override void didChangeAppLifecycleState(AppLifecycleState state)` — on `resumed`, recompute today and call `onTodayChanged(...)` if the day has changed.
6.4. `void dispose()` cancels the timer + removes the observer.
6.5. Expose `final midnightTickerProvider = Provider<MidnightTickerService>(...)` with `ref.onDispose(() => service.dispose())`.

## 7. Repository layer (`app/lib/features/checklist/data/`)

7.1. Create `checklist_repository.dart` — abstract `ChecklistRepository`:
   ```dart
   abstract class ChecklistRepository {
     Future<Map<String, bool>> readDay(DayKey day);
     Future<void> setCompletion({required DayKey day, required String taskId, required bool completed});
     Future<void> resetDay(DayKey day);
     Stream<Map<String, bool>> watchDay(DayKey day);
   }
   ```
7.2. Create `drift_checklist_repository.dart` — concrete class taking an `AppDatabase`:
   - `readDay`: `select(dailyLogs)..where((r) => r.date.equals(day.toIsoDate()))` → map to `{taskId: completed}`.
   - `setCompletion`: `into(dailyLogs).insertOnConflictUpdate(DailyLogsCompanion.insert(date: day.toIsoDate(), taskId: taskId, completed: Value(completed)));`.
   - `resetDay`: `(delete(dailyLogs)..where((r) => r.date.equals(day.toIsoDate()))).go();` — **note** the WHERE clause is a single equality (R8 — unit-test asserts this).
   - `watchDay`: `(select(dailyLogs)..where((r) => r.date.equals(day.toIsoDate()))).watch().map(...)`.
7.3. Create `task_repository.dart` — abstract + concrete; `Future<List<Task>> readAll()` joins the DB rows with `staticTaskCatalog` (matched by id) to produce display-ready `Task` objects with their `titleResolver`. Tasks present in DB but absent from the static catalog are filtered out.
7.4. Create `settings_repository.dart`:
   - `Future<String?> readLocaleOverride()` — `SELECT value FROM app_settings WHERE key = 'app.locale.override'`; return `null` if missing.
   - `Future<void> writeLocaleOverride(String? code)` — if `code == null`, `DELETE`; else `INSERT OR REPLACE`.

## 8. The one mandatory unit test (`app/test/data/drift_checklist_repository_test.dart`)

8.1. Use Drift's `NativeDatabase.memory()` to spin up an in-memory `AppDatabase`.
8.2. Seed two days of `daily_logs` (`2026-05-12` and `2026-05-11`), each with 3 task completions.
8.3. Call `resetDay(DayKey(2026, 5, 12))`.
8.4. Assert: `2026-05-12` has zero rows; `2026-05-11` still has its 3 rows.
8.5. This single test exists because R8 flagged a high-impact regression surface. It is the **only** mandatory test this phase per D15.

## 9. Riverpod providers (`app/lib/features/checklist/presentation/providers/` + `app/lib/core/i18n/locale_provider.dart`)

9.1. New top-level `app_database_provider.dart` in `core/db/`:
   ```dart
   final appDatabaseProvider = Provider<AppDatabase>((_) => throw UnimplementedError(
     'appDatabaseProvider must be overridden in main() with the opened database.',
   ));
   ```
9.2. `task_catalog_provider.dart` → `final taskCatalogProvider = FutureProvider<List<Task>>((ref) async => ref.read(taskRepositoryProvider).readAll());`. Repository provider is a thin `Provider` over `appDatabaseProvider`.
9.3. `active_day_provider.dart`:
   - `class ActiveDayNotifier extends Notifier<DayKey>`.
   - `build()` returns `DayKey.today()`.
   - Methods: `goToPreviousDay()`, `goToNextDay()`, `goToToday()`, `goToDay(DayKey)` — all enforce the `[today - kMaxHistoryDays, today]` clamp (const `kMaxHistoryDays = 30` at top of file).
9.4. `checklist_state_provider.dart`:
   - Replace the `Notifier<Map<String, bool>>` with a `StreamProvider.autoDispose<Map<String, bool>>((ref) { final day = ref.watch(activeDayProvider); return ref.read(checklistRepositoryProvider).watchDay(day); });`.
   - **Public `toggle(String taskId)` API:** add a small companion `Provider<ChecklistController>` exposing `Future<void> toggle(String taskId)` that resolves the current `activeDayProvider` value and current state, computes the flipped bool, and calls `setCompletion(...)`. UI calls `ref.read(checklistControllerProvider).toggle(id)`.
9.5. `daily_progress_provider.dart` → returns `AsyncValue<DailyProgress>` derived from `taskCatalogProvider` (`AsyncValue<List<Task>>`) and `checklistStateProvider` (`AsyncValue<Map<String, bool>>`). Both `loading`/`error` collapse to a loading header.
9.6. `core/i18n/locale_provider.dart`:
   - Convert `LocaleNotifier` from `Notifier<Locale?>` to `AsyncNotifier<Locale?>`.
   - `build()` reads `SettingsRepository.readLocaleOverride()` → returns `null` if absent, else `Locale(code)`.
   - `setLocale(Locale? l)` and `toggle()` call the repository's `writeLocaleOverride(...)` and emit the new state.
   - **Critical:** in `main()`, after opening the DB and reading the initial locale value, **override** `localeProvider` with `AsyncValue.data(initial)` so the first frame never flashes the system locale over the persisted choice (R9).

## 10. Bootstrap (`app/lib/main.dart`)

10.1. Convert `main()` to `Future<void> main() async { ... }`.
10.2. Call `WidgetsFlutterBinding.ensureInitialized();` as the first line.
10.3. `final database = await AppDatabase.open();` then `await database.seedAndReconcile();`.
10.4. `final initialLocaleCode = await SettingsRepository(database).readLocaleOverride();` → convert to `Locale?`.
10.5. `runApp(ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(database), localeProvider.overrideWith(() => LocaleNotifier()..debugPresetInitial(initialLocaleCode)), ], child: const MuhasabahApp()));`.
   - (`debugPresetInitial` is a small back-door on `LocaleNotifier` that bypasses the async `build()` for the first frame; it's purely an optimization for R9.)
10.6. Wire `MidnightTickerService` into a top-level `ConsumerStatefulWidget` shell that, in `initState`, reads `midnightTickerProvider.start((newToday) { ref.read(activeDayProvider.notifier).goToDay(newToday); })` — but **only** when `ref.read(activeDayProvider) == previousToday` (the "don't yank the user mid-review" rule, D12).
10.7. Keep `useMaterial3: true` and the soft-green seed theme **unchanged**.

## 11. Localization additions

11.1. Open `app/l10n/app_en.arb`. Append the 10 new keys from `requirements.md` §3.10 with their English values + `@`-metadata blocks (placeholder declarations where applicable).
11.2. Open `app/l10n/app_ar.arb`. Append the **same 10 keys** with `TODO:` placeholder values (e.g. `"dayLabelToday": "TODO: اليوم"`).
11.3. Run `flutter pub get` to trigger `gen-l10n` re-run. Confirm `AppLocalizations.dayLabelToday` (and the other 9) resolve in the IDE.

## 12. UI — Day picker bar (`app/lib/features/checklist/presentation/widgets/day_picker_bar.dart`)

12.1. `ConsumerWidget` reading `activeDayProvider`.
12.2. Layout: `Row(mainAxisAlignment: MainAxisAlignment.center, children: [prevButton, Expanded(child: Center(child: label)), nextButton])`. **No** hard-coded `left`/`right` padding — use `EdgeInsetsDirectional`.
12.3. Previous button: `IconButton(icon: Icon(Icons.chevron_left), tooltip: l.dayPickerPreviousLabel, onPressed: canGoPrev ? () => ref.read(activeDayProvider.notifier).goToPreviousDay() : null)`.
12.4. Next button: mirror logic with `Icons.chevron_right`. `onPressed: null` (disabled) when active day equals today.
12.5. Label: `TextButton` whose child is the localized day-label string. `onPressed` opens `showDatePicker(context: context, initialDate: ..., firstDate: today - kMaxHistoryDays, lastDate: today, locale: ref.watch(localeProvider).valueOrNull)`. Result feeds `goToDay(DayKey.fromLocalDateTime(picked))`.
12.6. Helper `String _labelFor(DayKey active, DayKey today, AppLocalizations l, Locale locale)`:
   - active == today → `l.dayLabelToday`.
   - active == today.previousDay() → `l.dayLabelYesterday`.
   - else → `DateFormat.MMMEd(locale.toLanguageTag()).format(activeAsDateTime)`.

## 13. UI — Read-only past-day state

13.1. Modify `task_row.dart`:
   - Read `final isToday = ref.watch(activeDayProvider) == DayKey.today();`.
   - When `!isToday`, set `onChanged: null` on the `CheckboxListTile` (or wrap the `InkWell` with `IgnorePointer`).
   - Material 3's disabled visual treatment kicks in automatically; do not introduce a custom muted color.
   - Semantics label gets the existing `taskRowSemanticLabel` (state-aware) but adds the localized `readOnlyBadge` suffix when applicable.
13.2. Modify `checklist_progress_header.dart`:
   - When `!isToday`, render a small pill (`Container` with `BorderRadius.circular(12)`, surface-variant background) containing `Text(l.readOnlyBadge, style: labelSmall)` aligned to the start.

## 14. UI — Reset-today affordance

14.1. In `checklist_progress_header.dart`, wrap the outer container in `GestureDetector(onLongPress: isToday ? () => _confirmReset(context, ref) : null, child: ...)`.
14.2. `_confirmReset` shows a Material `AlertDialog` using the 4 localized strings from §3.10 (`resetTodayDialogTitle`, `…Body`, `…Cancel`, `…Confirm`).
14.3. On confirm: `await ref.read(checklistRepositoryProvider).resetDay(DayKey.today()); if (context.mounted) Navigator.of(context).pop();`.
14.4. The reset action's color is the Material 3 primary (soft-green) — **no** red. The dialog's body copy is encouraging, not alarming.

## 15. Screen composition (`app/lib/features/checklist/presentation/checklist_screen.dart`)

15.1. Insert `DayPickerBar` between the `AppBar` and the existing `ChecklistProgressHeader` (top of the `CustomScrollView`'s first `SliverToBoxAdapter`).
15.2. The `SliverList`s for each category now read tasks from the **resolved** `taskCatalogProvider` (use `.when(data: ..., loading: ..., error: ...)` at the outermost layer). The loading state shows `l.loadingChecklist` centered.
15.3. The error state surfaces a small `Text(error.toString())` for now — full Sentry wiring is a tech-stack item for later phases.

## 16. Static analysis, formatting & RTL guard

16.1. From `/app`: `dart format .` — must produce a clean diff (no changes after the first run).
16.2. From `/app`: `flutter analyze` — must report `No issues found!`. Generated `*.g.dart` files are subject to analysis; if `drift_dev` produces lints, suppress them at the file level only (`// ignore_for_file:` at the top of the generated file is acceptable since we commit it).
16.3. From `/app`: `dart format --output=none --set-exit-if-changed .` — must exit 0.
16.4. **RTL guard (same as Phase 1):** from `/app`, `rg "EdgeInsets\.only\(left|right" lib/features/checklist/ lib/core/` and `rg "Alignment\.(centerLeft|centerRight)" lib/features/checklist/ lib/core/` must return **zero hits**.
16.5. **Reset-WHERE-clause guard:** from `/app`, `rg "delete\(dailyLogs\)" lib/features/checklist/data/` should return **exactly one** match (in `drift_checklist_repository.dart`); the surrounding lines must show a single `.where((r) => r.date.equals(...))` — no `isBetweenValues` or `isIn` clauses. Combined with the test in §8, this is the R8 defense-in-depth.

## 17. Manual verification on Web

17.1. From `/app`: `flutter run -d chrome --web-header=Cross-Origin-Embedder-Policy=require-corp --web-header=Cross-Origin-Opener-Policy=same-origin`. (Drift Web requires cross-origin-isolated context to use the OPFS-backed worker.)
17.2. **First-launch smoke:** wait for `loadingChecklist` to disappear (≤ 500 ms on a warm machine); confirm all 8 categories and 34 rows render in EN.
17.3. **Persistence:** check 5 tasks across 3 different categories; note the percentage (e.g. `14%`). Fully close the browser tab. Re-run `flutter run -d chrome ...`. Confirm the same 5 tasks are still checked and the percentage matches.
17.4. **Locale persistence:** tap the AppBar `EN ⇄ ع` toggle to switch to Arabic. Close the tab. Re-run. Confirm the app opens in Arabic + RTL **on the first frame** — no flash to English.
17.5. **Day picker:**
   - With today's progress non-empty, tap `‹` once. Confirm:
     - Label changes from `Today` to `Yesterday`.
     - All rows show as disabled (Material 3 muted styling).
     - The progress header shows `0 / 74 points` (yesterday is unrecorded) and a `Read-only` pill.
     - Tapping a row does **nothing** — no toggle, no haptic, no snackbar.
   - Tap `›`. Confirm the screen returns to today and the previously-checked rows are still checked.
   - Tap the middle label → calendar picker. Pick a date 10 days ago. Confirm same read-only behavior.
17.6. **History bounds:**
   - Tap `‹` 30 times. Confirm `‹` is disabled at day -30.
   - From today, tap `›` once. Confirm it's already disabled.
17.7. **Reset today:** with today partially checked, long-press the progress header. Confirm:
   - Dialog opens with the 4 localized strings.
   - `Cancel` keeps state.
   - `Reset` wipes today's progress (`0 / 74 points`); past-day data unaffected — tap `‹` to verify the previous day (if you populated it) is still intact (you won't have populated it without the picker; treat this verification as "no other day's rows changed" by inspecting `daily_logs` via DevTools → IndexedDB if needed).
   - The reset action is **not** available when viewing a past day (long-press is a no-op).
17.8. **Midnight rollover (simulated):** the easiest manual test is to change the device clock forward to 00:00:30 of the next day (Chrome DevTools → Sensors won't help here; use the OS clock or set `Locale + Region` to a future-day zone). Confirm:
   - The active-day label flips to the new "Today" within 30 seconds of crossing midnight (timer) or immediately on app resume.
   - The previously-completed checkboxes clear (new day = empty `daily_logs`).
   - Tapping `‹` shows the previous day's full record intact.

## 18. (Optional) Mobile spot-check

18.1. If an Android emulator is available: `flutter run -d <android-emulator-id>`. Repeat §17.2–§17.5 and §17.7. The native Drift path uses `sqlite3_flutter_libs` + `path_provider` and is functionally distinct from the Web path — this is a real coverage gain.
18.2. iOS verification is not required this phase (no macOS in the dev environment per Phase 0 convention). Note `deferred — no macOS` in the PR if applicable.

## 19. Pre-merge: fill Arabic translations (V36-equivalent gate)

19.1. Open `app/l10n/app_ar.arb`. For each of the 10 new keys, replace `TODO: …` with the reviewed final Arabic translation.
19.2. From `/app`: `rg "TODO:" l10n/app_ar.arb` — must return **zero matches** (this includes both Phase 1's keys and Phase 2's new keys).
19.3. Re-run §16 (analyze + format) and §17.2 / §17.4 / §17.7 (smoke + locale persistence + reset) on the Arabic build.

## 20. CI

20.1. The existing `app-lint` job runs `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, and `flutter analyze`. **No workflow changes** are required for Phase 2:
   - `flutter pub get` triggers `gen-l10n` automatically.
   - The committed `*.g.dart` files mean `build_runner` does **not** need to run in CI.
   - The committed `sqlite3.wasm` + `drift_worker.dart.js` mean no asset downloads at build time.
20.2. Confirm on the PR that `app-lint` and `api-lint` are both green. `api-lint` must still pass — Phase 2 doesn't touch `/api`.

## 21. Wrap-up & handoff

21.1. Re-read `validation.md`; tick every acceptance check.
21.2. Update root `README.md` "Status" line to `Phase 2 ✅ — local persistence (Drift/SQLite, EN + AR)`.
21.3. Add a "Specs" reference for this folder in `README.md` alongside Phase 0 and Phase 1.
21.4. Record the bundled Web binary SHAs in the PR description: `sqlite3.wasm <sha>` and `drift_worker.dart.js <sha>`.
21.5. Open PR `feature/phase-2-local-persistence-sqlite → master`; paste a link to `specs/2026-05-12-local-persistence-sqlite/` in the description; reference Phase 3 (History & Streaks) as the next planned phase.
21.6. **Flag for the Phase 3 plan:** the test harness deferred in D15 should land alongside Phase 3's streak code — same files we touch, half-day budgeted upfront.
21.7. Squash-merge once CI is green and `validation.md` checks pass (including the V36-equivalent zero-TODO gate).
