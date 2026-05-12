# Phase 1 — Static Daily Checklist · Plan

> Numbered task groups. Each group is self-contained, ordered for least-rework. Adjacent groups may be collapsed into the same commit, but ordering should be preserved.

---

## 1. Branch & dependencies

1.1. Confirm working tree is clean and you are on `feature/phase-1-static-daily-checklist` (branched off `master`).
1.2. From `/app`, add `flutter_riverpod` (latest stable v2) via `flutter pub add flutter_riverpod`.
1.3. From `/app`, add `intl` via `flutter pub add intl`. Also add the `flutter_localizations` SDK dependency manually under `dependencies:` in `pubspec.yaml`:
   ```yaml
   flutter_localizations:
     sdk: flutter
   ```
1.4. Under `flutter:` in `pubspec.yaml`, enable l10n: `generate: true`.
1.5. Run `flutter pub get` and commit the updated `pubspec.yaml` + `pubspec.lock`.
1.6. Run `flutter analyze` — must report `No issues found!` before any code changes.

## 2. Localization setup (`app/l10n/`)

2.1. Create `app/l10n.yaml`:
   ```yaml
   arb-dir: l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   output-class: AppLocalizations
   ```
2.2. Create `app/l10n/app_en.arb` with `@@locale: "en"` and the following key families (English values are canonical, `@`-metadata documents each placeholder type):
   - **UI chrome:** `appTitle`, `pointsLabel`, `pointsRatio` (with `{completed}` + `{total}` int placeholders), `taskRowSemanticLabel` (with `{title}`, `{points}`, `{state}` placeholders), `taskStateChecked`, `taskStateUnchecked`, `languageToggleTooltip`.
   - **Category names:** `categoryFajr`, `categoryDhuhr`, `categoryAsr`, `categoryMaghrib`, `categoryIsha`, `categoryQiyamEvening`, `categoryQuranFasting`, `categoryMiscAdhkar`.
   - **Task titles (34 keys):** one per task from `requirements.md` §3.1, named `task<CamelCase>` (e.g. `taskFajrWakingUpAdhkar`, `taskQiyamWitr`, `taskMiscEatingDrinkingAdhkar`). Values are the exact English titles from §3.1.
2.3. Create `app/l10n/app_ar.arb` with `@@locale: "ar"` and **the same key set** as `app_en.arb`. Every value is a `TODO:` placeholder followed by a working-draft Arabic translation hint, e.g.:
   ```json
   "appTitle": "TODO: محاسبة",
   "categoryFajr": "TODO: الفجر",
   "taskQiyamWitr": "TODO: صلاة الوتر"
   ```
   The `TODO:` prefix is what the V36 merge gate scans for; the hint text is a placeholder the reviewer overwrites with the final translation. Do not omit keys — `flutter gen-l10n` warns on incomplete translations.
2.4. Run `flutter pub get` — confirm `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` is generated and `AppLocalizations` resolves in the IDE.

## 3. Core i18n plumbing (`app/lib/core/i18n/`)

3.1. Create `locale_provider.dart`:
   - `class LocaleNotifier extends Notifier<Locale?>` — `build()` returns `null` (= follow system locale). Methods: `void setLocale(Locale? l)`; `void toggle()` cycles `null` → `Locale('en')` → `Locale('ar')` → `null`.
   - `final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);`.
3.2. Create `language_toggle_button.dart`:
   - `ConsumerWidget` rendering an `IconButton` (or `TextButton`) inside `AppBar.actions`.
   - Label: when `localeProvider` is `Locale('en')` show `EN`, when `Locale('ar')` show `ع`, when `null` show the system-resolved code (`EN` or `ع`) with a subtle "auto" marker (e.g. a tiny underline).
   - Tooltip: `AppLocalizations.of(context)!.languageToggleTooltip`.
   - `onPressed`: `ref.read(localeProvider.notifier).toggle()`.

## 4. Domain layer (`lib/features/checklist/domain/`)

4.1. Create `task.dart`:
   - `enum TaskCategory { fajr, dhuhr, asr, maghrib, isha, qiyamEvening, quranFasting, miscAdhkar }`.
   - Extension `TaskCategory.titleResolver` returning a `String Function(AppLocalizations)` mapping each value to its generated getter (e.g. `fajr` → `(l) => l.categoryFajr`).
   - `class Task` — `final` fields `id` (slug), `points`, `category`, and `final String Function(AppLocalizations) titleResolver`; `const` constructor; `==` and `hashCode` based on `id`.
4.2. Create `daily_progress.dart`:
   - `class DailyProgress` — `final int completedPoints, totalPoints; final double fraction;` const constructor; factory `DailyProgress.from(List<Task> tasks, Map<String, bool> state)` that derives all three fields.
   - `int get percentInt => (fraction * 100).round();` — used by the header for display.

## 5. Data layer (`lib/features/checklist/data/`)

