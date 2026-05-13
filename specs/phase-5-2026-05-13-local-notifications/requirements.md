# Phase 5 — Local Notifications · Requirements

> **Roadmap reference:** [`spec/roadmap.md`](../../spec/roadmap.md) — Phase 5 (Local Notifications, 3 days) · **MVP shipped at end of this phase**.
> **Guiding docs:** [`spec/mission.md`](../../spec/mission.md), [`spec/tech-stack.md`](../../spec/tech-stack.md).
> **Prior phase:** [`specs/phase-4-2026-05-13-dashboard-and-charts/`](../phase-4-2026-05-13-dashboard-and-charts/) — Phase 4 (Dashboard & Charts).

## 1. Goal

Deliver the **last feature gate before the public MVP**: gentle, user-controlled nudges that remind the user to complete their worship tasks throughout the day — without shame and without requiring a backend. This phase adds a dedicated **Settings screen** (the 3rd bottom-navigation tab), a one-time **permission onboarding screen**, **per-task notification toggles**, configurable **notification times per category window**, and an **end-of-day summary** if today's completion remains below 50 %.

At the end of this phase the app is **feature-complete for solo, offline use** and is ready for the public MVP release candidate.

## 2. Phase Exit Criteria (from roadmap)

- User can enable/disable notifications per individual task (finer than per-category; decision D1).
- Default schedule covers the 5 prayer windows + morning/evening Adhkar + pre-sleep Adhkar.
- Times configurable via simple time pickers (no prayer-time API yet).
- End-of-day summary notification (9:30 PM default) if completion < 50 % (threshold fixed; time configurable per D2).
- **Validated on:** Web (Chrome) and Windows (decision D5; Android/iOS deferred).
- **Exit:** Notifications fire reliably on both platforms. App is feature-complete for solo, offline use → **public MVP release candidate**.

## 3. In Scope

### 3.1 Navigation — Settings screen as 3rd bottom-nav tab (D3)

