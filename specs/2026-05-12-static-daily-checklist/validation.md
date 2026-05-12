# Phase 1 — Static Daily Checklist · Validation

> This phase merges when **every** check below passes. Checks are mostly manual; the test harness for the checklist domain lands in Phase 2 alongside persistence.

## 1. Roadmap exit criteria

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V1 | Checklist screen renders on **Web** | `cd app && flutter run -d chrome` | Browser opens to a `Muhasabah` AppBar; progress header visible at the top; 8 category sections render in the order Fajr → Dhuhr → Asr → Maghrib → Isha → Qiyam & Evening Devotion → Quran & Fasting → Miscellaneous Adhkar |
| V2 | All 34 tasks are rendered with their point values | Scroll the screen end-to-end; count rows per category | Counts match `requirements.md` §3.1 (Fajr 6 · Dhuhr 4 · Asr 3 · Maghrib 3 · Isha 3 · Qiyam & Evening 4 · Quran & Fasting 3 · Misc 8 = **34**). Every row shows a points indicator |
| V3 | 1-tap toggle works | Tap any row | Checkbox flips state immediately; no dialog, no snackbar, no confirmation step |
| V4 | Progress updates live | Tap a 4-point row (e.g. "Two Rak'ahs of Qiyam al-Layl") | Header re-renders within the same frame: "4 / 74 points" and bar advances to ~5% |
| V5 | Progress reaches 100% | Toggle every row on | Header reads exactly "`74 / 74 points`" and "`100%`"; progress bar is fully filled |
| V6 | Progress returns to 0% | Toggle every row back off | Header reads "`0 / 74 points`" and "`0%`"; bar empty |

## 2. No-persistence guarantee

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V7 | Hot-restart resets state | With some tasks checked, press `R` in the Flutter CLI (full restart, not hot-reload) | All tasks are unchecked; header shows `0 / 74 points` |
| V8 | Process restart resets state | Close the app/browser tab fully, relaunch via `flutter run -d chrome` | All tasks unchecked. **Intentional** — Phase 2 owns persistence |
| V9 | No SQLite / Drift / storage code introduced | `git diff master -- app/` | No reference to `drift`, `sqflite`, `shared_preferences`, or filesystem writes anywhere in the diff |

## 3. State management & architecture

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V10 | Only sanctioned new runtime dependencies are added | Inspect `app/pubspec.yaml` diff vs `master` | Exactly three **new** runtime entries under `dependencies:` — `flutter_riverpod`, `flutter_localizations` (SDK), and `intl` (Phase 0 deps such as `go_router` unchanged); `pubspec.lock` reflects the additions; no other new runtime deps |
| V11 | `ProviderScope` wraps the app | Inspect `app/lib/main.dart` | `runApp(const ProviderScope(child: <MyApp>))` (or equivalent) is present |
| V12 | Providers expose the contract Phase 2 will reuse | Inspect `lib/features/checklist/presentation/providers/` | Three providers present: `taskCatalogProvider`, `checklistStateProvider` (a `NotifierProvider`), `dailyProgressProvider`. `ChecklistNotifier` has a public `void toggle(String taskId)` method |
| V13 | Feature folder layout matches `requirements.md` §3.4 | `ls app/lib/features/checklist/` and subfolders | `data/`, `domain/`, `presentation/` each present; `presentation/` has `providers/`, `widgets/`, and `checklist_screen.dart` |
| V14 | Old `home` feature is removed | `ls app/lib/features/` | `home/` does **not** exist; only `checklist/` |
| V15 | Routing points at `ChecklistScreen` | Inspect `app/lib/core/routing/app_router.dart` | The `/` route resolves to `ChecklistScreen`; no remaining import of `HomeScreen` |

## 4. UX / visual quality bar

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V16 | Material 3 + soft-green theme reused | Inspect `app/lib/main.dart` | `useMaterial3: true` and the Phase 0 seed color are **unchanged** — no new theming code introduced in Phase 1 |
| V17 | Progress header is always visible during normal scrolling | Run on Chrome, scroll | The percentage label + progress bar remain visible (either pinned at top or in the always-visible portion above the scroll viewport when the user is near the top); on shorter viewports it scrolls naturally |
| V18 | Tone is encouraging, not shaming | Read every string rendered on screen in **both locales** | No language implying failure or guilt (e.g. no "missed", "failed", "incomplete!"); category names and task titles match README §3 in English and their Arabic equivalents in `app_ar.arb` |
| V19 | No red error states | Visual inspection | Toggle state uses the Material 3 primary (soft green); no red coloring is introduced for unchecked tasks |
| V20 | Accessibility labels present and localized | Inspect Flutter's `Semantics` debugger (or grep for `Semantics(` in `task_row.dart`) in both EN and AR | Each row exposes a `Semantics` node containing the *localized* task title, points, and toggled state |

