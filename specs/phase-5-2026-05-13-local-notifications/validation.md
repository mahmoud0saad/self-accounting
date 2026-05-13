# Phase 5 — Local Notifications · Validation

> This phase merges when **every** check below passes. One automated test suite (V14) is the mandatory gate; the rest are manual but must be verified end-to-end before opening the PR for review.

---

## 1. Roadmap exit criteria

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V1 | Per-task notification toggles exist | Open Settings → expand any category tile. | Each of the category's tasks shows an individual `SwitchListTile`. Toggling one task off, cold-restarting, and returning to Settings shows it still off. |
| V2 | Default schedule covers all 8 category windows | Fresh DB, open Settings → Notifications. | All 8 categories render with the seeded default times: Fajr 05:00, Dhuhr 13:00, Asr 16:00, Maghrib 18:30, Isha 20:00, Qiyam 21:00, Quran/Fasting 06:00, Adhkar 07:30. All are enabled by default. |
| V3 | Times configurable via time pickers | Tap the time chip on any category tile. | Native `showTimePicker` dialog opens; selecting a new time updates the chip label; time persists after cold-restart. |
| V4 | EOD summary fires when completion < 50 % | Complete < 50 % of today's tasks; set EOD time to 2 min from now; wait. | The EOD notification fires (Windows: Action Center; Web: browser notification). Body matches `notifEodBody` with the correct percent. |
| V5 | EOD summary does **not** fire when completion ≥ 50 % | Complete ≥ 50 % of today's tasks; set EOD time to 2 min from now; wait. | No EOD notification fires. |
| V6 | Notifications fire reliably on Windows | Run `plan.md` group 15 smokes. | All category and EOD smokes in §15.5–§15.8 pass. |
| V7 | Notifications fire reliably on Web | Run `plan.md` group 16 smokes. | Category notification fires in browser (§16.3). |

## 2. Navigation — Settings tab

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V8 | Settings is the 3rd bottom-nav destination | Launch the app. | `NavigationBar` shows exactly **3** destinations: Checklist, Dashboard, Settings. Tapping Settings routes to `/settings`. |
| V9 | State preserved across tab switches | Scroll Checklist, switch to Settings, switch back. | Checklist scroll position is unchanged (`indexedStack` guarantee). |
| V10 | Settings label localizes | Toggle to Arabic. | Settings tab label shows the Arabic copy (or `TODO:` before V38 clears). |
| V11 | Routes resolve directly | Open `http://localhost:<port>/#/settings` in Chrome from a cold session. | App boots into the Settings tab; bottom nav shows tab 2 selected; Checklist and Dashboard branches are also mounted. |

## 3. Notification permission onboarding

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V12 | Onboarding screen appears on first cold launch | Cold-launch on a fresh DB. | The `/onboarding/notifications` route renders before the shell; the bottom nav is **not** visible. |
| V13 | "Enable notifications" path | Tap "Enable notifications". | Platform permission flow fires. `notification_onboarding_done` is set to `true`. App navigates to `/`; bottom nav appears. |
| V14 | "Not now" path | Tap "Not now". | No permission prompt. `notification_onboarding_done` set to `true`. App navigates to `/`. |
| V15 | Onboarding never repeats | Cold-restart after completing onboarding (either path). | App opens directly to `/`; onboarding screen is never shown again. |
| V16 | Onboarding copy is niyyah-first | Read the onboarding screen text. | Heading matches `onboardingNotifTitle`; body matches `onboardingNotifBody` — encouraging, not coercive. |

## 4. Category notification schedules

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V17 | Category master toggle cancels notifications for that category | Disable Fajr. Set Fajr time to 2 min from now. Wait. | No Fajr notification fires. |
| V18 | Re-enabling reschedules the category | Re-enable Fajr. Wait until the next Fajr time. | Fajr notification fires. |
| V19 | Updating time reschedules | Change Dhuhr from 13:00 to 2 min from now. | Notification fires at the updated time; the old 13:00 slot does not fire. |
| V20 | Changed times persist across cold-restart | Update Asr to 15:45. Cold-restart. Open Settings. | Asr time chip shows `15:45`. |

## 5. Per-task notification toggles

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V21 | Task toggle persists across cold-restart | Toggle one task off in Fajr. Cold-restart. Open Settings → Fajr. | The toggled-off task still shows as off. |
| V22 | Disabled task excluded from notification body | Disable all but one Dhuhr task. Set Dhuhr time to 2 min from now. Wait. | Notification body lists only the single enabled task. |
| V23 | "All tasks muted" warning appears | Toggle off every task in Maghrib. | A warning item (icon + `"All tasks muted"` text) appears as the first expanded row of the Maghrib tile. |
| V24 | All-tasks-muted category does not fire | With all Maghrib tasks muted, set Maghrib time to 2 min from now. Wait. | No Maghrib notification fires. |