5.1. Create `static_task_catalog.dart` exposing `const staticTaskCatalog = <Task>[ ... ]` (use `final` if `const` is blocked by the function-reference field; preferred order: `final` with all-`const` `Task` instances if possible, else `final` list of `Task` literals).
5.2. Encode every row from `requirements.md` §3.1 in the **exact** order shown (Fajr → Dhuhr → Asr → Maghrib → Isha → Qiyam & Evening → Quran & Fasting → Misc). Stable `id` slugs use snake_case **without** dots so they map cleanly to ARB camelCase keys: e.g. `fajr_morning_adhkar` ↔ `taskFajrMorningAdhkar`, `qiyam_witr` ↔ `taskQiyamWitr`, `misc_eating_drinking_adhkar` ↔ `taskMiscEatingDrinkingAdhkar`.
5.3. Each `Task` binds its `titleResolver` to the corresponding generated getter — e.g. `Task(id: 'fajr_morning_adhkar', points: 2, category: TaskCategory.fajr, titleResolver: (l) => l.taskFajrMorningAdhkar)`.
5.4. Add a top-of-file `assert` in debug builds that `staticTaskCatalog.fold(0, (s, t) => s + t.points) == 74`.

## 6. Presentation — providers (`lib/features/checklist/presentation/providers/`)

6.1. `task_catalog_provider.dart` — `final taskCatalogProvider = Provider<List<Task>>((_) => staticTaskCatalog);`.
6.2. `checklist_state_provider.dart`:
   - `class ChecklistNotifier extends Notifier<Map<String, bool>>` with `build()` returning a fresh map seeded `false` for every task id; method `void toggle(String taskId)` that creates a new map (immutable update) with the value flipped.
   - `final checklistStateProvider = NotifierProvider<ChecklistNotifier, Map<String, bool>>(ChecklistNotifier.new);`.
6.3. `daily_progress_provider.dart` — `Provider<DailyProgress>` that reads `taskCatalogProvider` and `checklistStateProvider` and returns `DailyProgress.from(...)`.

## 7. Presentation — widgets (`lib/features/checklist/presentation/widgets/`)

7.1. `checklist_progress_header.dart`:
   - `ConsumerWidget` reading `dailyProgressProvider`.
   - Renders, top-to-bottom: percent label (`"${progress.percentInt}%"`, `headlineMedium`, semibold), `LinearProgressIndicator(value: progress.fraction)`, supporting line `AppLocalizations.of(context)!.pointsRatio(progress.completedPoints, progress.totalPoints)` (`bodySmall`, muted).
   - Outer container has comfortable padding (≥ 16 px) using `EdgeInsetsDirectional` and `Theme.of(context).colorScheme.surface`.
7.2. `task_row.dart`:
   - `ConsumerWidget` taking a `Task`.
   - Watches the `checklistStateProvider` selector for `state[task.id] ?? false`.
   - Reads `final l = AppLocalizations.of(context)!;` then `final title = task.titleResolver(l);`.
   - Renders a `CheckboxListTile` (or custom `InkWell` row) with `controlAffinity: ListTileControlAffinity.leading`, `title: Text(title)`, and a `secondary`/trailing points chip (`"+${task.points}"` plus a small `AppLocalizations.of(context)!.pointsLabel`). `onChanged` calls `ref.read(checklistStateProvider.notifier).toggle(task.id)`.
   - Semantics: `Semantics(label: l.taskRowSemanticLabel(title, task.points, isChecked ? l.taskStateChecked : l.taskStateUnchecked), toggled: isChecked, child: ...)`.
   - **No hard-coded `left`/`right` padding** — use `EdgeInsetsDirectional` and `AlignmentDirectional` so RTL flips cleanly.
7.3. `category_section.dart`:
   - Plain `StatelessWidget` accepting `(TaskCategory category, List<Task> tasks)`.
   - Renders the section header (`Padding` + `Text(_categoryTitle(context, category), style: titleMedium)`) then a `Column` of `TaskRow`s in order.
   - `_categoryTitle` is a small private helper that switches on the enum and returns the matching `AppLocalizations.category…` getter result.

## 8. Screen composition (`lib/features/checklist/presentation/checklist_screen.dart`)

8.1. `class ChecklistScreen extends ConsumerWidget`.
8.2. In `build`, read `taskCatalogProvider` and group tasks by `category` while preserving the catalog's insertion order (use a `LinkedHashMap<TaskCategory, List<Task>>`).
8.3. Compose:
   - `Scaffold` → `AppBar(title: Text(AppLocalizations.of(context)!.appTitle), actions: const [LanguageToggleButton()])`.
   - Body is a `CustomScrollView` with:
     - `SliverToBoxAdapter(child: ChecklistProgressHeader())` (or `SliverPersistentHeader` if pinning the header is preferred — see `requirements.md` §3.5).
     - One `SliverList` per category emitting a `CategorySection` for the header + each `TaskRow` underneath (use `SliverList.builder` to keep build cost flat).
8.4. Bottom safe-area padding so the last Misc Adhkar row isn't hidden under the device home indicator.

