# Phase 1 — Static Daily Checklist · Requirements

> **Roadmap reference:** [`spec/roadmap.md`](../../spec/roadmap.md) — Phase 1 (Static Daily Checklist, 4 days).
> **Guiding docs:** [`spec/mission.md`](../../spec/mission.md), [`spec/tech-stack.md`](../../spec/tech-stack.md), repo-root [`README.md`](../../README.md) §3.

## 1. Goal

Render the full default daily checklist from the README, grouped by category, with a 1-tap toggle per task and a live progress percentage at the top of the screen. **No persistence** — closing the app resets state. This is the visual + interaction baseline that Phase 2 (SQLite + Drift) will plug behind.

## 2. Phase Exit Criteria (from roadmap)

- The home screen renders the full task catalog grouped by category (Fajr, Dhuhr, Asr, Maghrib, Isha, Qiyam, Quran & Fasting, Misc Adhkar).
- A user can tap a task row to toggle its completion in a single tap (no modals, no confirmations).
- A daily progress bar at the top of the screen reflects `(completed points / total points) × 100` and updates immediately on toggle.
- Data does **not** persist between launches.

## 3. In Scope

### 3.1 Task catalog (hard-coded, from README §3)

The catalog is defined in code as an immutable Dart constant. Categories, items, and point values come **verbatim** from the README. Eight categories, 34 tasks, **74 total points**. The English titles below are the canonical labels; the Arabic equivalents live in `app_ar.arb` keyed by each task's stable slug (see §3.7).

