# Phase 2 — Local Persistence with SQLite · Requirements

> **Roadmap reference:** [`spec/roadmap.md`](../../spec/roadmap.md) — Phase 2 (Local Persistence with SQLite, 4 days).
> **Guiding docs:** [`spec/mission.md`](../../spec/mission.md), [`spec/tech-stack.md`](../../spec/tech-stack.md), repo-root [`README.md`](../../README.md) §3.
> **Prior phase:** [`specs/2026-05-12-static-daily-checklist/`](../2026-05-12-static-daily-checklist/) — Phase 1 (Static Daily Checklist, EN/AR).

## 1. Goal

Replace the in-memory `Map<String, bool>` checklist state introduced in Phase 1 with a Drift-backed SQLite store that:

- Survives app close / process kill / cold launch.
- Remembers today **and** yesterday (and the last 30 days, read-only — Phase 3 will add edit affordances).
- Auto-rolls the displayed "today" forward when the device clock crosses local midnight.
- Persists the user's language toggle preference across launches (closes the loop on Phase 1 D10).
- Works **identically on Android, iOS, and Web** — no platform-conditional UX divergence.

This phase is the data-layer foundation that Phases 3 (streaks/history), 4 (charts), 6 (cloud sync), and 7 (custom tasks) all build on. The Riverpod provider surface introduced in Phase 1 (`taskCatalogProvider`, `checklistStateProvider`, `dailyProgressProvider`) keeps the *same public contract* — only the source moves from in-memory to Drift.

## 2. Phase Exit Criteria (from roadmap)

- Add `drift` + SQLite schema for `tasks` and `daily_logs`.
- Seed default tasks on first launch.
- Persist task completions per day; auto-reset display at local midnight.
- Repository layer + Riverpod providers wired end-to-end.
- **Exit:** Closing/reopening the app preserves today's progress. Switching days shows correct historical state.

## 3. In Scope

### 3.1 Drift + SQLite setup (all three platforms)

- New runtime deps in `app/pubspec.yaml`:
  - `drift` (latest stable v2)
  - `drift_flutter` — single cross-platform `driftDatabase()` opener that handles Android, iOS, **and** Web.
  - `sqlite3_flutter_libs` — bundles the native SQLite shared library for Android & iOS.
  - `path_provider`, `path` — resolve the per-platform database file location on native.
- New dev deps:
  - `drift_dev`
  - `build_runner`
- Web bundle: drop `sqlite3.wasm` (version-matched to `drift`) and `drift_worker.dart.js` into `app/web/`. Source: the official Drift release assets. Both files are committed to the repo (small, ~1 MB each); CI does not download them at build time.
- Codegen: `dart run build_runner build --delete-conflicting-outputs` produces `app_database.g.dart`. Generated files are **committed** to keep `flutter analyze` clean in CI without forcing CI to run `build_runner`.

### 3.2 Schema (Drift v1 migration)

Three tables. Column names are snake_case in SQL; Dart accessors are camelCase per Drift convention.

| Table | Columns | Notes |
|---|---|---|
| `tasks` | `id` TEXT PK, `points` INT, `category` TEXT, `sort_order` INT | Seeded from `staticTaskCatalog`. See §3.4. |
| `daily_logs` | `date` TEXT, `task_id` TEXT, `completed` BOOL, `updated_at` DATETIME | Composite PK (`date`, `task_id`). `date` stores `YYYY-MM-DD` in the **device's local timezone**. `task_id` references `tasks.id`. |
| `app_settings` | `key` TEXT PK, `value` TEXT | Tiny K/V store. Phase 2 uses one key: `app.locale.override` ∈ {`en`, `ar`, `null` row absent}. |

- Schema version: `1` (no migration logic needed yet; `onCreate` runs DDL + seed).
- `onUpgrade` is wired with an explicit `assert(false, 'no migration path defined yet')` so a future schema bump can't silently no-op.
- Foreign keys are **enabled** (`PRAGMA foreign_keys = ON;` in `beforeOpen`).

### 3.3 Database opener & lifecycle