## 6. End-of-day summary

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V25 | EOD toggle persists | Toggle EOD off. Cold-restart. | EOD row shows the toggle in the off state. |
| V26 | EOD time configurable | Tap the EOD time chip; select 22:00. Cold-restart. | EOD chip displays `22:00`. |
| V27 | EOD body copy is niyyah-first | Trigger an EOD notification with < 50 % completion. | Body matches `notifEodBody` — encouraging, never shaming. |
| V28 | 50 % threshold is not user-configurable | Inspect the Settings screen. | No slider, input field, or picker for the EOD threshold is present anywhere in the UI. The caption `settingsEodThresholdNote` reads `"Fires when daily completion is below 50 %."` |

## 7. Platform — Windows

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V29 | App builds for Windows | `flutter build windows --debug` | Build succeeds; no `flutter_local_notifications` linker or COM registration errors. |
| V30 | Category notification fires in Action Center | `plan.md` §15.5 | A Windows toast notification appears in the Action Center with the correct category title and task body. |
| V31 | EOD notification fires in Action Center | `plan.md` §15.7 | EOD toast appears. |
| V32 | Cancellation works on Windows | `plan.md` §15.9 (global off) | No notification fires after global toggle is turned off; scheduled alarms are cancelled. |
| V33 | Cold-restart preserves notification schedule | Schedule Dhuhr to 2 min from now; cold-restart before it fires. | After restart, Dhuhr notification still fires at the scheduled time (`zonedSchedule` survives app restart). |

## 8. Platform — Web

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V34 | Notification fires in Chrome | `plan.md` §16.3 | Browser notification bell appears in Chrome. |
| V35 | Permission-denied banner shows | `plan.md` §16.5 | Settings screen shows `"Notifications blocked in browser settings"` banner when Chrome has notifications blocked for the domain and the global toggle is on. |
| V36 | Web limitation banner is present | Open Settings on Web. | `settingsWebNotificationNote` banner (`"Notifications require the app tab to be open."`) is visible. Banner is **absent** on Windows. |
| V37 | No console errors on Web | Run `plan.md` §16.1–§16.6. | Chrome DevTools console shows no uncaught errors from `dart:js_interop` or `WebNotificationService`. |
| V38 | Tab-close limitation is documented | Confirm L1 behaviour (§16.6). | After closing and re-opening the tab, notifications that were scheduled before the close do not arrive — the `Timer` was lost. This is expected. A comment in `web_notification_service.dart` documents this. |

## 9. Schema & repository

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V39 | Schema version is 2 | `rg "schemaVersion" app/lib/core/database/app_database.dart` | Single declaration `schemaVersion = 2`. |
| V40 | Migration does not corrupt existing data | Start from a Phase 4 DB with real `daily_logs`. Run Phase 5 build. Open the Checklist and Dashboard. | All historical data, streaks, and dashboard charts display correctly after the v2 migration. |
| V41 | Mandatory test passes | `flutter test test/features/settings/notification_settings_repository_test.dart` | All 7 test cases pass. |
| V42 | All prior mandatory tests still pass | `flutter test test/data/ test/domain/ test/features/dashboard/` | No regressions in `drift_checklist_repository_test`, `drift_history_repository_test`, `streak_calculator_test`, `dashboard_aggregator_test`, `dashboard_range_picker_test`. |

## 10. Provider plumbing

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V43 | `notificationServiceProvider` returns correct implementation | Inspect the provider on each platform. | On Web: `WebNotificationService`. On Windows: `NativeNotificationService`. No `kIsWeb` check leaks into `notification_scheduler.dart`. |
| V44 | `syncAll()` called on cold start | Add a temporary `debugPrint`; launch the app. | `syncAll()` runs once after the DB is open and l10n is available. |
| V45 | Settings change triggers `syncAll()` | Toggle a category; observe via `debugPrint`. | `syncAll()` is re-invoked after each settings write. The notification schedule is updated immediately. |

## 11. Localization & dependency hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V46 | All 18 Phase 5 ARB keys exist in both locales | `rg '"navSettingsLabel"\|"settingsTitle"\|"settingsNotificationsTitle"\|"settingsNotificationsGlobalToggleLabel"\|"settingsCategoryScheduleTimeLabel"\|"settingsEodToggleLabel"\|"settingsEodTimeLabel"\|"settingsEodThresholdNote"\|"settingsWebNotificationNote"\|"settingsAboutTitle"\|"settingsVersionLabel"\|"onboardingNotifTitle"\|"onboardingNotifBody"\|"onboardingNotifEnableButton"\|"onboardingNotifSkipButton"\|"notifCategoryBody"\|"notifEodBody"\|"settingsTaskNotifToggleA11y"' app/l10n/` | Each key appears **once** in `app_en.arb` and **once** in `app_ar.arb`. Total key counts match between the two files. |
| V47 | Zero pending Arabic placeholders | `rg "TODO:" app/l10n/app_ar.arb` | **Zero** matches. |
| V48 | Placeholder metadata is correct | Inspect `@settingsCategoryScheduleTimeLabel`, `@notifEodBody`, `@settingsTaskNotifToggleA11y` metadata blocks. | Each declares its `placeholders` with the correct `type` (String vs int per `requirements.md` §3.12). |
| V49 | Exactly three new top-level dependencies | `git diff master -- app/pubspec.yaml` | Only `flutter_local_notifications`, `flutter_timezone`, and `package_info_plus` are added under `dependencies:`. No other new top-level packages. |

