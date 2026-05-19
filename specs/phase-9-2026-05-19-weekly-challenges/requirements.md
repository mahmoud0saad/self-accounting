# Requirements — Phase 9: Weekly Challenges

**Phase:** 9 of the roadmap
**Branch:** `phase-9-2026-05-19-weekly-challenges`
**Created:** 2026-05-19
**Status:** Spec — pre-implementation
**Estimated duration:** 4 days (per roadmap)

---

## 1. Context

After Phase 8 the daily checklist loop is fully shipped and synced:

- A user — anonymous or signed-in — has a calm daily checklist, point-weighted, with streaks, dashboard charts, notifications, and a customizable catalog (`UserCategory` / `UserTask` / overrides) that round-trips between Drift (SQLite) on device and Prisma (MySQL) on the server via `pending_sync_ops` + `PUT /v1/customizations/batch`.
- `CustomizationRestoreService` (Phase 8) gives the app a deterministic snapshot-vs-push-up branch on first sign-in.
- `GET /v1/catalog` returns the full per-user effective catalog payload; `GET /v1/catalog/snapshot-state` cheaply reports whether the server has anything.
- `DailyLog` rows accumulate per `(userId, date, taskId | userTaskId)` — these are the **source of truth** for every progress signal in the app.

What's missing is a **weekly motivation layer** on top of the daily loop. Today the only periodicity surfaced to the user is the day and the streak; the dashboard hints at weekly aggregates but doesn't ask the user to commit to anything beyond "today". Per the roadmap Phase 9 entry:

> Predefined challenge templates (e.g., "Read 1 Juz' this week", "Pray all Fajr in congregation").
> Custom user-defined challenges.
> Challenge progress widget on home + completion celebration.
> Exit: First batch of challenges live; users can opt in/out weekly.

Phase 9 introduces **Weekly Challenges**: opt-in, week-scoped goals that **roll up automatically from existing `daily_logs`**. The user picks templates (or defines their own), the app derives weekly progress without any new tap-to-tick affordance, and a calm completion celebration fires when the weekly goal lands.

Mission constraints that shape every decision below:

- **#1 — Niyyah-first.** Challenges are encouragement, never pressure. Missing a week emits silence, not a shaming nudge. Completion is celebrated; non-completion is invisible.
- **#3 — Frictionless logging.** Progress derives from existing taps; no new "did you do it?" prompt for any predefined challenge.
- **#4 — Local-first.** Anonymous users get the full feature locally. Sync is opt-in and runs through the existing Phase-6/7/8 plumbing.
- **#5 — Honest measurement.** A challenge counts a day only if the underlying daily-log says so; we never inflate progress from a partial week or backfill.
- **#6 — Privacy.** Challenge state — like the checklist — leaves the device only after the user signs in and confirms email.

## 2. Goal (in one sentence)

A signed-out or signed-in user can subscribe to one or more **Weekly Challenges** — predefined or custom, each declaring a single underlying default task or category and a weekly goal count — see live progress derived from `daily_logs` on the home screen under the streak pills, and receive a calm soft-green confetti celebration the moment the weekly goal is reached; subscriptions, templates, and weekly progress snapshots round-trip via a new Prisma model + REST surface + `pending_sync_ops` op types + a Phase-8-style restore branch so a fresh sign-in on a second device pulls down the user's current week of challenges as authoritative.

## 3. In Scope

### 3.1 Challenge templates (global, seeded)

A new **global** catalog of predefined challenges, parallel to `categories` / `tasks` (Phase 7). Each template declares **exactly one** underlying signal and **one** weekly goal:

```text
ChallengeTemplate {
  code            String  @id           // e.g. "fajr_in_jamaah"
  defaultTitle    String                // English title; localized in ARB by `code`
  defaultIcon     String                // Material icon name (Phase-7 picker set)
  sourceKind      enum   { TASK_WEEKLY_COUNT, CATEGORY_WEEKLY_COUNT }
  sourceRef       String                // taskId (TASK_*) or categoryCode (CATEGORY_*)
  goalCount       Int                   // days in the week the source must be completed
  defaultSortOrder Int
  isActive        Boolean @default(true)
  createdAt       DateTime
}
```

The **first batch** (six templates) ships seeded on both Prisma and Drift, all mapped to real ids from `app/lib/features/checklist/data/static_task_catalog.dart`:

| Code | Source kind | Source ref | Goal | Default title |
|---|---|---|---|---|
| `fajr_in_jamaah` | `TASK_WEEKLY_COUNT` | `fajr_first_congregation` | 7 | "Pray every Fajr in congregation" |
| `qiyam_witr_all_week` | `TASK_WEEKLY_COUNT` | `qiyam_witr` | 7 | "Pray Witr every night" |
| `read_quran_daily` | `TASK_WEEKLY_COUNT` | `quran_read_six_quarters` | 7 | "Read Qur'an every day" |
| `tahajjud_three_nights` | `TASK_WEEKLY_COUNT` | `qiyam_two_rakahs` | 3 | "Stand for Tahajjud three nights" |
| `fajr_category_all_week` | `CATEGORY_WEEKLY_COUNT` | `fajr` | 7 | "Complete the Fajr block every day" |
| `morning_adhkar_daily` | `TASK_WEEKLY_COUNT` | `fajr_morning_adhkar` | 7 | "Morning Adhkar every morning" |

**Both sides** are seeded by code, not name, so localized titles + icons live in `app_en.arb` / `app_ar.arb` keyed by `code`. Templates can grow in future phases without breaking the wire shape.

`CATEGORY_WEEKLY_COUNT` semantics: a day counts as a "category hit" if **every** non-archived task in that category for that day is completed (i.e., the category bar is 100% for that day). This matches what the dashboard already calls "perfect Fajr day".

### 3.2 User challenges (subscriptions, opt-in)

A user opts in to a template by creating a **`UserChallenge`** row. The same shape carries **custom user-defined challenges** (per the roadmap third bullet), keyed off `templateCode IS NULL`:

```text
UserChallenge {
  id             String   @id @default(cuid())
  userId         String                                 // empty/anonymous = "local" key
  templateCode   String?                                // NULL for custom challenges
  customTitle    String?                                // required when templateCode IS NULL
  customIcon     String?                                // required when templateCode IS NULL
  customSourceKind String?                              // TASK_WEEKLY_COUNT or CATEGORY_WEEKLY_COUNT (required if custom)
  customSourceRef  String?                              // taskId or userTaskId or categoryCode/userCategoryId (required if custom)
  customGoalCount  Int?                                 // 1..7 inclusive (required if custom)
  startedAt      DateTime @default(now())
  archivedAt     DateTime?                              // soft-unsubscribe (Phase-7 archivedAt pattern)
  updatedAt      DateTime @updatedAt
  @@index([userId, archivedAt])
}
```

- Subscribing to a template = inserting a row with that `templateCode`; `custom*` fields are NULL.
- A user-defined challenge = same row, `templateCode` NULL, all `custom*` fields populated.
- Unsubscribing **sets `archivedAt`**; never deletes (Phase-8 toggle-vs-remove rule).
- "Remove permanently" is **not offered** in Phase 9 — a `UserChallenge` accumulates weekly history (§3.3) and that history must survive a stray un-subscribe tap. Hard-delete lives behind a Phase-10 backlog ticket.

Validation:

- `customGoalCount` is `1 <= n <= 7`.
- For `CATEGORY_WEEKLY_COUNT`, `customSourceRef` must resolve to an existing default `Category.code` or `UserCategory.id` for that user. For `TASK_WEEKLY_COUNT`, to a `Task.id` or `UserTask.id` for that user.
- A user cannot have **two non-archived** subscriptions to the same template code (server returns 409; client surfaces *"You're already subscribed to this challenge."*). Two custom challenges with identical fields are allowed (it's the user's choice).

### 3.3 Weekly progress snapshots

A user's progress on a single challenge for a single week is materialized in **`UserChallengeWeek`** rows. These exist so we can snapshot the goal count at week start (immune to a mid-week template edit), record completion time, and remember whether the celebration modal has been seen:

```text
UserChallengeWeek {
  id              String   @id @default(cuid())
  userId          String
  userChallengeId String                                // FK → UserChallenge.id
  weekStart       DateTime @db.Date                     // inclusive, in user's weekStartDow
  weekEnd         DateTime @db.Date                     // inclusive (weekStart + 6)
  goalCount       Int                                   // snapshot of UserChallenge.effectiveGoalCount at week start
  achievedCount   Int                                   // derived count of days the underlying source fired
  status          enum     { IN_PROGRESS, COMPLETED, MISSED, CANCELLED }
  completedAt     DateTime?                             // first transition to COMPLETED
  celebrationSeenAt DateTime?                           // set the first time the modal is dismissed
  updatedAt       DateTime @updatedAt
  @@unique([userChallengeId, weekStart])
}
```

`achievedCount` is recomputed (and persisted) every time the client touches the row — opening the home screen, toggling a relevant task on the checklist, or pulling from server. It is **never** edited by the user directly. The "honest measurement" promise (§mission 5) is enforced by deriving from `daily_logs` on every read; the persisted value is a cache for the home widget.