- Single `AppDatabase extends _$AppDatabase` class in `app/lib/core/db/app_database.dart`.
- Constructor takes a `QueryExecutor`. Production `AppDatabase.open()` calls `drift_flutter`'s `driftDatabase(name: 'muhasabah', native: const DriftNativeOptions(...))` which automatically picks the right opener per platform.
- Database file name on native: `muhasabah.sqlite` under the platform's app-documents directory (resolved by `path_provider`).
- Database location on web: OPFS / IndexedDB managed by `drift_worker.dart.js`.
- `AppDatabase` is created once at app startup and held by a Riverpod `Provider` (lifetime = process). Disposal is a no-op in this phase (the OS reclaims on process exit).

### 3.4 Task catalog seeding & reconciliation

- The static catalog (`app/lib/features/checklist/data/static_task_catalog.dart`) remains the **development** source of truth for task definitions in Phase 2. (Phase 7 will pivot to user-editable CRUD.)
- On **every** app launch, the database runs an idempotent reconcile pass:
  1. For each entry in `staticTaskCatalog`, upsert into `tasks` by `id` (write `points`, `category`, `sort_order`).
  2. Tasks present in DB but absent from the static catalog are **not** deleted (preserves any future user-custom rows landed in Phase 7); they are filtered out at the presentation layer because the static catalog provides the localized `titleResolver`.
- The seed/reconcile is wrapped in a single Drift transaction.
- Counter assertion in debug builds: after reconcile, `SELECT SUM(points) FROM tasks WHERE id IN (<staticCatalogIds>)` must equal **74** — mirrors the Phase 1 assert.

### 3.5 Repository layer

New folder `app/lib/features/checklist/data/`:

- `checklist_repository.dart` — abstract `ChecklistRepository` interface:
  - `Future<Map<String, bool>> readDay(DayKey day);` — returns `{taskId: completed}` for that date (missing rows default to `false`).
  - `Future<void> setCompletion({required DayKey day, required String taskId, required bool completed});`
  - `Future<void> resetDay(DayKey day);` — wipes all `daily_logs` rows for that date.
  - `Stream<Map<String, bool>> watchDay(DayKey day);` — Drift `.watch()` stream so the UI reacts to writes.
- `drift_checklist_repository.dart` — concrete impl backed by `AppDatabase`.
- `task_repository.dart` — abstract + concrete; reads tasks from the DB and joins them with the static catalog's `titleResolver` (matched by `id`) to produce display-ready `Task` objects.
- `settings_repository.dart` — abstract + concrete; `Future<String?> readLocaleOverride()` / `Future<void> writeLocaleOverride(String?)`.

`DayKey` is a small value class in `app/lib/core/time/day_key.dart`:

- Fields: `final int year, month, day;`
- Factory `DayKey.fromLocalDateTime(DateTime now)` — strips the time component using the **device's local timezone**.
- `String toIsoDate()` → `YYYY-MM-DD`.
- `==`/`hashCode` based on the three ints.
- Helpers: `previousDay()`, `nextDay()`, `daysSince(DayKey other)`.

### 3.6 Riverpod provider rewiring

The Phase 1 provider surface stays the same in spirit; implementations move:

| Provider | Phase 1 | Phase 2 |
|---|---|---|
| `taskCatalogProvider` | `Provider<List<Task>>` returning the static catalog directly | `FutureProvider<List<Task>>` reading from `TaskRepository` (cached after first load); seeded on first call. UI uses `.when()` with a skeleton state. |
| `checklistStateProvider` | `NotifierProvider<ChecklistNotifier, Map<String, bool>>` | `StreamProvider<Map<String, bool>>` (or `AsyncNotifierProvider` exposing `Stream` + a `toggle` method) backed by `ChecklistRepository.watchDay(activeDayProvider)`. Public `toggle(taskId)` writes through the repository. |
| `dailyProgressProvider` | `Provider<DailyProgress>` | `Provider<AsyncValue<DailyProgress>>` derived from the two above. |
| `localeProvider` | `NotifierProvider<LocaleNotifier, Locale?>` (session-only) | `AsyncNotifierProvider<LocaleNotifier, Locale?>` whose `build()` awaits `SettingsRepository.readLocaleOverride()`; `setLocale()` / `toggle()` write through and emit. |