`RootShell` (Phase 4's `app/lib/features/shell/presentation/root_shell.dart`) gains a third `NavigationDestination`. No routing refactor is needed — the existing `StatefulShellRoute.indexedStack` just receives a third branch:

| Tab | Icon (selected / unselected) | Route | Body |
|---|---|---|---|
| **Checklist** | `checklist_rounded` / `checklist` | `/` | Phase 1–4 `ChecklistScreen` (unchanged) |
| **Dashboard** | `insights_rounded` / `insights` | `/dashboard` | Phase 4 `DashboardScreen` (unchanged) |
| **Settings** | `settings_rounded` / `settings` | `/settings` | New `SettingsScreen` |

The Checklist and Dashboard branches are unchanged; only a third branch is appended.

### 3.2 Notification permission onboarding (D4)

A mini-onboarding screen is shown **once**, on the first cold launch after Phase 5 is installed, to explain and request the platform's notification permission.

**Trigger logic:**
- `AppSettingsRepository` stores a `bool` flag `notification_onboarding_done` in the new `app_settings` Drift table (§3.4).
- On cold launch, if `notification_onboarding_done == false`, the router redirects to `/onboarding/notifications` before the shell renders.
- The onboarding screen is a **separate top-level route** outside the `StatefulShellRoute`; the bottom nav is not visible during it.

**Two buttons:**
- **"Enable notifications"** → calls `NotificationService.requestPermission()` → marks `notification_onboarding_done = true` → navigates to `/`.
- **"Not now"** → marks `notification_onboarding_done = true` → navigates to `/`. (User can enable later from Settings.)

### 3.3 Domain model

Three new value objects in `app/lib/features/settings/domain/`:

```dart
class CategoryNotificationSchedule {
  const CategoryNotificationSchedule({
    required this.category,
    required this.enabled,
    required this.hour,
    required this.minute,
  });
  final TaskCategory category;
  final bool enabled;  // master toggle for the entire category window
  final int hour;      // 0–23
  final int minute;    // 0–59
}

class TaskNotificationToggle {
  const TaskNotificationToggle({
    required this.taskId,
    required this.notificationsEnabled,
  });
  final int taskId;
  final bool notificationsEnabled;
}

class EodSummarySettings {
  const EodSummarySettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
  final bool enabled;
  final int hour;   // default 21
  final int minute; // default 30
  // Threshold is fixed at 50 % and is not user-configurable (D2).
  static const int thresholdPercent = 50;
}
```

All three classes have `const` constructors and `==` / `hashCode` overrides across all fields.

### 3.4 Drift schema — v2 (D7)

Two new Drift tables appended in a `MigrationStrategy` that runs for `from == 1 && to == 2`. The DB schema version bumps from `1` → `2` in `app/lib/core/database/app_database.dart`.

#### `category_notification_schedules`

| Column | Type | Notes |
|---|---|---|
| `category` | `TextColumn`, PK | `TaskCategory.name` enum string |
| `enabled` | `BoolColumn` | default `true` |
| `hour` | `IntColumn` | 0–23; seeded from `kDefaultCategoryTimes` map (§3.5) |
| `minute` | `IntColumn` | 0–59; seeded from same map |

Seeded on migration with one row per `TaskCategory` enum value (8 rows).

#### `task_notification_toggles`

| Column | Type | Notes |
|---|---|---|
| `task_id` | `IntColumn`, PK | Matches `tasks.id` in the static catalog |
| `notifications_enabled` | `BoolColumn` | default `true` |

Seeded on migration with one row per task in the static catalog (34 rows, all `notifications_enabled = true`).

#### `app_settings`

| Column | Type | Notes |
|---|---|---|
| `key` | `TextColumn`, PK | Arbitrary key string |
| `value` | `TextColumn` | Stored as a plain string (bool → `"true"/"false"`, int → decimal string) |

Used for: `notification_onboarding_done`, `eod_enabled`, `eod_hour`, `eod_minute`. Deliberately open-ended so Phase 6+ can add settings keys without another migration.

### 3.5 Default category notification times

| Category | Default time | Rationale |
|---|---|---|
| `fajr` | 05:00 | Pre-sunrise window |
| `dhuhr` | 13:00 | Post-noon |
| `asr` | 16:00 | Late afternoon |
| `maghrib` | 18:30 | Post-sunset (approximate) |
| `isha` | 20:00 | Evening prayer |
| `qiyamEvening` | 21:00 | Evening Adhkar / Qiyam start |
| `quranFasting` | 06:00 | Post-Fajr Quran window |
| `miscAdhkar` | 07:30 | Morning Adhkar |

These are defaults only; the user changes them via time pickers in Settings.

### 3.6 Per-task notification toggle (D1)

Each of the 34 tasks in the static catalog has an individual toggle in the Settings screen that controls whether the task is included in its category's notification payload.

**Behaviour rules:**
- If a category's master toggle is off (`CategoryNotificationSchedule.enabled == false`), no notification fires for any task in that category, regardless of individual task toggles.
- If a category is enabled but a task's toggle is off, that task is excluded from the notification body text.
- If every task in a category has its toggle off, the category schedule becomes effectively silent; a warning subtitle appears on that category tile in Settings (e.g., "All tasks muted").

### 3.7 End-of-day summary notification (D2)

A single daily notification fires at the configured time if `(completed_enabled_tasks / total_enabled_tasks) < 0.50`.

- The **50 % threshold is not configurable** in Phase 5 (D2).
- The **time defaults to 21:30** and is configurable via a time picker in Settings.
- Notification body: `"You're at {percent}% today. A few minutes of Adhkar can change the day."` — mission-aligned, niyyah-first copy.
- The threshold check runs **at send time** (not at schedule time) — the scheduler reads the current completion % when the notification fires.
- EOD uses a separate notification ID (200) from category schedules (100–107).

### 3.8 Settings screen layout

`app/lib/features/settings/presentation/settings_screen.dart` — `ConsumerStatefulWidget`:

- `CustomScrollView` with `SliverAppBar` (`settingsTitle`, pinned).
- **Section A — Notifications** (card):
  - **Global on/off switch** (`settingsNotificationsGlobalToggleLabel`). Off → `cancelAll()`; on → `syncAll()`.
  - **EOD summary row**: toggle + time picker chip + `settingsEodThresholdNote` caption.
  - **Web-only banner** (`settingsWebNotificationNote`): visible only when `kIsWeb`.
  - **8 `ExpansionTile`s**, one per `TaskCategory`. Header: category icon + localized name + enabled/disabled `Switch` + scheduled-time chip. Expanded: per-task `SwitchListTile`s.
- **Section B — About** (card): `package_info_plus`-driven version string.

### 3.9 Notification scheduler service

```dart
abstract class NotificationService {
  Future<bool> requestPermission();
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}
```

Two implementations resolved at runtime via `notificationServiceProvider`:

| Platform check | Implementation | Backend |
|---|---|---|
| `kIsWeb` | `WebNotificationService` | `dart:js_interop` + `Timer` |
| `Platform.isWindows` (else) | `NativeNotificationService` | `flutter_local_notifications` |

#### Notification IDs

| Source | ID range | Formula |
|---|---|---|
| Category schedules | 100–107 | `100 + TaskCategory.values.indexOf(category)` |
| EOD summary | 200 | Fixed |

### 3.10 Platform behavior — Web

`flutter_local_notifications` does not support Web. `WebNotificationService` uses the browser [Notifications API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API) via `dart:js_interop`:

```dart
@JS('Notification')
@staticInterop
class _JSNotification {
  external static Object requestPermission();
  external factory _JSNotification(String title, JSObject options);
}
```

**Scheduling strategy:** a `Timer` is computed to the next occurrence of each `hour:minute` and fires the notification. After firing, it re-arms for 24 hours.

**Documented limitation (L1):** Browser notifications only fire while the app tab is active (no service worker in Phase 5). A persistent banner `settingsWebNotificationNote` is shown in the Settings Notifications section when `kIsWeb`, so the user is not surprised.

### 3.11 Platform behavior — Windows

`NativeNotificationService` wraps `flutter_local_notifications`:

- `FlutterLocalNotificationsPlugin.zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time` for daily repeating notifications.
- Only `WindowsInitializationSettings` is active; `AndroidInitializationSettings` / `DarwinInitializationSettings` are included for compilation completeness on other targets.
- Windows runner setup: the app must declare a `GUID` and register the notification activator COM class in `app/windows/runner/main.cpp` per the `flutter_local_notifications` Windows README.

**Notification format:**
- Title: localized category name.
- Body: up to 3 enabled task names joined by `, `; if more than 3 enabled tasks, `"{n} tasks ready."`.

### 3.12 New & modified localization keys

18 new keys added to both `app_en.arb` and `app_ar.arb`. Arabic ships as `TODO: …` per project convention:

| Key | English value | Notes |
|---|---|---|
| `navSettingsLabel` | `Settings` | Bottom nav 3rd tab |
| `settingsTitle` | `Settings` | AppBar title |
| `settingsNotificationsTitle` | `Notifications` | Section header |
| `settingsNotificationsGlobalToggleLabel` | `Enable all notifications` | Global on/off |
| `settingsCategoryScheduleTimeLabel` | `{category} · {time}` | Category time chip; placeholders: `category` (String), `time` (String) |
| `settingsEodToggleLabel` | `End-of-day summary` | EOD toggle label |
| `settingsEodTimeLabel` | `At {time}` | EOD time chip; placeholder: `time` (String) |
| `settingsEodThresholdNote` | `Fires when daily completion is below 50 %.` | Explanatory caption |
| `settingsWebNotificationNote` | `Notifications require the app tab to be open.` | Web-only banner |
| `settingsAboutTitle` | `About` | Section header |
| `settingsVersionLabel` | `Version {version}` | About row; placeholder: `version` (String) |
| `onboardingNotifTitle` | `Stay consistent` | Onboarding heading |
| `onboardingNotifBody` | `Allow gentle reminders so the app can nudge you at your chosen prayer times. You control which reminders you receive.` | Onboarding body |
| `onboardingNotifEnableButton` | `Enable notifications` | Primary button |
| `onboardingNotifSkipButton` | `Not now` | Secondary button |
| `notifCategoryBody` | `{taskSummary}` | Notification body; placeholder: `taskSummary` (String) |
| `notifEodBody` | `You're at {percent}% today. A few minutes of Adhkar can change the day.` | EOD body; placeholder: `percent` (int) |
| `settingsTaskNotifToggleA11y` | `Enable notification for {taskName}` | Per-task toggle a11y; placeholder: `taskName` (String) |

### 3.13 New dependencies

| Package | Why |
|---|---|
| `flutter_local_notifications` | Native scheduling on Windows. Already named in `tech-stack.md`. |
| `flutter_timezone` | Required by `flutter_local_notifications` for time-zone-aware `zonedSchedule`. |
| `package_info_plus` | Version string in the Settings About section. |

Added via `flutter pub add flutter_local_notifications flutter_timezone package_info_plus`.

### 3.14 Feature folder layout

```
app/
  l10n/
    app_en.arb                                          # +18 new keys (§3.12)
    app_ar.arb                                          # +18 new keys with TODO: placeholders
  lib/
    core/
      database/
        app_database.dart                               # MODIFIED — schema v1→v2, migration, 3 new tables
      routing/
        app_router.dart                                 # MODIFIED — 3rd branch (/settings) + onboarding route
    features/
      shell/
        presentation/
          root_shell.dart                               # MODIFIED — 3rd NavigationDestination
      settings/                                         # NEW feature folder
        domain/
          category_notification_schedule.dart           # NEW
          task_notification_toggle.dart                 # NEW
          eod_summary_settings.dart                     # NEW
        data/
          notification_settings_repository.dart         # NEW — Drift-backed
          app_settings_repository.dart                  # NEW — Drift key-value
        presentation/
          providers/
            notification_settings_provider.dart         # NEW — category + task stream providers
            eod_settings_provider.dart                  # NEW
            onboarding_done_provider.dart               # NEW
          widgets/
            category_schedule_tile.dart                 # NEW — ExpansionTile + switch + time chip
            task_notif_toggle_tile.dart                 # NEW — per-task SwitchListTile
            eod_summary_row.dart                        # NEW
            settings_section_card.dart                  # NEW — mirrors DashboardSectionCard
          settings_screen.dart                          # NEW
          notification_onboarding_screen.dart           # NEW
      notifications/                                    # NEW feature folder
        notification_service.dart                       # NEW — abstract interface
        native_notification_service.dart                # NEW — flutter_local_notifications
        web_notification_service.dart                   # NEW — dart:js_interop
        notification_scheduler.dart                     # NEW — orchestrates service + settings
        providers/
          notification_service_provider.dart            # NEW
          notification_scheduler_provider.dart          # NEW
          app_localizations_provider.dart               # NEW — thin StateProvider for l10n injection
  test/
    features/
      settings/
        notification_settings_repository_test.dart      # NEW — mandatory (§3.15)
```

### 3.15 Mandatory automated tests

**`app/test/features/settings/notification_settings_repository_test.dart`** (Drift in-memory DB):

1. Migration from v1 → v2 seeds exactly **8 category rows**.
2. Migration seeds exactly **34 task rows**.
3. Toggle a category off → read back → `enabled == false`.
4. Update a category time → read back → correct `hour` / `minute`.
5. Toggle a task off → read back → `notificationsEnabled == false`.
6. EOD settings round-trip: disable + set 22:00 → read back.
7. `notification_onboarding_done` flag: starts `false`, persists `true` after set.

This is the **only mandatory automated gate** this phase. The notification service implementations are not unit-testable without platform channels; they are covered by the manual smokes in `plan.md` groups 18–19.

### 3.16 RTL & accessibility commitments

- All horizontal layouts in Settings use `EdgeInsetsDirectional`; no `EdgeInsets.only(left/right)`.
- `ExpansionTile`s use `TextDirection`-aware leading icons.
- Every per-task `SwitchListTile` carries `Semantics(label: l.settingsTaskNotifToggleA11y(task.name))`.
- Time picker dialogs use native `showTimePicker()` — accessible by default.
- Category tile headers carry `Semantics` combining the category name and enabled/disabled state.

## 4. Out of Scope (explicitly deferred)

- **Android / iOS notification scheduling.** `flutter_local_notifications` supports both, but Android 13 `POST_NOTIFICATIONS` and iOS `UNUserNotificationCenter` permission flows exceed the 3-day budget. Deferred to a Phase 6 polish pass.
- **Prayer-time API.** Times are user-set and static. Aladhan / IslamicFinder integration is post-roadmap.
- **Snooze / dismiss tracking.** Notifications are fire-and-forget; no interaction callbacks in Phase 5.
- **Background scheduling on Web.** Service-worker push requires a backend (Phase 6). Web notifications in Phase 5 fire only while the app tab is open (L1).
- **Per-task notification times.** Each task inherits its category's scheduled time; per-task time overrides are not in scope.
- **Custom notification sounds.** Default system sound only.
- **macOS / Linux** validation targets. Phase 5 validates Web + Windows only (D5).
- **In-app notification history or log.**

## 5. Decisions Recorded This Phase

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Notification toggle granularity | **Per individual task** within a category | User-selected in spec scoping. Allows silencing the Sunnah prayer but not the Fard, for example. The category master toggle remains as a coarser control. |
| D2 | EOD summary configurability | **Time configurable; 50 % threshold fixed** | User-selected. The threshold is a spiritual design choice — "half your ibadah is significant" — making it configurable risks gamification creep. Time flexibility respects varied sleep schedules. |
| D3 | Settings location | **3rd bottom-nav tab** in the existing `RootShell` | User-selected. Phase 4 handoff note (plan §25.6) explicitly flagged this slot as ready. No shell refactor needed. |
| D4 | Permission prompt strategy | **Mini-onboarding screen on first launch** | User-selected. One-shot, explains the value before asking. Follows "niyyah-first" mission principle — the user understands the nudge before granting access. |
| D5 | Validation platforms | **Web (Chrome) + Windows** | User-selected. Matches the current dev environment (no macOS per Phase 0 convention). Android/iOS deferred. |
| D6 | Notification architecture | **Platform-conditional service**: `NativeNotificationService` (Windows) + `WebNotificationService` (Web via `dart:js_interop` + `Timer`) | `flutter_local_notifications` does not support Web. A thin abstract interface keeps the scheduler free of `kIsWeb` branches. |
| D7 | Drift schema version | **v1 → v2**; three new tables: `category_notification_schedules`, `task_notification_toggles`, `app_settings` | Clean separation of notification state from checklist data. `app_settings` is open-ended so Phase 6 sync preferences land without a further migration. |
| D8 | Notification IDs | **Stable integers** derived from category enum index (100–107) and EOD constant (200) | Prevents ghost notifications on reschedule. IDs are deterministic, so `cancel(id)` works without persisting issued IDs. |

## 6. Context & Assumptions

- Phase 0–4 deliverables are on `master`. The most recent merge to `master` is the Phase 4 dashboard PR.
- This branch is `feature/phase-5-local-notifications`, branched off `master` post-Phase-4 merge.
- The Drift schema is currently at version `1`. Phase 5 bumps it to `2`.
- The Phase 4 `RootShell` and `app_router.dart` are the canonical shell; Phase 5 extends them minimally (one destination, one branch, one redirect).
- No backend changes; `/api` remains untouched.
- `flutter_local_notifications` is the declared package in `tech-stack.md`; Phase 5 is its first use in the codebase.
- The app currently targets Android, iOS, Web, and Windows. Phase 5 notification code compiles for all targets; only Web and Windows are **validated** this phase.
- This spec folder (`specs/phase-5-2026-05-13-local-notifications/`) is the source of truth and is linked from the PR description.

## 7. Risks / Open Questions

- **R1 — Windows runner setup.** `flutter_local_notifications` on Windows requires adding a COM GUID and notification-activator registration to `app/windows/runner/main.cpp`. If the Phase 0 runner was never touched, this is new territory. *Mitigation:* `plan.md` group 13 has a step-by-step checklist; the package README is authoritative.
- **R2 — Web permission blocked at browser level.** If the user previously denied notifications for the domain, `requestPermission()` returns `"denied"` silently. *Mitigation:* the Settings screen shows a `"Notifications blocked in browser settings"` banner when permission is `denied` and the global toggle is `true`.
- **R3 — `dart:js_interop` API surface.** The Dart 3.3 `@staticInterop` syntax replaced `package:js`. *Mitigation:* use `dart:js_interop` exclusively; the `web_notification_service.dart` file is guarded by a `// ignore_for_file:` for the `js_interop` lint if needed; test on the exact Flutter stable version in the dev environment.
- **R4 — Schema migration on a live Phase 4 DB.** Users upgrading from Phase 4 have real `daily_logs` and `tasks` data. *Mitigation:* the migration is additive-only; only new tables are created; no existing tables are altered.
- **R5 — Timer-based Web scheduling can be up to ~60 s late.** A minute-resolution `Timer` is inherently imprecise. *Mitigation:* acceptable for "gentle nudge" use case; limitation L1 is documented in §3.10 and surfaced in the Settings banner.
- **R6 — 3-day budget.** Phase 5 adds a Drift migration, a new feature folder, a platform-conditional service, and an onboarding screen. *Mitigation:* the mandatory test is a single repository test (fast to write); the Settings UI uses `ExpansionTile` to reduce widget count; the notification service is thin configuration code.