| Category | Task | Points |
|---|---|---|
| **Fajr** | Waking up Adhkar | 2 |
| Fajr | Sunnah before Fajr | 2 |
| Fajr | First Congregation (Jama'ah) | 2 |
| Fajr | Post-prayer Adhkar | 2 |
| Fajr | Morning Adhkar | 2 |
| Fajr | Duha Prayer — 4 Rak'ahs | 2 |
| **Dhuhr** | Sunnah before Dhuhr — 4 Rak'ahs | 2 |
| Dhuhr | First Congregation (Jama'ah) | 2 |
| Dhuhr | Post-prayer Adhkar | 2 |
| Dhuhr | Sunnah after Dhuhr | 2 |
| **Asr** | First Congregation (Jama'ah) | 2 |
| Asr | Post-prayer Adhkar | 2 |
| Asr | Evening Adhkar | 2 |
| **Maghrib** | First Congregation (Jama'ah) | 2 |
| Maghrib | Post-prayer Adhkar | 2 |
| Maghrib | Sunnah after Maghrib | 2 |
| **Isha** | First Congregation (Jama'ah) | 2 |
| Isha | Post-prayer Adhkar | 2 |
| Isha | Sunnah after Isha | 2 |
| **Qiyam & Evening Devotion** | Two Rak'ahs of Qiyam al-Layl | 4 |
| Qiyam & Evening Devotion | Daily Quran Portion (Wird) — Two quarters | 4 |
| Qiyam & Evening Devotion | Witr Prayer | 1 |
| Qiyam & Evening Devotion | Adhkar before sleep | 2 |
| **Quran & Fasting** | Memorizing half a page | 2 |
| Quran & Fasting | Reading six quarters (~1.5 Juz') | 2 |
| Quran & Fasting | Fasting (Monday and Thursday) | 5 |
| **Miscellaneous Adhkar** | Restroom Adhkar (Entering/Leaving) | 2 |
| Miscellaneous Adhkar | Clothing Adhkar (Putting on/Taking off) | 2 |
| Miscellaneous Adhkar | Wudu (Ablution) Adhkar | 2 |
| Miscellaneous Adhkar | House Adhkar (Entering/Leaving) | 2 |
| Miscellaneous Adhkar | Mosque Adhkar (Entering/Leaving) | 2 |
| Miscellaneous Adhkar | Walking to the Mosque Adhkar | 2 |
| Miscellaneous Adhkar | Eating and Drinking Adhkar | 2 |
| Miscellaneous Adhkar | Riding/Traveling Adhkar | 2 |

> Totals: Fajr 12 · Dhuhr 8 · Asr 6 · Maghrib 6 · Isha 6 · Qiyam & Evening 11 · Quran & Fasting 9 · Misc Adhkar 16 = **74 points**.

### 3.2 Domain model (in-memory only)

- `TaskCategory` — enum (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, `qiyamEvening`, `quranFasting`, `miscAdhkar`). Display names are **not** stored on the enum — they are resolved at the presentation layer through `AppLocalizations` (see §3.7).
- `Task` — immutable value object: `id` (stable string slug, e.g. `fajr_morning_adhkar`), `points`, `category`, and `String Function(AppLocalizations l)` `titleResolver`. The resolver returns the locale-correct title at build time; the catalog binds each task to its generated getter (e.g. `(l) => l.taskFajrMorningAdhkar`).
- `DailyChecklistState` — `Map<String, bool>` keyed by `Task.id` indicating today's completion.
- `DailyProgress` — computed view model: `completedPoints`, `totalPoints`, `percent` (0–100, rounded to nearest integer for display).

### 3.3 State management (Riverpod v2)

- Introduce **Riverpod** in this phase per tech-stack — add `flutter_riverpod` to `pubspec.yaml`.
- `ProviderScope` wraps the app at `main.dart`.
- Providers live under `lib/features/checklist/presentation/providers/`:
  - `taskCatalogProvider` — `Provider<List<Task>>` returning the hard-coded catalog from §3.1.
  - `checklistStateProvider` — `NotifierProvider<ChecklistNotifier, Map<String, bool>>` exposing `toggle(taskId)` and seeded as all-false.
  - `dailyProgressProvider` — `Provider<DailyProgress>` derived from the two above.
- App-wide locale lives in a separate provider (`lib/core/i18n/locale_provider.dart`):
  - `localeProvider` — `NotifierProvider<LocaleNotifier, Locale?>` whose `null` value means "follow the system locale"; `LocaleNotifier` exposes `setLocale(Locale?)` and `toggle()` (cycles `null` → `en` → `ar` → `null`). State is **not persisted** (matches Phase 1's no-persistence rule); it resets on app launch.
- **Phase 2 contract:** the surface of `ChecklistNotifier` (`toggle`, current state shape) is what Phase 2 will keep; only the *source* moves from in-memory to Drift/SQLite. `localeProvider` will likewise gain a persisted-preference backing in Phase 2.

### 3.4 Feature folder layout

```
app/
  l10n/
    app_en.arb                     # English source strings (UI chrome + 34 task titles + 8 category names)
    app_ar.arb                     # Arabic translations — TODO placeholders this phase (see §3.7)
  l10n.yaml                        # gen-l10n config (arb-dir, template-arb-file, output-class)
  lib/
    core/
      i18n/
        locale_provider.dart       # localeProvider + LocaleNotifier (session-only)
        language_toggle_button.dart # AppBar action that cycles locale
      routing/
        app_router.dart            # unchanged from Phase 0 apart from / target
    features/
      checklist/
        data/
          static_task_catalog.dart        # hard-coded Task list (§3.1) wired to AppLocalizations getters
        domain/
          task.dart                       # Task value object + TaskCategory enum
          daily_progress.dart             # DailyProgress view model + computation
        presentation/
          providers/
            task_catalog_provider.dart
            checklist_state_provider.dart
            daily_progress_provider.dart
          widgets/
            checklist_progress_header.dart   # progress bar + % label
            category_section.dart            # category header + child rows
            task_row.dart                    # CheckboxListTile-style 1-tap row
          checklist_screen.dart              # composes the screen
```

- `home/presentation/home_screen.dart` is **replaced** by routing `/` to `ChecklistScreen`. The empty `home` feature folder is removed in the same PR.
- The generated `AppLocalizations` class (output of `flutter gen-l10n`) lives under `.dart_tool/flutter_gen/gen_l10n/` and is **not** committed.

### 3.5 UI / UX requirements

- **Layout:** `Scaffold` → `AppBar` (title from `AppLocalizations.appTitle`) → `CustomScrollView`/`ListView` with the progress header pinned at the top (as a `SliverPersistentHeader`, **or** placed as a non-pinned card immediately under the AppBar — implementation choice, must remain visible during typical scrolling of the catalog on mobile).
- **AppBar action:** a single `LanguageToggleButton` (text label `EN` or `ع`, or icon) on the trailing edge that calls `localeProvider.notifier.toggle()`. The button reflects the *active* locale (system or override). Position swaps to the leading edge automatically under RTL because Material 3 mirrors `AppBar.actions` based on `Directionality`.
- **Progress header:**
  - Big percentage label (e.g. `0%` → `100%`), Material 3 `headlineMedium` style. Digits remain Western (Latin) numerals in both locales for Phase 1; Eastern Arabic numerals are a post-MVP polish item.
  - Linear progress bar beneath (`LinearProgressIndicator`), soft-green primary color (Material 3 scheme), neutral track. The bar fills *visually correctly* in both LTR (left → right) and RTL (right → left) — `LinearProgressIndicator` does this automatically when wrapped by `Directionality`.
  - Sub-label uses `AppLocalizations.pointsRatio(completedPoints, totalPoints)` (e.g. `"12 / 74 points"` / `"12 / 74 نقطة"`).
- **Category sections:** simple section header (`AppLocalizations.category<Name>`, `titleMedium`, slight top padding). No collapsing/expanding in this phase.
- **Task rows:** full-width tappable area, leading checkbox, title on the *text-start* side (left in EN, right in AR), points pill on the *text-end* side. Use `Row` with `MainAxisAlignment.spaceBetween` rather than hard-coded `left`/`right` — RTL mirrors automatically. Whole row toggles; tapping the checkbox alone also toggles. **No** modal, **no** confirmation, **no** snackbar.
- **Tone:** copy stays neutral and encouraging — never shaming. No red error states. Arabic copy follows the same tone (encouraging, not commanding).
- **Empty/loading:** not applicable — catalog is synchronous and always non-empty.
- **Accessibility:** every row exposes `Semantics(label: AppLocalizations.taskRowSemanticLabel(title, points, isChecked), toggled: ...)` so screen readers announce the localized phrase in either language.

### 3.6 Theming

- Reuse the Material 3 + soft-green seed from Phase 0 (`app/lib/main.dart`). **No** new theme constants in this phase.
- No custom font assets — Arabic text renders with the platform's default Arabic system font on Android, iOS, and Web. Typography may differ slightly across platforms; this is accepted for Phase 1 (see Risks §7).
- Material 3 automatically flips component layouts (AppBar, ListTile, LinearProgressIndicator) when the root `Directionality` is RTL; no manual mirroring is needed in this phase.

### 3.7 Internationalization (English + Arabic, RTL)

**Both English and Arabic are first-class in Phase 1.** Every user-visible string — AppBar title, language toggle, progress header label, category names, task titles, accessibility labels — is localized.

- **Setup:**
  - Add `flutter_localizations` (Flutter SDK) and `intl` to `pubspec.yaml`.
  - Add `app/l10n.yaml` with `arb-dir: l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`, `synthetic-package: true` (default).
  - Add `app/l10n/app_en.arb` (template, source-of-truth keys + English values) and `app/l10n/app_ar.arb` (placeholders this phase).
  - `flutter gen-l10n` runs automatically on `flutter pub get`; the generated `AppLocalizations` class is consumed via `AppLocalizations.of(context)`.

- **Locale selection (covers your "all app and content" requirement):**
  - **Default:** follow the system locale. If the device is set to Arabic (any region), the app opens in Arabic + RTL. Otherwise English.
  - **In-app override:** an AppBar toggle (`EN ⇄ ع`) cycles between `null` (system), `Locale('en')`, and `Locale('ar')`. The override is stored in `localeProvider` and is **session-only** — closing the app reverts to system locale. Phase 2 will persist it.
  - `MaterialApp.router` is wired with:
    - `locale: ref.watch(localeProvider)` (when `null`, Flutter falls back to system).
    - `supportedLocales: const [Locale('en'), Locale('ar')]`.
    - `localizationsDelegates: AppLocalizations.localizationsDelegates`.

- **Key naming convention (in ARB files):**
  - UI chrome: `appTitle`, `pointsLabel`, `pointsRatio` (with `{completed}` and `{total}` placeholders), `taskRowSemanticLabel` (with `{title}`, `{points}`, `{state}` placeholders), `languageToggleTooltip`.
  - Category names: `categoryFajr`, `categoryDhuhr`, `categoryAsr`, `categoryMaghrib`, `categoryIsha`, `categoryQiyamEvening`, `categoryQuranFasting`, `categoryMiscAdhkar`.
  - Task titles: `task<CamelCaseFromId>` for each of the 34 tasks — e.g. `taskFajrWakingUpAdhkar`, `taskQiyamWitr`, `taskMiscEatingDrinkingAdhkar`. The slug ↔ key mapping is 1:1 and stable; the catalog binds each task to its getter.

- **Arabic translations source:**
  - **You will provide the Arabic translations.** This phase commits `app_ar.arb` with **explicit `TODO:` placeholders** for every value (e.g. `"taskFajrMorningAdhkar": "TODO: أذكار الصباح"`). The PR description must include the final, reviewed Arabic strings; the merge gate (V36 in `validation.md`) blocks if any `TODO:` prefix remains.
  - Until those placeholders are filled, the Arabic build is fully functional but reads "TODO: …" for every string — sufficient for visual/RTL verification on developer machines.

- **RTL audit (this phase):**
  - Manually verify on Web (`flutter run -d chrome`) with the in-app toggle set to Arabic that: AppBar title sits on the right; the language toggle moves to the left; category headers and task titles read right-to-left; the progress bar fills right-to-left; the points chip lands on the text-end (left) side of each row.

- **Out of i18n scope this phase:**
  - Eastern Arabic-Indic digits (٠١٢…) — Phase 1 uses Western digits in both locales for now.
  - Persisted language preference — owned by Phase 2.
  - Translation review by a native Arabic speaker — owned by the reviewer / you before merge.
  - Pluralization rules for Arabic (which has 6 plural forms) — Phase 1 uses simple `{count}` interpolation in the `pointsRatio` string; full Arabic plural categories deferred to post-MVP polish.

## 4. Out of Scope (explicitly deferred)

- Any persistence (SQLite, `drift`, repositories, daily-log table) → **Phase 2**. Includes persisting the language preference.
- Day switching, history, "On this day" navigation → **Phase 3**.
- Charts, dashboard, heatmap → **Phase 4**.
- Notifications → **Phase 5**.
- Auth, backend `/v1/tasks` endpoint → **Phase 6**.
- Custom user tasks, hide/disable defaults, editing point values → **Phase 7**.
- Eastern Arabic-Indic digits (٠١٢…) for the points display → post-MVP polish.
- Full Arabic plural-category handling (Arabic has 6 plural forms) → post-MVP polish.
- Native-speaker Arabic copy review → handled inline before merge (see V36).
- Animations on toggle (beyond what Material 3 ships by default).
- Dark mode.
- Custom Arabic font asset (Noto Naskh / Cairo / IBM Plex Sans Arabic) → post-MVP if cross-platform typography drift proves objectionable.

## 5. Decisions Recorded This Phase

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Task catalog source | Hard-code verbatim from repo-root `README.md` §3 (8 categories, 34 tasks, 74 points) | README is the user-confirmed source of truth; matches roadmap mandate |
| D2 | Point values | Use README values exactly — predominantly 2 pts, with Qiyam=4, Quran wird=4, Witr=1, Fasting=5 | Avoids spec drift; later phases can re-tune via the same constant |
| D3 | Categories | 8 sections (Fajr, Dhuhr, Asr, Maghrib, Isha, Qiyam & Evening Devotion, Quran & Fasting, Misc Adhkar) | Matches roadmap ("Fajr, Dhuhr, Asr, Maghrib, Isha, Qiyam, Quran & Fasting, Misc") and README grouping |
| D4 | State management | Introduce **Riverpod v2** (`flutter_riverpod`) in Phase 1 rather than deferring to Phase 2 | Per tech-stack; Phase 2 only swaps the data source behind a stable notifier API |
| D5 | Feature folder | New `lib/features/checklist/` with `data/` `domain/` `presentation/`; existing `home` feature is replaced | Clean-architecture-lite, matches Phase 0 §3.2 conventions |
| D6 | Routing | `go_router` `/` route swapped from `HomeScreen` → `ChecklistScreen` | Single-route app this phase; multi-route navigation arrives in Phase 3 |
| D7 | Progress rounding | Display percentage as integer (`round()`); internal computation kept as double | Mission "calm by design" — avoids twitchy decimal updates as tasks toggle |
| D8 | Persistence | None — state lives in a `Notifier`, dies with the process | Explicit phase boundary; Phase 2 owns SQLite wiring |
| D9 | i18n scope | English **and** Arabic are first-class from Phase 1; every user-visible string is localized | Mission promises Arabic from day one; tech-stack lists `flutter_localizations` + ARB; deferring to "post-MVP polish" would force a larger refactor of every widget later |
| D10 | Locale selection | System locale on first launch **+** an AppBar toggle (`EN ⇄ ع`) for the active session | Maximum user agency without persistence; persistence is owned by Phase 2 |
| D11 | Arabic translation source | User-supplied; this phase commits `app_ar.arb` with `TODO:` placeholders that **must** be filled before merge (gated by V36) | Reviewer is the Arabic source of truth; AI-drafted strings risk doctrinal/terminology drift |
| D12 | Arabic font | Use the platform-default Arabic system font on Android/iOS/Web; no bundled font assets | Zero asset footprint; cross-platform typography drift is acceptable for Phase 1 and revisitable post-MVP |
| D13 | Numerals | Western digits (0–9) for the percentage and points ratio in both locales | Eastern Arabic-Indic digits add formatting complexity (`intl` `NumberFormat`); deferred to polish |
| D14 | RTL layout strategy | Rely on Material 3's automatic RTL flipping via root `Directionality`; no manual mirroring | Standard Flutter idiom; we author widgets with `start`/`end` semantics rather than `left`/`right` |

## 6. Context & Assumptions

- Phase 0 deliverables are already on `master`: Flutter app builds, `go_router` `/` route exists, Material 3 soft-green theme is configured.
- `flutter_localizations` is a Flutter SDK component (no extra runtime dep cost); `intl` is added as the only new pub.dev dependency for i18n.
- The branch follows the convention `feature/phase-<n>-<slug>` — this branch is `feature/phase-1-static-daily-checklist`.
- The reviewer has a working dev environment per the root `README.md` (Flutter stable + Docker for the API, though the API is **not exercised** in Phase 1).
- This spec folder (`specs/2026-05-12-static-daily-checklist/`) is the source of truth for the feature and will be linked from the PR description.

## 7. Risks / Open Questions

- **R1:** Riverpod has a small learning surface for reviewers new to it. Mitigation: keep the providers minimal and idiomatic; link to `riverpod.dev` quickstart in the PR description.
- **R2:** ~~README task titles are in English; we defer i18n.~~ Superseded by D9 — Arabic is in scope. New risk: Arabic strings ship as `TODO:` placeholders until you fill them; the merge gate (V36) blocks if any remain.
- **R3:** The Misc Adhkar category contains 8 tasks worth 16 points (~22% of the daily total). If user testing later finds this dominates the bar, a re-tuning pass can land in Phase 7 (Customization). Not blocking now.
- **R4:** No persistence is intentional — but means QA must explicitly verify that closing/reopening the app **does** reset progress (see `validation.md` V8). Documenting this so it isn't mistaken for a regression in Phase 2 review.
- **R5:** Cross-platform Arabic typography drift. Without a bundled font, Android (Roboto fallback → Noto Naskh), iOS (system Arabic font), and Web (browser default) render Arabic slightly differently. Mitigation: explicitly accepted in D12; revisit post-MVP if visual inconsistency is reported.
- **R6:** RTL audit is manual this phase — easy to miss subtle asymmetries (e.g. a hard-coded `EdgeInsets.only(left: …)` instead of `EdgeInsetsDirectional.only(start: …)`). Mitigation: V32–V34 in `validation.md` enumerate the specific things to eyeball; code review enforces `EdgeInsetsDirectional` / `AlignmentDirectional` usage.
- **R7:** `flutter gen-l10n` generates code that imports from a synthetic package; some IDEs (older VS Code Dart extension versions) misreport unresolved imports. Mitigation: run `flutter pub get` once after pulling the branch; document this in the PR description if encountered.