## 9. Routing & app bootstrap

9.1. Edit `app/lib/main.dart`:
   - Wrap the app root in `ProviderScope`.
   - Convert the root widget to a `ConsumerWidget` (or `Consumer` wrapping `MaterialApp.router`).
   - Read `final locale = ref.watch(localeProvider);` and pass it to `MaterialApp.router`.
   - Wire i18n on `MaterialApp.router`:
     ```dart
     locale: locale, // null falls back to system
     supportedLocales: AppLocalizations.supportedLocales,
     localizationsDelegates: AppLocalizations.localizationsDelegates,
     ```
   - Keep the existing `useMaterial3: true` + soft-green seed theme **unchanged**.
9.2. Edit `app/lib/core/routing/app_router.dart`:
   - Swap the `/` route from `HomeScreen` to `ChecklistScreen` (imported from the new feature folder).
9.3. Delete `app/lib/features/home/` in the same commit (it served only as the Phase 0 placeholder).

## 10. Static analysis & formatting

10.1. From `/app`: `dart format .` — must produce a clean diff (no changes after the first run).
10.2. From `/app`: `flutter analyze` — must report `No issues found!`.
10.3. From `/app`: `dart format --output=none --set-exit-if-changed .` — must exit 0 (this is what CI runs).
10.4. Grep guard: from `/app`, `rg "EdgeInsets\.only\(left|right"` and `rg "Alignment\.(centerLeft|centerRight)"` against `lib/features/checklist/` — must return **zero hits**. RTL-safe widgets use the `Directional` variants.

## 11. Manual verification on Web (developer machine)

11.1. `flutter run -d chrome` from `/app`.
11.2. **English path:** with system locale English (or override the toggle to `EN`), confirm the screen matches `validation.md` §1 (header at top, 8 sections rendered in roadmap order, all 34 rows visible by scrolling). Confirm RTL is **off** (AppBar title left, points chip right).
11.3. Tap rows in different categories; confirm the percentage updates atomically (no flicker, no double-render).
11.4. Tap every row in a single category (e.g. Qiyam & Evening = 11 pts); confirm header reads `11 / 74 points` and the bar reflects ~15%.
11.5. Tap **every** row in all categories; confirm `74 / 74 points` and `100%`.
11.6. **Arabic path:** tap the AppBar `EN ⇄ ع` toggle to switch to Arabic. Confirm:
   - AppBar title moves to the right edge; language toggle moves to the left edge.
   - Category headers and task titles read right-to-left.
   - Points chip lands on the *start* (left) side of each row, checkbox lands on the *end* (right) side — both auto-flipped by Material 3.
   - `LinearProgressIndicator` fills right-to-left.
   - Strings render with `TODO:` prefixes (expected this phase — they get filled before merge per V36).
11.7. **System locale path:** open Chrome DevTools → "Sensors" → set the browser locale to Arabic (`ar`), then `flutter run -d chrome` again. Confirm app opens in Arabic + RTL without touching the toggle.
11.8. Hot-restart (`R` in the Flutter CLI); confirm all rows reset to unchecked **and** the locale resets to system default — this proves no accidental persistence leak.

## 12. (Optional) Mobile spot-check

12.1. If an Android emulator is available: `flutter run -d <android-emulator-id>` — repeat the smoke test in §11 including the Arabic toggle path.
12.2. iOS verification is **not** required this phase (no new platform-specific code); note "deferred — no macOS" in the PR if applicable, same convention as Phase 0.

## 13. Pre-merge: fill Arabic translations

13.1. Open `app/l10n/app_ar.arb`. For every value with a `TODO:` prefix, replace the entire value with the final, reviewed Arabic translation.
13.2. Confirm zero `TODO:` prefixes remain: from `/app`, `rg "TODO:" l10n/app_ar.arb` returns no matches.
13.3. Re-run §10 (analyze + format) and §11 Arabic path; confirm every string is rendered.

## 14. CI

14.1. The existing `app-lint` job in `.github/workflows/ci.yml` already runs `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, and `flutter analyze`. **No workflow changes** are required for Phase 1 — `flutter pub get` triggers `gen-l10n` automatically.
14.2. Confirm on the PR that `app-lint` and `api-lint` both pass; the `api-lint` job should still be green since Phase 1 doesn't touch `/api`.

## 15. Wrap-up & handoff

15.1. Re-read `validation.md`; tick every acceptance check.
15.2. Update root `README.md` "Status" line to `Phase 1 ✅ — static daily checklist (EN + AR)`.
15.3. Add a "Specs" reference for this folder in `README.md` alongside the Phase 0 entry.
15.4. Open PR `feature/phase-1-static-daily-checklist → master`; paste a link to `specs/2026-05-12-static-daily-checklist/` in the description, list the final Arabic strings used (for native-speaker spot-review in the PR thread), and reference Phase 2 as the next planned phase.
15.5. Squash-merge once CI is green and `validation.md` checks pass (including V36 — zero `TODO:` in `app_ar.arb`).