## 12. Lints, format & RTL guard

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V50 | `flutter analyze` is clean | `flutter analyze` from `/app` | `No issues found!` |
| V51 | `dart format` is clean | `dart format --output=none --set-exit-if-changed .` from `/app` | Exit code `0`. |
| V52 | RTL guard — no directional `EdgeInsets` | `rg "EdgeInsets\.only\(left\|right" app/lib/features/settings/ app/lib/features/notifications/` | **Zero** hits. |
| V53 | No raw hex colors | `rg "Color\(0x" app/lib/features/settings/ app/lib/features/notifications/` | **Zero** hits. All colors flow from `ColorScheme`. |
| V54 | Single source for onboarding key | `rg "notification_onboarding_done" app/lib/` | Appears only in `AppSettingsRepository` (definition) and `notification_settings_repository_test.dart`. No bare string elsewhere. |

## 13. Accessibility

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V55 | Per-task toggles have descriptive a11y labels | Focus a task toggle with TalkBack / VoiceOver / keyboard. | Screen reader announces the `settingsTaskNotifToggleA11y` value (e.g., `"Enable notification for Fajr prayer"`). |
| V56 | Onboarding buttons are announced correctly | Inspect the onboarding screen with a screen reader. | Primary button announces `"Enable notifications"` as a button; secondary announces `"Not now"` as a button. |
| V57 | Time picker is accessible | Open `showTimePicker` and navigate via keyboard. | Dialog is fully navigable; hours and minutes selectable without a pointer. |
| V58 | Category tiles announce enabled state | Focus the category tile header with a screen reader. | Reader speaks the category name and `"enabled"` or `"disabled"` state based on the `Semantics` wrapper. |

## 14. PR hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V59 | PR description links the spec folder | Inspect PR body. | Body contains a link to `specs/phase-5-2026-05-13-local-notifications/`. |
| V60 | PR description records the platform scope | Inspect PR body. | Body notes: "Validated on Web (Chrome) and Windows. Android/iOS deferred to Phase 6 onboarding review." |
| V61 | PR description records the schema bump | Inspect PR body. | Body notes: "Drift schema v1 → v2; new tables: `category_notification_schedules`, `task_notification_toggles`, `app_settings`." |
| V62 | PR description records the new dependencies | Inspect PR body. | Body lists `flutter_local_notifications`, `flutter_timezone`, `package_info_plus`. |
| V63 | Phase 6 handoff note | Inspect PR body. | Body mentions: "Android/iOS notification permission flows added in Phase 6; `app_settings` table absorbs sync-preference keys without further migration." |
| V64 | README status line updated | `git diff master -- README.md` | Status line reads `Phase 5 ✅ — local notifications, settings screen, MVP shipped (Web + Windows)` and a link to this spec folder is added alongside Phase 0–4. |
| V65 | CI is green | GitHub Actions PR checks | `app-lint`, `app-test`, and `api-lint` all green at squash-merge time. |

---

### Notes for the reviewer

- Phase 5 completes the MVP feature set. The public release candidate is ready after this phase merges.
- Three new dependencies: `flutter_local_notifications` (spec-declared since Phase 0), `flutter_timezone` (required by the scheduler), `package_info_plus` (About section).
- The Drift schema bumps from v1 to v2 with an additive-only migration — no existing rows are touched.
- Web notifications use a `dart:js_interop` shim + `Timer` scheduling. They fire only while the app tab is active (limitation L1, documented in Settings and §3.10 of requirements). This is expected behaviour, not a bug.
- The per-task toggle granularity (D1) means Settings has up to 34 toggle rows across 8 expandable sections. The `ExpansionTile` design keeps the initial view compact; no scrolling is required to see all 8 category headers.
- The Phase 4 `RootShell` extension is minimal: one `NavigationDestination` appended and one `StatefulShellBranch` added. The Checklist and Dashboard branches are untouched.
- The `app_settings` key-value table is intentionally open-ended — it is designed to absorb Phase 6 sync preferences, Phase 7 task-display preferences, and beyond without a further migration.