## 5. Static analysis & CI

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V21 | `flutter analyze` clean | From `/app`: `flutter analyze` | `No issues found!` |
| V22 | `dart format` clean | From `/app`: `dart format --output=none --set-exit-if-changed .` | Exit code 0 |
| V23 | `app-lint` CI job green on the PR | GitHub Actions tab on the PR | Job passes |
| V24 | `api-lint` CI job still green | GitHub Actions tab on the PR | Job passes — Phase 1 must not regress the backend lint |
| V25 | No new workflow needed | Diff `.github/workflows/` | No changes (Phase 0 CI already covers Phase 1's needs — `flutter pub get` runs `gen-l10n` automatically) |
| V25a | No hard-coded directional padding/alignment | From `/app`: `rg "EdgeInsets\.only\(left\|right" lib/features/checklist/` and `rg "Alignment\.(centerLeft\|centerRight)" lib/features/checklist/` | Zero matches — code uses `EdgeInsetsDirectional` and `AlignmentDirectional` for RTL safety |

## 6. Spec hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V26 | Decisions D1–D14 in `requirements.md` are reflected in code | PR diff review | Each decision is observable in code, config, or folder structure |
| V27 | README "Status" line updated | Inspect repo-root `README.md` | Reads `Phase 1 ✅ — static daily checklist (EN + AR)` |
| V28 | This spec folder is linked from the PR | Inspect PR description | Link to `specs/2026-05-12-static-daily-checklist/` is present |

## 7. i18n & RTL

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V29 | ARB files present and key-complete | `ls app/l10n/` | Both `app_en.arb` and `app_ar.arb` exist; every key in `app_en.arb` also exists in `app_ar.arb` (run `flutter gen-l10n --verbose` — should report 0 missing translations) |
| V30 | `AppLocalizations` is wired into `MaterialApp.router` | Inspect `app/lib/main.dart` | `locale: ref.watch(localeProvider)`, `supportedLocales: AppLocalizations.supportedLocales`, and `localizationsDelegates: AppLocalizations.localizationsDelegates` are all present |
| V31 | English path renders the full catalog | With system or override locale set to EN, run `flutter run -d chrome` | All 8 category headers in English ("Fajr", "Dhuhr", …, "Miscellaneous Adhkar"); all 34 task titles in English; AppBar reads "Muhasabah"; layout is LTR |
| V32 | Arabic path renders the full catalog | Tap the AppBar `EN ⇄ ع` toggle (or set system locale to `ar`) | All 8 category headers and all 34 task titles read in Arabic from `app_ar.arb`; layout flips to RTL |
| V33 | RTL layout flips correctly | In Arabic mode, visually inspect | (a) AppBar title aligned right; (b) language toggle button appears on the leading (left) edge of the AppBar; (c) with a **leading** checkbox: control sits at the row's **start** (physical right in RTL); title text begins at **start** and reads RTL; points chip at the row's **end** (physical left); (d) `LinearProgressIndicator` fills right-to-left |
| V34 | Language toggle works | Tap the toggle button repeatedly on a running app | Cycles `system → EN → AR → system`; UI re-renders with the new locale within one frame; in-progress checkbox state is **preserved** across the toggle (locale change is a presentation concern, not a state reset) |
| V35 | System-locale-on-first-launch honored | Hot-restart the app (`R`) with the toggle previously set to AR | After restart, locale falls back to whatever the platform reports (e.g. Chrome's `--lang=ar` or system Arabic → AR + RTL; English system → EN + LTR). Confirms session-only override per D10 |
| V36 | **All Arabic `TODO:` placeholders filled** (merge-blocking) | From `/app`: `rg "TODO:" l10n/app_ar.arb` | **Zero matches.** A non-zero count blocks merge per D11 |
| V37 | Arabic text is legible on each platform | Run on Chrome (mandatory); Android emulator if available; iOS simulator if available | Arabic glyphs render without missing-glyph boxes (`☐`/`◻`/`.notdef`); diacritics (if any) are not clipped. Platform-default font is acceptable per D12 |

## 8. Definition of Done (merge gate)

The PR is mergeable when:

- [ ] V1 – V6 (roadmap exit criteria) pass on the reviewer's machine.
- [ ] V7 – V9 (no-persistence guarantee) verified.
- [ ] V10 – V15 (state mgmt & architecture) verified by code inspection.
- [ ] V16 – V20 (UX / visual quality bar) confirmed in code review and on the running app.
- [ ] V21 – V25 (lint + CI) green on the PR; V25a (no hard-coded directional padding) confirmed.
- [ ] V26 – V28 (spec hygiene) confirmed.
- [ ] V29 – V35, V37 (i18n & RTL) verified on the running app in both locales.
- [ ] **V36 verified: zero `TODO:` placeholders remain in `app_ar.arb`.** This is a hard merge-block.
- [ ] No new runtime dependencies beyond `flutter_riverpod`, `flutter_localizations` (SDK), and `intl` — without an inline justification in the PR description.

When all boxes are checked: **squash-merge to `master`** and proceed to Phase 2 (Local Persistence with SQLite).