New provider in `app/lib/features/checklist/presentation/providers/`:

- `active_day_provider.dart` — `NotifierProvider<ActiveDayNotifier, DayKey>` with:
  - `build()` returns `DayKey.fromLocalDateTime(DateTime.now())`.
  - `goToPreviousDay()`, `goToNextDay()`, `goToToday()`, `goToDay(DayKey)`.
  - Constraint: `nextDay()` cannot exceed today; `previousDay()` cannot go beyond `today - 30 days` (configurable constant `kMaxHistoryDays = 30`).

### 3.7 Midnight rollover

- A single `MidnightTickerService` (singleton, owned by a top-level provider) recomputes "today" and pushes a new `DayKey` to `activeDayProvider` if (and only if) the user is currently viewing today (i.e., the active day equals the previous "today").
- Implementation:
  1. On app start, schedule a one-shot `Timer` for the **next local midnight** (next-day 00:00:00 in the device's local timezone). On fire, recompute and reschedule.
  2. Also observe `WidgetsBindingObserver.didChangeAppLifecycleState` — on `resumed`, recompute immediately (handles backgrounded apps that miss the timer fire and DST shifts).
- If the user has navigated to a past day via the day picker, the ticker does **not** force-snap them back to today — it only rebases the "what is today" anchor used by `activeDayProvider.goToToday()` and the picker's bounds.
- The rollover does **not** clear the previous day's `daily_logs` — it just changes which day's rows the screen reads.

### 3.8 UI changes

**Day-picker row** (new), placed between the AppBar and the existing `ChecklistProgressHeader`:

- Layout: `[‹] [Today / Yesterday / Wed 6 May] [›]` centered, ~48 px tall.
- The middle label reads:
  - `AppLocalizations.dayLabelToday` if `activeDay == today`.
  - `AppLocalizations.dayLabelYesterday` if `activeDay == today - 1 day`.
  - Otherwise a localized short date (e.g. `"Wed, 6 May"` / `"الأربعاء، 6 مايو"`) — uses `intl.DateFormat.MMMEd(locale)`.
- Right arrow (`›`) is disabled when `activeDay == today`.
- Left arrow (`‹`) is disabled when `activeDay == today - kMaxHistoryDays`.
- Tapping the middle label opens a small `showDatePicker` constrained to `[today - kMaxHistoryDays, today]`.
- **RTL:** arrows use `Icons.chevron_left` / `chevron_right` inside an `IconButton` — Material 3 mirrors them automatically when wrapped by `Directionality`. **Semantics** of "previous" / "next" are bound to the logical action, not the glyph direction, so screen readers stay correct in both locales.

**Read-only past days:**

- When `activeDay != today`, every `TaskRow` renders as disabled (`onChanged: null` on the `CheckboxListTile`, opacity reduced per Material 3 spec). Tapping does nothing; the row's semantics announce the localized state but not a toggle action.
- The progress header still renders the historical `DailyProgress` for that day.
- A small "read-only" pill (`AppLocalizations.readOnlyBadge`) appears in the header when viewing a past day.

**Debug "Reset today" affordance:**

- **Long-press** the progress header (≥ 600 ms) opens a Material `AlertDialog`:
  - Title: `AppLocalizations.resetTodayDialogTitle`
  - Body: `AppLocalizations.resetTodayDialogBody`
  - Actions: `Cancel` (default) / `Reset` (destructive style, soft-green text per mission — no red).
- `Reset` calls `ChecklistRepository.resetDay(today)` and dismisses.
- The long-press is **only** available when `activeDay == today` — viewing a past day shows no affordance (read-only).
- This is a developer/QA tool; we surface it now to make midnight-rollover and persistence verification fast. The affordance is **kept** post-MVP for users who want to redo their day.

### 3.9 Feature folder layout (delta from Phase 1)

```
app/
  l10n/
    app_en.arb                                # +6 new keys (see §3.10)
    app_ar.arb                                # +6 new keys with TODO: placeholders (V36 gate again)
  web/
    sqlite3.wasm                              # NEW — committed binary, version-pinned
    drift_worker.dart.js                      # NEW — committed JS bundle
  lib/
    core/
      db/
        app_database.dart                     # NEW — Drift @DriftDatabase class
        app_database.g.dart                   # NEW — generated, committed
        tables/
          tasks_table.dart                    # NEW
          daily_logs_table.dart               # NEW
          app_settings_table.dart             # NEW
      time/
        day_key.dart                          # NEW — DayKey value class
        midnight_ticker_service.dart          # NEW
    features/
      checklist/
        data/
          static_task_catalog.dart            # unchanged from Phase 1
          checklist_repository.dart           # NEW — abstract
          drift_checklist_repository.dart     # NEW — concrete
          task_repository.dart                # NEW
          settings_repository.dart            # NEW
        domain/
          task.dart                           # unchanged
          daily_progress.dart                 # unchanged
        presentation/
          providers/
            task_catalog_provider.dart        # MODIFIED — now FutureProvider
            checklist_state_provider.dart     # MODIFIED — now StreamProvider w/ repo
            daily_progress_provider.dart      # MODIFIED — handles AsyncValue
            active_day_provider.dart          # NEW
          widgets/
            checklist_progress_header.dart    # MODIFIED — long-press handler, read-only pill
            category_section.dart             # MODIFIED — passes read-only flag down
            task_row.dart                     # MODIFIED — read-only when activeDay != today
            day_picker_bar.dart               # NEW
          checklist_screen.dart               # MODIFIED — inserts day picker, async wiring
    main.dart                                 # MODIFIED — awaits AppDatabase before runApp
```

### 3.10 New localization keys

Added to **both** `app_en.arb` and `app_ar.arb` (Arabic values ship as `TODO: …` placeholders again — V36-equivalent gate; see §3.13):

| Key | English value | Notes |
|---|---|---|
| `dayLabelToday` | `Today` | |
| `dayLabelYesterday` | `Yesterday` | |
| `dayPickerPreviousLabel` | `Previous day` | Tooltip + semantics label for `‹` |
| `dayPickerNextLabel` | `Next day` | Tooltip + semantics label for `›` |
| `readOnlyBadge` | `Read-only` | Small pill on past-day view |
| `resetTodayDialogTitle` | `Reset today's progress?` | Long-press dialog |
| `resetTodayDialogBody` | `This will uncheck every task for today. Past days are unaffected.` | |
| `resetTodayDialogCancel` | `Cancel` | |
| `resetTodayDialogConfirm` | `Reset` | |
| `loadingChecklist` | `Loading your checklist…` | Skeleton state while `taskCatalogProvider` resolves on first launch |

### 3.11 Bootstrap flow change

`main.dart` becomes async:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  await database.seedAndReconcile(); // idempotent
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const MuhasabahApp(),
    ),
  );
}
```

This means a single brief frame of `Loading…` is acceptable on first launch; subsequent launches are instant because the OS caches the SQLite open.

### 3.12 No new platforms, no new theming

- Material 3 + soft-green seed: **unchanged** from Phase 0/1.
- Routing: still single `/` route → `ChecklistScreen`. No new `go_router` routes in Phase 2.

### 3.13 Localization completeness gate (re-applied from Phase 1)

- Every new ARB key must exist in both files.
- `app_ar.arb` ships `TODO: …` placeholders that **must be filled before merge** (gate V36-equivalent — see `validation.md`).

## 4. Out of Scope (explicitly deferred)

- 7-day strip on the home screen → **Phase 3**.
- Current-streak / longest-streak counters → **Phase 3**.
- Editing completions on past days (the day picker is read-only this phase) → **Phase 3** ("On this day" navigation with an explicit edit window).
- Dashboard, weekly bar chart, monthly heatmap, per-category breakdown → **Phase 4**.
- Notifications (any kind) → **Phase 5**.
- Auth, cloud sync, sync queue, conflict resolution → **Phase 6**.
- User-custom tasks (CRUD), hide/disable default tasks → **Phase 7**.
- Weekly challenges → **Phase 8**.
- Comprehensive automated test harness for the domain/repository layer — **mentioned in Phase 1 validation as "lands in Phase 2"** but deliberately **descoped** here to keep the 4-day budget honest. A few smoke tests are welcome but not gated by validation; the canonical test pass is owned by a future polish phase (see R6).
- Eastern Arabic-Indic digits — still deferred per Phase 1 D13.

## 5. Decisions Recorded This Phase

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Persistence library | **Drift** (formerly Moor) on top of `sqlite3` | Tech-stack mandate; type-safe queries, reactive streams, mature web support. |
| D2 | Platform parity | **All three platforms** (Android, iOS, Web) get persistence in this phase | Mission's "single codebase" promise + the user explicitly chose this option in spec scoping. The ~1 day of Web wasm/worker setup fits inside the 4-day budget. |
| D3 | Web SQLite delivery | Commit `sqlite3.wasm` + `drift_worker.dart.js` into `app/web/` | Avoids brittle CDN fetches at build time; CI is offline-deterministic. ~2 MB repo growth is acceptable. |
| D4 | Generated files | `*.g.dart` files are **committed** | Keeps CI lint-only (no `build_runner` step); matches the Phase 0 CI design. |
| D5 | Schema columns | `tasks(id, points, category, sort_order)`, `daily_logs(date, task_id, completed, updated_at)`, `app_settings(key, value)` | Smallest viable surface; `updated_at` is groundwork for Phase 6 sync (last-write-wins). |
| D6 | Day key representation | Store dates as `YYYY-MM-DD` text computed against the **device's local timezone**; no UTC normalization this phase | Roadmap explicitly says "local midnight". DST edge cases are accepted risk for Phase 2 (see R3). |
| D7 | Task catalog truth | Static catalog remains the dev source-of-truth; `tasks` table is seeded **and reconciled** on every launch (upsert-by-id, no deletes) | Smooth ramp into Phase 7 (which flips DB → primary); reconciliation lets us tune points/sort-order in code without a migration. |
| D8 | Provider surface | Phase 1 provider names stay; types shift to `AsyncValue` / `Stream`-backed | Minimizes the diff at call sites and prevents UI from re-architecting twice. |
| D9 | Locale persistence | Persisted via the new `app_settings` table (single source: Drift); no new top-level dependency on `shared_preferences` | Cleaner — one persistence layer; closes Phase 1 D10. |
| D10 | History window | Day picker exposes the last **30 days** (read-only); future arrows disabled past today | The minimal-day-picker option you chose; 30 days is enough for monthly insight in Phase 4 to read meaningful history without Phase 2 bleeding into Phase 3's edit window. |
| D11 | Past-day editability | **Read-only** for any day where `activeDay != today` | Phase 3 owns the editable window (e.g. last 7 days). Read-only-only here removes ambiguity. |
| D12 | Midnight rollover | One-shot `Timer` to next local midnight + `WidgetsBindingObserver` resume hook; **only** auto-snaps the active day if the user was already on today | "Calm by design" — does not yank the user mid-review of yesterday. |
| D13 | Reset-today affordance | Long-press the progress header → confirm dialog → `resetDay(today)` | Fastest manual QA path for verifying persistence + midnight; kept post-MVP (not gated behind a debug flag) as a legitimate user feature. |
| D14 | Boot sequencing | `main()` is `async`; opens & seeds DB **before** `runApp` | Avoids a flash-of-empty-state and simplifies provider `build()` methods. ~50–200 ms first-launch delay is acceptable. |
| D15 | Test harness scope | Smoke unit tests for `DayKey` arithmetic and `DailyProgress.from` are welcome; full repository integration tests **deferred** | You explicitly did not select "land the test harness" in spec scoping. Deferring keeps the 4-day budget honest. |

## 6. Context & Assumptions

- Phase 1 deliverables are on `master`: Riverpod + i18n wired, `ChecklistScreen` rendering 8 categories × 34 tasks × 74 points; `localeProvider` exists as a session-only `Notifier`.
- This branch is `feature/phase-2-local-persistence-sqlite`, branched off `master` post-Phase-1 merge (commit `2f4417c`).
- The reviewer's dev environment already has the Phase 0 / Phase 1 prerequisites; Phase 2 adds nothing platform-side beyond Flutter stable.
- The `sqlite3.wasm` and `drift_worker.dart.js` artifacts are downloaded from the Drift release matching the chosen `drift` version (e.g. drift `2.x` → matching `sqlite3.wasm`). The PR description must record the version + the SHA-256 of each binary committed under `app/web/`.
- No backend touched in Phase 2; `/api` remains green on `api-lint`.
- This spec folder (`specs/2026-05-12-local-persistence-sqlite/`) is the source of truth for the feature and will be linked from the PR description.

## 7. Risks / Open Questions

- **R1 — Drift Web setup is fiddly.** The first-time setup of wasm + worker on Chrome can surface obscure CORS / cross-origin-isolation errors if the dev server isn't configured for COOP/COEP headers. *Mitigation:* document the exact `flutter run -d chrome --web-header=Cross-Origin-Embedder-Policy=require-corp ...` invocation in the PR; pin specific wasm/worker versions in `app/web/`.
- **R2 — Generated `*.g.dart` drift.** Committing generated code risks merge conflicts on later schema changes. *Mitigation:* `build_runner` regen is a single command; the PR description lists the exact regen command; Phase 7 will revisit whether to gitignore the files and add a CI build step instead.
- **R3 — DST / timezone edge cases.** A user crossing a DST boundary or changing device timezone mid-day will see "today" reinterpreted. *Mitigation:* document as accepted risk; the `MidnightTickerService` recompute-on-resume hook covers the most common path (phone in airplane mode on a flight, then back online). Full timezone-stable storage is a Phase 6 (sync) concern.
- **R4 — First-launch latency on Web.** Opening the wasm worker + IndexedDB on first navigation to the page can take 200–500 ms; subsequent loads are instant. *Mitigation:* the `loadingChecklist` skeleton string is shown if `taskCatalogProvider` is still resolving on first frame.
- **R5 — Reconciliation can't remove tasks.** If the static catalog ever shrinks (a task is removed), the row stays in `tasks` and any historical `daily_logs` referencing it remain — they just don't render. *Mitigation:* explicitly out-of-scope for Phase 2; Phase 7 will introduce a soft-delete column (`is_active`) and a UI for hidden tasks. Documented in D7.
- **R6 — No automated tests = brittle later.** Skipping the test harness now means refactoring the repository layer in Phase 3 (when streaks land) carries more risk. *Mitigation:* accept the trade now; budget a half-day in the **first** phase that touches the repository to add tests in arrears (likely Phase 3 or Phase 6 — flag it in the Phase 3 plan opener).
- **R7 — Long-press as a destructive trigger.** Long-press can be discovered accidentally (especially on mobile with sticky touch). *Mitigation:* the dialog is the safety net; the destructive action requires an explicit tap. "Reset" copy is encouraging ("Reset today's progress?") rather than alarming. No red color — soft-green per mission.
- **R8 — Reset-today must not nuke past days.** A bug in `resetDay` could match too broadly. *Mitigation:* unit-test the WHERE clause is `date = ?` (single equality, not a range) — this is the **one** test we *will* write this phase (in `app/test/data/drift_checklist_repository_test.dart`).
- **R9 — `localeProvider` race on first frame.** Reading the locale override from Drift is async, so the very first frame on cold launch may render in system locale before snapping to the override. *Mitigation:* since `main()` already awaits the DB open and seed, we also `await SettingsRepository.readLocaleOverride()` there and pass the initial value via a provider override — guaranteeing the first frame respects the persisted choice.