State transitions:

- `IN_PROGRESS → COMPLETED` when `achievedCount >= goalCount` for the first time. Sets `completedAt = now()`.
- `IN_PROGRESS | COMPLETED → MISSED` is **not** automatic. At local-midnight on the day after `weekEnd`, the client opens a fresh row for the new week; the old row keeps its terminal state (`COMPLETED` if it landed in time, otherwise it stays `IN_PROGRESS` and is treated as MISSED **only for display purposes** — see §3.5 — no DB write happens to flip a `IN_PROGRESS` to `MISSED`, because "missed" carries the wrong tone and we want the row to be reusable if a daily-log row is added retroactively for that week).
- `IN_PROGRESS | COMPLETED → CANCELLED` when the user un-subscribes (`UserChallenge.archivedAt` is set). Only the current week's row is flipped; older COMPLETED rows are preserved.

### 3.4 Week boundaries

- **Default week:** Saturday → Friday (Hijri-aligned). Rationale: the Islamic week begins at Jumu'ah / Saturday in cultural practice, and most users for this app target that cadence; this is the lowest-friction default for the target persona.
- **Configurable:** Settings → *Week start* radio control with three options (Saturday, Sunday, Monday). Default = Saturday. Stored in `app_settings.week_start_dow` (values `sat`, `sun`, `mon`). A change applies on the **next** Sunday/Saturday/Monday boundary so we don't retroactively re-window a week that already has progress; the change does not migrate existing `UserChallengeWeek` rows.
- **Server side:** the `weekStart` of a `UserChallengeWeek` is computed by the **client** (the client owns the user's timezone), and sent to the API as part of the upsert. The server validates `weekStart.day_of_week ∈ { sat, sun, mon }` and `weekEnd = weekStart + 6`. The server does not pick a week boundary on the user's behalf.

### 3.5 Home-screen surface (1-line widget)

A new sliver `WeeklyChallengeStrip` is inserted into `app/lib/features/checklist/presentation/checklist_screen.dart`, **immediately below `StreakPills`**:

- **When the user has zero non-archived `UserChallenge`s**: a calm one-line *"This week: start a challenge"* card with a chevron, tapping it pushes `/challenges`.
- **When the user has one non-archived `UserChallenge`**: a single-row strip showing the challenge's icon + title + `N / goal` progress + a thin Material 3 linear progress indicator. Tap → `/challenges`.
- **When the user has multiple non-archived `UserChallenge`s**: a single horizontally-scrollable row of compact chips, each showing icon + `N / goal`. Tap a chip → `/challenges` with that challenge focused.
- The widget never overflows above 56px tall (the streak strip's height) so the screen stays calm.
- The widget hides cleanly during the `loading` and `error` states of `effectiveCatalogProvider`; it does **not** show a skeleton on first paint (calm-by-default).

A new `MISSED`-looking display state is **only** computed on the client by comparing `weekEnd` to today; no DB flag is written. The chip body for a missed week reads *"Next week starts <weekday>"* in soft grey, never red.

### 3.6 Dedicated Challenges screen

`app/lib/features/challenges/presentation/challenges_screen.dart`, routed at `/challenges` (added to the existing `go_router` config in `app/lib/main.dart`). One screen, two tabs:

1. **This week** — every non-archived `UserChallenge` with the current week's `UserChallengeWeek` row, sorted by status (`IN_PROGRESS` → `COMPLETED` → just-archived → never-started). Each row is a soft-green card showing icon + title + linear progress + `N / goal` + a leading "subscribed" switch (Phase-8 toggle pattern: switch off → set `archivedAt`, switch on → clear `archivedAt`).
2. **Browse** — every `ChallengeTemplate` (filtered by `isActive=true`), grouped by category of the source task, each with a "Subscribe" / "Subscribed" toggle. Tapping a subscribed template opens it on the *This week* tab. Below the templates: a soft-green *"+ Create custom challenge"* tile that opens a sheet (title + icon picker (Phase 7 set) + source picker (default task or default category) + goal count slider 1–7).

A **history list** (past `UserChallengeWeek` rows grouped by week) is **out of scope for Phase 9**; it lives under §6 *"Out-of-scope-but-documented"*. The dashboard's Phase-4 charts already cover historical worship density; weekly challenge history is a Phase-10 candidate.

### 3.7 Completion celebration

When the client recomputes `UserChallengeWeek.achievedCount` and observes the first transition to `>= goalCount`:

1. The Drift row is updated: `status = COMPLETED`, `completedAt = now()`. Persisted **before** the modal opens (so a navigation away doesn't lose the transition).
2. A **soft-green confetti modal** opens over the current screen using the Phase-4 modal scaffold (`showDialog` with the calm Material 3 dialog theme; **no red**, **no shame copy**). Body: *"Mā shā' Allāh — `<title>`. `<goal>` of `<goal>` days this week."* with a primary **"Continue"** button (soft green, Phase-7 button style) and a secondary **"View challenge"** tile that pushes `/challenges`.
3. On dismiss, `celebrationSeenAt = now()` is persisted. The modal **never** re-opens for the same `(userChallengeId, weekStart)` pair, even across cold starts and across devices (the field syncs).
4. A small "completed this week" **badge** is added to the underlying checklist row(s) in `EffectiveCategorySection`: a soft-green tiny chip overlay (`flutter_local_notifications`-free pure-Flutter widget, top-right of the row). The badge disappears the moment the new week starts (computed at the row build time, not by a job).

Confetti uses `flutter_confetti` (or equivalent pure-Dart particle paint — final dep choice deferred to the plan); animation is opt-out via *Settings → "Reduce animations"* (existing accessibility hook from Phase 5).

### 3.8 Backend changes (NestJS + Prisma + MySQL)

#### 3.8.1 Prisma schema

Three new models, one Prisma migration. **No** edits to existing models. Schema additions are append-only.

```prisma
model ChallengeTemplate {
  code             String   @id
  defaultTitle     String   @map("default_title")
  defaultIcon      String   @map("default_icon")
  sourceKind       String   @map("source_kind")   // TASK_WEEKLY_COUNT | CATEGORY_WEEKLY_COUNT
  sourceRef        String   @map("source_ref")
  goalCount        Int      @map("goal_count")
  defaultSortOrder Int      @default(0) @map("default_sort_order")
  isActive         Boolean  @default(true) @map("is_active")
  createdAt        DateTime @default(now()) @map("created_at")

  @@map("challenge_templates")
}

model UserChallenge {
  id               String    @id @default(cuid())
  userId           String    @map("user_id")
  templateCode     String?   @map("template_code")
  customTitle      String?   @map("custom_title")
  customIcon       String?   @map("custom_icon")
  customSourceKind String?   @map("custom_source_kind")
  customSourceRef  String?   @map("custom_source_ref")
  customGoalCount  Int?      @map("custom_goal_count")
  startedAt        DateTime  @default(now()) @map("started_at")
  archivedAt       DateTime? @map("archived_at")
  updatedAt        DateTime  @updatedAt @map("updated_at")

  user  User                  @relation(fields: [userId], references: [id], onDelete: Cascade)
  weeks UserChallengeWeek[]

  @@index([userId, archivedAt])
  @@map("user_challenges")
}

model UserChallengeWeek {
  id                String    @id @default(cuid())
  userId            String    @map("user_id")
  userChallengeId   String    @map("user_challenge_id")
  weekStart         DateTime  @db.Date              @map("week_start")
  weekEnd           DateTime  @db.Date              @map("week_end")
  goalCount         Int                              @map("goal_count")
  achievedCount     Int      @default(0)            @map("achieved_count")
  status            String    @default("IN_PROGRESS")
  completedAt       DateTime?                        @map("completed_at")
  celebrationSeenAt DateTime?                        @map("celebration_seen_at")
  updatedAt         DateTime  @updatedAt             @map("updated_at")

  user          User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  userChallenge UserChallenge @relation(fields: [userChallengeId], references: [id], onDelete: Cascade)

  @@unique([userChallengeId, weekStart])
  @@index([userId, weekStart])
  @@map("user_challenge_weeks")
}
```

The Prisma `User` model gains three relation back-references (`challenges`, `challengeWeeks`) but **no scalar field changes**. The relation block is the only edit to an existing model.

#### 3.8.2 New endpoints

All under the existing `JwtAuthGuard` + `EmailConfirmedGuard` chain (same as Phase 6/7/8). All return JSON. All grouped under a new `Challenges` tag in OpenAPI.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/v1/challenges/templates` | List active templates. Public to any confirmed user. |
| `GET` | `/v1/challenges` | List the caller's `UserChallenge`s (with the latest `UserChallengeWeek` row attached per challenge). |
| `POST` | `/v1/challenges` | Subscribe to a template **or** create a custom challenge. Body: either `{ templateCode }` or `{ customTitle, customIcon, customSourceKind, customSourceRef, customGoalCount }`. 409 on duplicate non-archived template subscription. |
| `PATCH` | `/v1/challenges/:id` | Edit `archivedAt` (un-subscribe / re-subscribe), and — for custom challenges only — edit `customTitle`, `customIcon`, `customGoalCount` (changing `customSourceKind` / `customSourceRef` is **forbidden** mid-flight to keep history honest; the user must archive and create a new one). |
| `PUT` | `/v1/challenges/:id/weeks/:weekStart` | Upsert a `UserChallengeWeek` for the given (challenge, week). Body: `{ weekEnd, goalCount, achievedCount, status, completedAt?, celebrationSeenAt? }`. Client-authoritative for `achievedCount` (the server cannot recompute without the client's timezone). `goalCount` is locked on first insert; the server returns 409 on a mismatching `goalCount` for an existing row. |
| `GET` | `/v1/challenges/snapshot-state` | `{ hasSnapshot: boolean, totals: { userChallenges: int, userChallengeWeeks: int }, lastUpdatedAt?: ISO8601 }`. Phase-8 pattern; powers the restore branch. |

`PUT /v1/customizations/batch` is **not** extended in Phase 9 — challenges get their own batch endpoint for symmetry and so a future "challenges-only sync" rollout can ship without disturbing customization sync:

- `PUT /v1/challenges/batch` — accepts an array of `ChallengeOp`s (`upsert_user_challenge`, `delete_user_challenge`, `upsert_user_challenge_week`) with the same shape & response codes as Phase-7 `BatchOpResultDto` (`APPLIED`, `STALE`, `NOT_FOUND`, `INVALID`). Per-op LWW on `updatedAt`. Atomic per-op, not per-batch (Phase-7 pattern).

### 3.9 Flutter client changes

#### 3.9.1 New Drift tables

`app/lib/core/db/tables/`:

- `challenge_templates_table.dart` (mirror of the Prisma model; seeded on `onCreate` and on schema upgrade).
- `user_challenges_table.dart`.
- `user_challenge_weeks_table.dart`.

`app/lib/core/db/app_database.dart`:

- Bump `schemaVersion` from 5 → 6.
- Add a migration step (`if (from < 6) { ... createTable + seed challenge_templates }`).
- Wire the three new tables into `@DriftDatabase(tables: [...])`.

#### 3.9.2 New feature folder

```
app/lib/features/challenges/
  data/
    challenge_repository.dart                 // Drift CRUD + watch streams
    challenge_api.dart                        // REST methods
    challenge_progress_engine.dart            // derive achievedCount from daily_logs
    challenge_restore_service.dart            // Phase-8-style restore branch
  domain/
    challenge.dart                            // sealed: TemplateChallenge | CustomChallenge
    challenge_template.dart
    challenge_week.dart
    week_boundary.dart                        // pure functions: weekStartFor(date, dow)
  presentation/
    providers/
      challenge_templates_provider.dart
      user_challenges_provider.dart
      current_week_progress_provider.dart     // map<userChallengeId, WeekProgress>
      week_start_dow_provider.dart
    challenges_screen.dart
    widgets/
      weekly_challenge_strip.dart             // sliver placed in checklist_screen.dart
      challenge_card.dart
      completion_celebration_modal.dart
      create_custom_challenge_sheet.dart
      challenge_template_tile.dart
```

#### 3.9.3 Progress derivation engine

`ChallengeProgressEngine`:

- Pure-Dart class taking `(challenge, weekStart, weekEnd, dailyLogs)` and returning `(achievedCount, status)`.
- For `TASK_WEEKLY_COUNT`: count distinct dates in `[weekStart, weekEnd]` where any `DailyLog` row with `taskId == sourceRef` or `userTaskId == sourceRef` is `completed = true`.
- For `CATEGORY_WEEKLY_COUNT`: count distinct dates in `[weekStart, weekEnd]` where the *effective* per-day category completion of that category is 100% (using the existing `daily_progress.dart` calculation).
- Capped at `goalCount`. Strictly monotonic forward — never decreases on recomputation. (If `achievedCount` from logs is **lower** than the persisted value due to a user un-checking a task, the row keeps the higher value; this protects the user from "losing" a completion they earned and matches Phase-3 streak semantics.)

The engine is exercised by `current_week_progress_provider`, which `watches` the Drift `daily_logs` table and recomputes on every change. The recomputation is cheap (one pass over the week's logs, ≤ 56 rows in practice) so we keep the engine in-line — no isolate, no debounce.

#### 3.9.4 Sync ops (`pending_sync_ops`)

Three new op types, added to `app/lib/features/sync/data/sync_constants.dart`:

```dart
const kChallengeOpTypes = {
  'upsert_user_challenge',
  'delete_user_challenge',         // sets archivedAt; never hard-deletes
  'upsert_user_challenge_week',
};
```

`SyncService.enqueueChallengeOp(...)` mirrors `enqueueCustomizationOp` (Phase 7): coalesce-by-target-id, payload is the full row, drained by `drainOutbound()` against `PUT /v1/challenges/batch`.

A new helper `ChallengeRestoreService` (Phase-8 mirror):

- Reads `TokenStorage.isChallengeFirstSyncDone(userId)`.
- `GET /v1/challenges/snapshot-state` → branch:
  - `hasSnapshot=false`: enqueue every local `UserChallenge` + `UserChallengeWeek` as upserts, drain, mark flag.
  - `hasSnapshot=true`: await `confirmReplacePrompt(totals)`; if `true`, drop challenge-typed pending ops, truncate `user_challenges` + `user_challenge_weeks` (but **never** `challenge_templates` — those are global, identical on both sides, and seeded locally), `GET /v1/challenges` → repopulate. Mark flag.
- Wired into `SyncService.runFirstSignInMigrationIfNeeded()` **after** the Phase-8 customization restore so a single sign-in pulls logs → customizations → challenges, in that order.

#### 3.9.5 Routing

`app/lib/main.dart` `go_router` config adds:

```dart
GoRoute(
  path: '/challenges',
  builder: (context, state) => const ChallengesScreen(),
),
```

#### 3.9.6 i18n

Every new visible string lives in **both** `app/l10n/app_en.arb` and `app/l10n/app_ar.arb`. Non-exhaustive list:

- Each of the six seeded template titles + descriptions (en + ar).
- *"This week"* / *"Browse"* tab labels.
- *"Start a challenge"* zero-state.
- *"+ Create custom challenge"*.
- *"Subscribe"* / *"Subscribed"* / *"Already subscribed"*.
- Custom-challenge sheet labels: *"Title"*, *"Icon"*, *"Source"*, *"Goal: N days this week"*.
- Settings *Week start* labels + Saturday/Sunday/Monday.
- Completion modal: *"Mā shā' Allāh"*, *"`<title>`"*, *"`<goal>` of `<goal>` days this week."*, *"Continue"*, *"View challenge"*.
- "Completed this week" badge tooltip.

### 3.10 `TokenStorage` extension

`app/lib/features/auth/data/token_storage.dart`:

- `Future<bool> isChallengeFirstSyncDone(String userId)`.
- `Future<void> markChallengeFirstSyncDone(String userId)`.
- `Future<void> clearChallengeFirstSyncFlag(String userId)` — invoked by a future *"Restore challenges from your account"* tile (Phase 10 candidate; the flag-clear API is in place from day one so we don't ship a half-baked storage shape).

Key namespace: `challenge_first_sync_done:<userId>` — separate from the Phase-6 log flag and the Phase-8 customization flag, so a partial install can complete each pass independently.

## 4. Decisions (from clarification questions, 2026-05-19)

### 4.1 Progress model — **Auto-derived from `daily_logs`**

Every challenge — predefined or custom — declares a single underlying source (a default task, a user-owned task, a default category, or a user-owned category) and a weekly goal count. Progress is the count of distinct dates in `[weekStart, weekEnd]` on which the source fired. No manual tick. No "I did it" affordance.

Implications:
- **Zero new friction** on the daily checklist (mission #3). The user keeps doing what they already do; the strip on home renders the side-effect.
- **No "Read 1 Juz" with page-tracking** in Phase 9 — that template is reframed as *"Read Qur'an every day this week"* (7 × `quran_read_six_quarters`). Real Juz tracking is in the backlog (§6) once a Qur'an reader sub-feature lands.
- Custom challenges that don't map to a single task/category are **not allowed** in Phase 9. The "MANUAL" source kind is named here for forward compatibility (§6) but not shipped.
- Anonymous users get the feature too: progress derives from local `daily_logs` regardless of sign-in state.

### 4.2 Backend scope — **Full stack this phase**

Phase 9 ships the Prisma migration, the six new endpoints (templates, list, subscribe, edit, week upsert, snapshot-state), the `/v1/challenges/batch` endpoint, the Drift schema bump, the sync op types, the `ChallengeRestoreService`, and the Settings *Week start* control — all in 4 days.

Implications:
- Sign-in on a second device pulls the user's current week + subscriptions down via the restore branch, identical UX to Phase-8 customization restore.
- Schema growth is contained: three new tables, append-only. No edits to existing tables beyond Prisma relation back-references on `User`.
- Aggressive scope. Validation (§validation.md) explicitly lists timeboxes for each task group; if Group 9 (celebration) slips, we ship Phase 9 without confetti (text-only modal) and treat confetti as a follow-up commit on the same branch.

### 4.3 UX & validation — **Saturday→Friday week, 1-line widget under streak strip, confetti modal + row badge**

- **Default week start = Saturday** (Hijri-aligned). User can switch to Sunday or Monday in Settings → *Week start*; default behavior reflects the target persona's calendar (see mission, target user).
- **Home surface:** a `WeeklyChallengeStrip` sliver immediately below `StreakPills` in `checklist_screen.dart`. Adaptive: empty-state card, single-row strip, or horizontal chip row. Never taller than 56px.
- **Completion celebration:** soft-green confetti modal (no red, no shame copy) + a soft-green badge on the underlying checklist row(s) until the week rolls. *Reduce animations* opt-out is honored.

Implications:
- The home screen layout shift is minimal — one new sliver, only visible when the user has subscriptions or a relevant zero-state.
- The Settings *Week start* radio is a 1-tap control. The change does not retroactively re-window existing weeks; it applies on the next week boundary.
- Confetti dependency choice (`flutter_confetti` vs a custom particle paint) is left to the plan, scored against bundle size and the existing `flutter_lints` rule set.

## 5. Non-Goals (this phase)

- **Sub-week challenges** (e.g., 3-day Adhkar sprints) or **monthly challenges** (e.g., "Pray Tahajjud every night this Ramadan"). Phase 9 is strictly week-scoped.
- **Manual-tick challenges** — see §4.1. Every progress signal flows through `daily_logs`.
- **Page-level / verse-level Qur'an tracking** — Phase 9 reads from existing task completions; finer-grained Qur'an metering is post-roadmap.
- **Challenge history list** on the Challenges screen — past `UserChallengeWeek` rows are persisted and synced, but no list UI is added in Phase 9; the dashboard's Phase-4 monthly heatmap already shows worship density.
- **Push notifications for challenge milestones** (e.g., "halfway there"). The notification surface is intentionally limited to Phase-5 prayer / EOD notifications. A Phase-10 candidate.
- **Social / leaderboard / shared challenges** — explicitly out of v1 per mission §"Out of Scope".
- **Hard delete of `UserChallenge`** (no *Remove permanently* affordance in Phase 9). Subscriptions are soft-archived; weekly history is retained.
- **Schema changes on the `User`, `DailyLog`, `Task`, `Category` models.** Only new tables + back-references.
- **Editing the underlying source of an existing custom challenge.** Changing source mid-flight breaks the "honest measurement" promise. The user archives and creates a new one.

## 6. Out-of-Scope but Documented for Later

- **MANUAL source kind** — challenges that the user manually ticks per day (e.g., "Make du'a for my mother daily"). The `customSourceKind` enum already names `MANUAL` so a future phase can add it without a wire-shape break.
- **Challenge history screen** — paginated list of past weeks per challenge, with the dashboard heatmap colouring each week. Phase 10.
- **Hard-delete *Remove permanently* affordance** for `UserChallenge`s with zero weeks of progress. Mirrors the Phase-8 Manage screen split.
- **Stretch goals** — challenges with `goalCount > 7` (e.g., "21 Qiyam nights this 3-week stretch"). Requires a multi-week shape.
- **Server-pushed seasonal templates** (e.g., "Ramadan starter pack"). Templates are global and active-flagged; a future cron can flip `isActive` on seasonal sets.
- **Challenge notifications** — Phase-5 plumbing reused: "You're 1 Fajr away from completing your challenge."
- **Shared challenges** with a household — explicitly post-v1.

## 7. Constraints & Cross-Cutting Concerns

- **Offline-first** (mission #4): every challenge interaction works offline. Sync happens through the same `pending_sync_ops` queue that already drains on connectivity recovery (Phase 6).
- **Niyyah-first tone** (mission #1): no shame strings anywhere. Missing a week is silent. The Phase-7 / Phase-8 blocklist applies — no *"failure"*, no *"missed"* in user-facing copy; the chip body for a missed week reads *"Next week starts <weekday>"* in soft grey.
- **Calm palette** (mission #2): soft-green confetti + soft-green badge. No red. No amber except for any future *Remove permanently* (out of scope this phase).
- **Privacy** (mission #6): no analytics on subscription, completion, or template browse. Challenge titles and source refs do **not** appear in any server log line.
- **Versioned API**: all routes under `/v1`.
- **Backward compatibility**: a client built against Phase 8 keeps working — the `/v1/catalog/snapshot-state` endpoint is unchanged; no DTO breaks; the only new wire shapes are additive under `/v1/challenges/*`.
- **i18n parity**: every new ARB key exists in both `app_en.arb` and `app_ar.arb`. Arabic copy is reviewed for tone, not just translated literally.
- **A11y**: every new tappable widget has a `Semantics` label; confetti respects *Reduce animations*; soft-green chips meet WCAG AA contrast on both light and dark scheme.

## 8. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Recomputing weekly progress on every `daily_logs` change creates jank on slow devices | Low–Medium | Engine is O(week_days × per_day_log_rows) — ≤ 56 rows worst case. Persist `achievedCount` so the home strip can render from the cache without recompute; recompute lazily on first frame of each route. |
| User changes their *Week start* mid-week and expects "this week" to re-window | Medium | Settings copy explicitly says *"Applies to next week."*. Existing `UserChallengeWeek` rows are not migrated. A snackbar confirms *"Your new week starts `<weekday>`."* on toggle. |
| User creates a custom challenge pointing at a `UserTask` then deletes that task (Phase-8 *Remove permanently*) | Medium | `customSourceRef` is validated server-side on `POST /v1/challenges`. If the referenced row is later hard-deleted, the next progress recompute returns `0`; the challenge keeps showing on the strip with a calm subtitle *"This challenge's source was removed."* and the user can archive it manually. No automatic archive. |
| `UserChallengeWeek.goalCount` drifts from `UserChallenge.customGoalCount` after the user edits the latter mid-week | Low | `goalCount` is snapshotted on row creation and locked. The server returns 409 on a mismatching `goalCount` PUT. The edit applies to next week's row. |
| Confetti modal fires twice (e.g., progress recompute races with sync pull-down on the same week) | Medium | Single source of truth: `celebrationSeenAt`. The modal opens iff `status=COMPLETED ∧ celebrationSeenAt IS NULL`. Setting `celebrationSeenAt` is gated by a per-row in-memory mutex. Drift uniqueness on `(userChallengeId, weekStart)` enforces it at rest. |
| Two-device race: device A completes a challenge while device B's offline progress is stale | Low | Per-op LWW on `updatedAt` (Phase-7 batch contract). The "first" `completedAt` wins; the modal opens on whichever device next foregrounds the row. `celebrationSeenAt` is also LWW so the user is not nagged twice across devices. |
| `pending_sync_ops` grows unbounded if the user toggles task completions rapidly on the checklist (each toggle triggers a `upsert_user_challenge_week` enqueue) | Medium | Coalesce by `(opType, targetId)` — the same Phase-7 rule already applies. Only the latest `upsert_user_challenge_week` per `(challenge, weekStart)` survives the queue. |
| Confetti dep adds > 100KB to the Flutter web bundle | Low | Decision deferred to Group 9 of the plan; the spec ships with text-only celebration as the fallback. |
| Custom challenge with `customSourceRef` pointing at a default `Category.code` that gets a new task added by the user (Phase 7) inflates day-count retroactively | Low | Acceptable. The "honest measurement" promise is **today's task list × today's completions** — adding a task changes the bar going forward, never backward. Existing `UserChallengeWeek.achievedCount` is monotonic (§3.9.3); retroactive log additions can only increase, never decrease the persisted value. |

## 9. Dependencies

- Phase 8 must be merged. ✅ (verify on branch creation: `git log master -- specs/phase-8-2026-05-19-tasks-category-sync`).
- Phase 7 `UserCategory`, `UserTask`, `pending_sync_ops`, `BatchOpResultDto`.
- Phase 6 `TokenStorage`, `JwtAuthGuard`, `EmailConfirmedGuard`, `SyncService.runFirstSignInMigrationIfNeeded`.
- Phase 5 *Reduce animations* accessibility setting (re-used by the confetti opt-out).
- Phase 4 `daily_progress.dart` (re-used by `CATEGORY_WEEKLY_COUNT` derivation).
- Phase 3 `streak_calculator.dart` (informational — the new strip lives directly below `StreakPills`; no shared code).
- Phase 2 `daily_logs` schema (read-only consumer in this phase).
- Phase 1 `staticTaskCatalog` (six template `sourceRef`s point into it).

## 10. References

- `spec/roadmap.md` — Phase 9 entry (the three goal bullets).
- `spec/mission.md` — principles #1, #2, #3, #4, #5, #6 and the "Out of Scope" section.
- `spec/tech-stack.md` — *Data Model* sketch already names `challenges`; this phase fills that out.
- `specs/phase-6-2026-05-18-backend-optional-sync/requirements.md` — first-sign-in migration contract this phase extends.
- `specs/phase-7-2026-05-19-task-customization/requirements.md` — `pending_sync_ops` shape + batch endpoint pattern.
- `specs/phase-8-2026-05-19-tasks-category-sync/requirements.md` — restore service pattern, snapshot-state endpoint shape, toggle-vs-remove model.
