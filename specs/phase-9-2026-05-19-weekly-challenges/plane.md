# Plan — Phase 9: Weekly Challenges

A series of **numbered task groups**, ordered so each group leaves the repo in a working, demoable state. Tick boxes as you complete them. Each group should be one PR (or one well-titled commit on this branch).

> Branch: `phase-9-2026-05-19-weekly-challenges`
> Companion docs: `requirements.md`, `validation.md`

---

## Group 1 — Backend: Prisma schema + migration

**Goal:** Land the three new tables in MySQL without touching anything Phase 1–8 owns.

1.1. Add `ChallengeTemplate`, `UserChallenge`, `UserChallengeWeek` models to `api/prisma/schema.prisma`. Exactly mirror §3.8.1 of `requirements.md`. The only edit to `User` is two relation back-references (`challenges`, `challengeWeeks`).

1.2. Generate the migration:

```bash
cd api && npx prisma migrate dev --name phase_9_challenges
```

Migration file lives under `api/prisma/migrations/<timestamp>_phase_9_challenges/`. Commit it.

1.3. Verify the migration is purely additive: `prisma migrate diff --from-empty --to-schema-datamodel` shows only `CREATE TABLE` + `CREATE INDEX` statements for the three new tables and `ALTER TABLE users` for the back-references (no column adds, no destructive ops).

1.4. Seed the six `challenge_templates` rows via a new `api/prisma/seed.ts` block (or extend the existing seed entry point). Use the exact codes + source refs from §3.1 of `requirements.md`. Seeding is idempotent (`upsert` on `code`).

1.5. Unit test (`api/test/challenges/seed.spec.ts`): run the seed twice; assert exactly six rows with the expected codes and that `sourceRef` points at a non-empty default task / category code. The test asserts `sourceRef ∈ static catalog ids ∪ category codes` by importing a shared constants file mirrored from Flutter (see §1.6).

1.6. Add `api/src/challenges/source-refs.ts` — a compile-time list of the eight default `categoryCode`s + the static catalog `taskId`s (mirroring `app/lib/features/checklist/data/static_task_catalog.dart` ids 1:1). This is the **only** allowed value-set for `ChallengeTemplate.sourceRef` and for any **default-targeted** `UserChallenge.customSourceRef`. User-owned refs (`user_task_id`, `user_category_id`) are validated via Prisma at the request boundary.

**Exit:** `npx prisma migrate dev` runs clean against a fresh DB; the seed yields six template rows; CI green on `api/test`.

---

## Group 2 — Backend: `challenges` Nest module + read endpoints

**Goal:** Templates and subscriptions are readable end-to-end.

2.1. New folder `api/src/challenges/` with:
- `challenges.module.ts` (registered in `api/src/app.module.ts` alongside `CustomizationModule`).
- `challenges.controller.ts` — `GET /v1/challenges/templates` + `GET /v1/challenges` + `GET /v1/challenges/snapshot-state`.
- `challenges.service.ts` — Prisma read helpers.
- `dto/` folder with `ChallengeTemplateDto`, `UserChallengeDto` (includes the latest `UserChallengeWeek` row), `SnapshotStateDto` (totals + lastUpdatedAt, identical shape to the Phase-8 customization snapshot-state but named for this surface).

2.2. Guards: re-use `JwtAuthGuard` + `EmailConfirmedGuard` at the controller level (same chain as `CatalogController` in Phase 8).

2.3. OpenAPI:
- New `Challenges` tag.
- Each endpoint annotated with response DTOs + example values + status codes (`200`, `401`, `403`).

2.4. Unit tests (`api/test/challenges/challenges.service.spec.ts`):
- `getTemplates()` returns the seeded six with `isActive=true` filtering.
- `listUserChallenges(userId)` excludes `archivedAt IS NOT NULL` by default; supports `?includeArchived=true` query param (used by the restore branch).
- `getSnapshotState(userId)` returns `{ hasSnapshot, totals, lastUpdatedAt }` exactly like §3.8.2 of `requirements.md`. Empty user → `hasSnapshot=false`, no `lastUpdatedAt`.

2.5. E2E tests (`api/test/challenges/challenges.e2e.spec.ts`):
- Anonymous → 401 on all three endpoints.
- Authed unconfirmed → 403.
- Authed confirmed empty → `GET /v1/challenges/templates` returns the six seeded rows; `GET /v1/challenges` returns `[]`; `GET /v1/challenges/snapshot-state` returns `hasSnapshot=false`.

**Exit:** `curl -H "Authorization: Bearer <jwt>" /v1/challenges/templates` returns the seeded payload. CI green.

---

## Group 3 — Backend: write endpoints (`POST` + `PATCH` + `PUT week`)

**Goal:** A confirmed user can subscribe, edit, un-subscribe, and upsert weekly progress.

3.1. Extend `challenges.controller.ts`:
- `POST /v1/challenges` — body discriminated by presence of `templateCode` vs `custom*` fields. Validation via `class-validator` (Phase-7 pattern). 409 on duplicate non-archived template subscription. 422 on invalid `customSourceRef` (not in `source-refs.ts` for default refs, not owned by the user for `user_*` refs).
- `PATCH /v1/challenges/:id` — body: optional `archivedAt` (clearable with `null`), optional `customTitle`/`customIcon`/`customGoalCount` (only when `templateCode IS NULL`). Forbids `customSourceKind` / `customSourceRef` edits with 422.
- `PUT /v1/challenges/:id/weeks/:weekStart` — body: `{ weekEnd, goalCount, achievedCount, status, completedAt?, celebrationSeenAt? }`. Idempotent upsert keyed on `(userChallengeId, weekStart)`. 409 on `goalCount` mismatch against an existing row. Validates `weekStart.day_of_week ∈ { sat, sun, mon }` and `weekEnd = weekStart + 6`.

3.2. New `PUT /v1/challenges/batch` endpoint (Phase-7 batch shape):
- Accepts `Array<{ opType, payload, clientUpdatedAt }>` where `opType ∈ kChallengeOpTypes`.
- Returns `Array<{ opType, targetId, outcome }>` where `outcome ∈ { APPLIED, STALE, NOT_FOUND, INVALID }`.
- Per-op LWW on `updatedAt`. Atomic per-op, not per-batch.

3.3. Service-level helpers:
- `ChallengesService.upsertUserChallenge(userId, dto)` — guards uniqueness + ref validity.
- `ChallengesService.upsertUserChallengeWeek(userId, challengeId, weekStart, dto)` — guards goalCount lock + day-of-week constraint.
- `ChallengesService.applyBatchOp(userId, op)` — dispatch table over `kChallengeOpTypes`.

3.4. E2E tests (`api/test/challenges/challenges-write.e2e.spec.ts`):
- Subscribe to a template → 201 → returns the new `UserChallenge` with `weeks: []`.
- Subscribe twice to the same template → second call returns 409.
- Subscribe → archive (`PATCH archivedAt=now`) → subscribe again → 201 (because the prior row is archived).
- Create a custom challenge with `customGoalCount=8` → 422.
- PUT a week with `weekStart` on a Tuesday → 422.
- PUT a week twice with different `goalCount` → second call returns 409.
- Batch op `upsert_user_challenge_week` with stale `clientUpdatedAt` → `STALE`.

**Exit:** Every endpoint in `requirements.md` §3.8.2 returns the contract listed there. CI green.

---

## Group 4 — Client: Drift schema bump + seed

**Goal:** The three new tables exist locally and are seeded with the same six templates.

4.1. Add Drift tables under `app/lib/core/db/tables/`:
- `challenge_templates_table.dart` — mirror of the Prisma model, key = `code TEXT PRIMARY KEY`.
- `user_challenges_table.dart` — `id TEXT PRIMARY KEY` + the fields from `requirements.md` §3.2.
- `user_challenge_weeks_table.dart` — `id TEXT PRIMARY KEY` + `UNIQUE(user_challenge_id, week_start)`.

4.2. Wire the three tables into `@DriftDatabase(tables: [...])` in `app/lib/core/db/app_database.dart`. Bump `schemaVersion` from 5 → 6.

4.3. Migration step:
```dart
if (from < 6) {
  await m.createTable(challengeTemplates);
  await m.createTable(userChallenges);
  await m.createTable(userChallengeWeeks);
  await _seedChallengeTemplates();
}
```
…and call `_seedChallengeTemplates()` from `onCreate` too. Seed uses the same six template codes / source refs / goal counts as the backend seed (single shared constants file imported by both sides — see §4.4).

4.4. Create `app/lib/features/challenges/data/challenge_template_seed.dart` exporting `const kSeededChallengeTemplates = <_TemplateSeed>[...]` with the six entries. This file is the **single source of truth** in Dart; the backend mirror lives in `api/src/challenges/seed-templates.ts` (Group 1.4) and the two are kept in lockstep by a CI script (see Group 10).

4.5. Run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `app_database.g.dart`.

4.6. Drift migration test (`app/test/core/db/migrations_test.dart`):
- Open a v5 database; assert `schemaVersion=5`.
- Run the migration to v6; assert the three new tables exist and `challenge_templates` has exactly six rows with the expected codes.
- Re-open at v6; assert the seed is **not** duplicated.

**Exit:** `flutter test app/test/core/db/migrations_test.dart` green. App boots cleanly on a v5-on-disk database without data loss.

---

## Group 5 — Client: domain, repository, API client

**Goal:** A `ChallengeRepository` and `ChallengeApi` that the rest of the client can consume.

5.1. Domain models under `app/lib/features/challenges/domain/`:
- `challenge_template.dart` — value type (code, defaultTitle, defaultIcon, sourceKind, sourceRef, goalCount, sortOrder, isActive).
- `challenge.dart` — sealed class with `TemplateChallenge` (templateCode + the resolved template + optional override-style edits, none in Phase 9) and `CustomChallenge` (the custom* fields). Both carry `id`, `userId`, `startedAt`, `archivedAt`, `updatedAt`.
- `challenge_week.dart` — `weekStart`, `weekEnd`, `goalCount`, `achievedCount`, `status`, `completedAt`, `celebrationSeenAt`, `updatedAt`.
- `week_boundary.dart` — pure functions `DateTime weekStartFor(DateTime date, WeekStartDow dow)` + `DateTime weekEndFor(DateTime weekStart)`. `WeekStartDow` is an enum `{ sat, sun, mon }`. Saturday-anchored arithmetic uses `((date.weekday - DateTime.saturday) % 7 + 7) % 7` to handle Sunday's `weekday=7` correctly. Tests in §5.5.

5.2. Repository `app/lib/features/challenges/data/challenge_repository.dart`:
- `Stream<List<Challenge>> watchActiveChallenges()`.
- `Stream<Map<String, ChallengeWeek>> watchCurrentWeekProgress(WeekStartDow dow)` — keyed by `userChallengeId`. Triggers re-emit on `user_challenges` and `daily_logs` table changes.
- `Future<Challenge> subscribeToTemplate(String templateCode)`.
- `Future<Challenge> createCustomChallenge({ ... })`.
- `Future<void> setArchived(String challengeId, { required bool archived })`.
- `Future<ChallengeWeek> upsertCurrentWeek(String challengeId, ChallengeWeek week)`.
- `Future<List<ChallengeTemplate>> listTemplates()`.

Repository writes also enqueue the matching `pending_sync_ops` row (Group 8) so the offline-first contract holds.

5.3. API client `app/lib/features/challenges/data/challenge_api.dart`:
- Mirrors every endpoint added in Groups 2 + 3 + the new `/v1/challenges/batch`.
- Uses the existing `dio` instance from `app/lib/core/api/api_client.dart` (Phase 6 plumbing).
- Returns plain Dart records / DTOs; serialization lives in `dto/` next to the api file.

5.4. Riverpod providers under `app/lib/features/challenges/presentation/providers/`:
- `challengeRepositoryProvider`.
- `challengeApiProvider`.
- `challengeTemplatesProvider` (`FutureProvider<List<ChallengeTemplate>>` — reads local first, schedules a background `GET /v1/challenges/templates` when signed-in + confirmed).
- `activeUserChallengesProvider` (`StreamProvider<List<Challenge>>`).
- `currentWeekProgressProvider` (`StreamProvider<Map<String, ChallengeWeek>>`).
- `weekStartDowProvider` (`StateNotifierProvider<WeekStartDowController, WeekStartDow>` backed by `app_settings.week_start_dow`, default `WeekStartDow.sat`).

5.5. Tests:
- `app/test/features/challenges/domain/week_boundary_test.dart` — table-driven: for each of `{ sat, sun, mon }` and 14 example dates spanning a week boundary, assert `weekStartFor` and `weekEndFor` are correct in both directions and across the year boundary (e.g., `2026-12-31` → previous Saturday).
- `app/test/features/challenges/data/challenge_repository_test.dart` — subscribe to a template, watch the resulting `Challenge` list, archive it, watch it disappear, un-archive it, watch it return. Uses an in-memory Drift instance.

**Exit:** `flutter analyze` and `flutter test` are green on the new files. No UI yet.

---

## Group 6 — Client: progress derivation engine

**Goal:** Given today's `daily_logs`, compute `(achievedCount, status)` for every active challenge for the current week.

6.1. `app/lib/features/challenges/data/challenge_progress_engine.dart`:
- Pure-Dart class. Inputs: `(Challenge challenge, DateTime weekStart, DateTime weekEnd, List<DailyLog> logsForWeek, List<EffectiveTask> effectiveTasksForCategory?)`. Output: `({int achievedCount, ChallengeWeekStatus status})`.
- For `TASK_WEEKLY_COUNT`: count distinct `date` values where any `logsForWeek` row matches the source and `completed=true`. Match by `taskId == sourceRef` (default task) or `userTaskId == sourceRef` (user task).
- For `CATEGORY_WEEKLY_COUNT`: count distinct `date` values where the per-day category completion is 100% — re-uses `DailyProgress.forCategory(...)` from `app/lib/features/checklist/domain/daily_progress.dart` (Phase 4).
- Cap `achievedCount` at `goalCount`.
- `status = COMPLETED` iff `achievedCount >= goalCount`, else `IN_PROGRESS`. The engine never returns `MISSED` or `CANCELLED` — those transitions are owned by the repository (`MISSED` is display-only; `CANCELLED` is set on archive).

6.2. **Monotonic guard**: the *engine* always returns the freshly-derived value, but `currentWeekProgressProvider` compares against the persisted `achievedCount` and persists only `max(persisted, derived)` — protecting the user from "losing" a completion if they un-check a task. The status only flips forward (`IN_PROGRESS → COMPLETED`).

6.3. Provider wiring:
- `currentWeekProgressProvider` watches `(activeUserChallengesProvider, weekStartDowProvider, dailyLogsForWeekProvider)`. On every change, it:
  1. Computes `weekStart` from today + dow.
  2. For each active challenge, derives `(achievedCount, status)` via the engine.
  3. Upserts the `UserChallengeWeek` row in Drift (creating it if absent, with `goalCount = challenge.effectiveGoalCount` at insert time).
  4. If the row just transitioned to `COMPLETED`, also writes `completedAt = now()`.
  5. Returns a `Map<String, ChallengeWeek>` to the UI.

6.4. Tests (`app/test/features/challenges/data/challenge_progress_engine_test.dart`):
- 7-day week, source `fajr_first_congregation`, 5 completions across 4 distinct dates → `achievedCount=4`, `status=IN_PROGRESS`.
- Same with 7 distinct dates → `achievedCount=7` (capped), `status=COMPLETED`.
- `CATEGORY_WEEKLY_COUNT` for `fajr` with 3 fully-completed Fajr days → `achievedCount=3`.
- Monotonic guard: persisted=5, derived=3 → persisted stays 5; persisted=3, derived=5 → persisted advances to 5.

**Exit:** Engine and provider produce honest progress for the seeded templates against a synthetic week of `daily_logs`. CI green.

---

## Group 7 — Client: home strip + week-start setting

**Goal:** The 1-line `WeeklyChallengeStrip` renders below `StreakPills`.

7.1. New widget `app/lib/features/challenges/presentation/widgets/weekly_challenge_strip.dart`:
- Watches `activeUserChallengesProvider` + `currentWeekProgressProvider`.
- Three render modes (§3.5 of `requirements.md`):
  - **Zero subscriptions** → soft-green calm card *"This week: start a challenge"* + chevron, navigation: `context.push('/challenges')`.
  - **One subscription** → row with icon + title + `N / goal` + a `LinearProgressIndicator` (Material 3, soft-green, height 4). Tap → `/challenges`.
  - **2+ subscriptions** → horizontally-scrollable `Row` of compact chips (icon + `N / goal`). Tap chip → `/challenges` with the challenge id deep-linked as a query param.
- Never taller than 56 px (asserted by a widget test that pumps each mode and reads `tester.getSize`).
- Hides cleanly (`SizedBox.shrink()`) when `effectiveCatalogProvider` is in `loading` or `error` state.

7.2. Insert the new sliver into `app/lib/features/checklist/presentation/checklist_screen.dart` directly after `StreakPills`:
```dart
const SliverToBoxAdapter(child: StreakPills()),
const SliverToBoxAdapter(child: WeeklyChallengeStrip()),
```

7.3. Settings UI: add a *Week start* radio control to the existing Settings screen (`app/lib/features/settings/presentation/settings_screen.dart` — Phase 5/6 surface). Three options: Saturday (default), Sunday, Monday. Selecting any value writes through `weekStartDowProvider` (which persists to `app_settings.week_start_dow`). Subtitle copy: *"Applies to next week."*. Snackbar on change: *"Your new week starts `<weekday>`."*.

7.4. Widget tests (`app/test/features/challenges/presentation/widgets/weekly_challenge_strip_test.dart`):
- Pump with 0 active challenges → finds the *"start a challenge"* card.
- Pump with 1 active challenge at 3/7 → finds the title + the progress label.
- Pump with 3 active challenges → finds a horizontal scrolling chip row; verify scroll works.
- Strip respects RTL (Arabic locale): icons mirror, progress indicator direction is correct.

**Exit:** Boot the app on an emulator, subscribe to *Pray every Fajr in congregation* via debug call, complete `fajr_first_congregation` for two days → the strip on home shows `2 / 7` with a soft-green progress bar.

---

## Group 8 — Client: dedicated Challenges screen + sync ops

**Goal:** Full subscribe/un-subscribe + custom-create UX, with writes flowing through the existing sync queue.

8.1. New route `/challenges` wired into `app/lib/main.dart` `go_router` config.

8.2. `challenges_screen.dart` — `DefaultTabController(length: 2)` with two tabs:
- **This week** — `ListView.separated` over `activeUserChallengesProvider`, each row a `ChallengeCard` (icon, title, linear progress, `N / goal`, leading subscribed `Switch`). Sort order: `IN_PROGRESS` first, then `COMPLETED`, then any *"source removed"* edge cases. Empty state: same calm copy as the strip's empty card + a *Browse templates* CTA.
- **Browse** — `ListView` over `challengeTemplatesProvider`, grouped by category of the source. Each row a `ChallengeTemplateTile` with a *Subscribe* / *Subscribed* trailing button. Below the list: a soft-green tile *"+ Create custom challenge"* opening `CreateCustomChallengeSheet`.

8.3. `create_custom_challenge_sheet.dart` — `showModalBottomSheet`-style sheet:
- Title text field (max 60 chars).
- Icon picker (re-uses the Phase-7 icon grid from `app/lib/features/customization/presentation/widgets/`).
- Source picker: tabbed `Task` / `Category`, populated from `effectiveCatalogProvider` (Phase 7). User-owned + default items both appear.
- Goal count slider, 1–7, default 7.
- Primary button *Create*; secondary *Cancel*.
- Validation surfaces inline (no AlertDialog).

8.4. Extend `app/lib/features/sync/data/sync_constants.dart`:
```dart
const kChallengeOpTypes = {
  'upsert_user_challenge',
  'delete_user_challenge',
  'upsert_user_challenge_week',
};

bool isChallengeOpType(String opType) => kChallengeOpTypes.contains(opType);
```
Update `kAllSyncOpTypes` (or equivalent) and `isCustomizationOpType`-style helpers if any consumer uses the combined set.

8.5. Extend `SyncService` (`app/lib/features/sync/data/sync_service.dart`):
- `enqueueChallengeOp({ required String opType, required String targetId, required Map<String, dynamic> payload })` — coalesce-by-`(opType, targetId)`, same shape as `enqueueCustomizationOp`.
- `drainOutbound()` already iterates op types in `pending_sync_ops`; add a dispatch branch routing `kChallengeOpTypes` ops to `ChallengeApi.batch(...)` against `PUT /v1/challenges/batch`.

8.6. Wire `ChallengeRepository` write methods to `enqueueChallengeOp` after every local write (Phase-7 / Phase-8 pattern). Reads never enqueue.

8.7. Widget tests (`app/test/features/challenges/presentation/challenges_screen_test.dart`):
- Browse tab → tap *Subscribe* on the first seeded template → assert a `user_challenges` row exists locally and a `pending_sync_ops` row of type `upsert_user_challenge` was enqueued.
- Switch off a subscribed challenge → `archivedAt` is set; the challenge drops off the *This week* tab and shows as *Subscribed: off* on the Browse tab.
- Create a custom challenge with goal=3 → row appears; the strip on home reflects it after one frame.

**Exit:** A full local round-trip works: subscribe → row appears on home → un-subscribe → row disappears → re-subscribe → row reappears. `pending_sync_ops` accumulates the corresponding ops.

---

## Group 9 — Client: completion celebration + checklist row badge

**Goal:** Soft-green confetti modal + persistent badge for the week.

9.1. New widget `app/lib/features/challenges/presentation/widgets/completion_celebration_modal.dart`:
- Triggered from `currentWeekProgressProvider` listener (Riverpod `ref.listen`) when a `ChallengeWeek` transitions to `status=COMPLETED ∧ celebrationSeenAt IS NULL`.
- Opens via `showDialog` with the calm Material 3 dialog theme; soft-green primary button, no red.
- Body copy from `requirements.md` §3.7: *"Mā shā' Allāh — `<title>`. `<goal>` of `<goal>` days this week."*.
- Optional confetti overlay using a single particle widget (`flutter_confetti` first try; if bundle size > 80 KB on the web build measured via `flutter build web --analyze-size`, fall back to a pure-Dart `CustomPaint` particle emitter — keep the dep cost calm).
- Honors *Settings → Reduce animations* (Phase 5): when on, render the modal without confetti at all (text-only).

9.2. On dismiss (`Continue` or backdrop tap), call `ChallengeRepository.markCelebrationSeen(weekId)` which writes `celebrationSeenAt = now()` locally AND enqueues an `upsert_user_challenge_week` op so the field syncs.

9.3. **Re-entry guard** (race against sync pull-down):
- The repository wraps `markCelebrationSeen` in a per-row mutex (`Map<String, Completer<void>>`).
- The provider listener only triggers when `(persisted celebrationSeenAt == null && new derived status == COMPLETED)`.
- After the first trigger, the listener notes the `(challengeId, weekStart)` in a `Set` and ignores subsequent emits for that pair until the next week boundary.

9.4. Checklist row badge:
- Extend `effective_category_section.dart` (Phase 7) — the row builder reads `currentWeekProgressProvider` for any challenge whose source matches the row's task code (or category, for `CATEGORY_WEEKLY_COUNT`) and the row is part of a `COMPLETED` week.
- Render a tiny soft-green chip with the challenge icon top-right of the row (overlay via `Stack`).
- Tooltip: *"Completed this week."*. Tap: navigates to `/challenges`.
- The badge disappears at the next week boundary (re-evaluated on every build via `weekStartFor(today, dow)`).

9.5. Tests:
- `app/test/features/challenges/presentation/widgets/completion_celebration_modal_test.dart` — pump a provider that transitions a single challenge to `COMPLETED`; assert the modal appears, the dismiss writes `celebrationSeenAt`, and a second transition (e.g., the user un-ticks a task and re-ticks it) does **not** open the modal again.
- `app/test/features/challenges/presentation/widgets/checklist_row_badge_test.dart` — pump a challenge with `status=COMPLETED` and an underlying task on Fajr; assert the chip is present on every Fajr row that matches the source.
- Reduce-animations a11y test: with the setting on, confetti widget is absent from the tree.

**Exit:** Subscribe to *Pray every Fajr in congregation*, complete `fajr_first_congregation` seven distinct dates → modal opens once, dismisses, and the badge persists on Fajr rows until the next Saturday.

---

## Group 10 — Sync: `ChallengeRestoreService` + first-sign-in hook

**Goal:** Sign-in on a second device pulls challenges down (or pushes them up) deterministically.

10.1. New service `app/lib/features/challenges/data/challenge_restore_service.dart`, mirroring `customization_restore_service.dart` (Phase 8):
- Reads `TokenStorage.isChallengeFirstSyncDone(userId)`.
- Hits `GET /v1/challenges/snapshot-state`.
- **No-snapshot branch:** enqueue every local `UserChallenge` + `UserChallengeWeek` row as `upsert_*` ops, call `SyncService.drainOutbound()`, mark flag done.
- **Snapshot branch:** await `confirmReplacePrompt(totals)`. On `true`: drop challenge-typed ops from `pending_sync_ops`, truncate `user_challenges` + `user_challenge_weeks` (the **global** `challenge_templates` table is identical on both sides and is **never** touched), `GET /v1/challenges` → repopulate. Mark flag done. On `false`: mark flag done, emit `cancelledByUser`.
- Emits the Phase-8 event stream: `idle`, `checking`, `pushing`, `restoring`, `done(restoredCount)`, `cancelledByUser`, `error(message)`.

10.2. Extend `TokenStorage` (`app/lib/features/auth/data/token_storage.dart`) with the three new methods from `requirements.md` §3.10 — namespaced `challenge_first_sync_done:<userId>`.

10.3. Wire into `SyncService.runFirstSignInMigrationIfNeeded()` **after** the Phase-8 `CustomizationRestoreService.restoreIfNeeded(...)` call:

```dart
await _customizationRestore.restoreIfNeeded(confirmReplacePrompt: customizationPrompt);
await _challengeRestore.restoreIfNeeded(confirmReplacePrompt: challengePrompt);
```

Order is fixed (logs → customizations → challenges) so a challenge that points at a user-owned task can resolve its `sourceRef` after the customization restore finishes.

10.4. The two confirmation prompts can be unified into a single dialog at the calling layer ("We found your saved checklist **and** your saved challenges …"). This keeps the user from being prompted twice on the same screen. Drive both restore services from a shared `restoreConfirmProvider` if the unified-dialog path is chosen; otherwise show two sequential dialogs (acceptable but less calm).

10.5. Tests:
- `app/test/features/challenges/data/challenge_restore_service_test.dart`:
  - Fake `ChallengeApi.snapshotState()` → `hasSnapshot=false`; pre-populate local DB with 2 challenges + their current week rows; call `restoreIfNeeded(...)`; assert four ops landed in `pending_sync_ops`, then `drainOutbound` was called and the flag was set.
  - Snapshot branch: server returns 3 challenges + 3 weeks; local DB has 1 different challenge + a `upsert_user_challenge` pending op; `confirmReplacePrompt → true` → local matches server exactly; pending op gone; `batch_log` ops (added beforehand) survive.
  - Cancel branch: `confirmReplacePrompt → false` → nothing touched; flag set; `cancelledByUser` emitted.
- Integration test (`app/integration_test/first_sign_in_phase9_test.dart`):
  - Stub server with a populated challenge catalog; fresh client; sign in (already confirmed); tap Restore on the unified dialog; assert the home strip on the second device shows the same active challenges with the same progress as the first device.

**Exit:** Two-device demo: device A subscribes to two templates + makes one custom; device B (different account state) signs in → unified restore dialog → tapping Restore replaces local data with device A's snapshot.

---

## Group 11 — Hardening, i18n parity, docs, and merge prep

**Goal:** Make Phase 9 mergeable.

11.1. Cross-side seed parity script — extend (or copy from Phase 7's icon-parity script) `tools/check_challenge_template_parity.dart`: reads the Dart const `kSeededChallengeTemplates` and the TS const from `api/src/challenges/seed-templates.ts`, asserts code-by-code equality on every field. Runs in CI alongside `tools/check_icon_parity.dart`.

11.2. RTL pass: switch device to Arabic, walk through:
- Home strip in each of its three render modes.
- Settings → *Week start* radio (labels render RTL, default Saturday).
- Challenges screen, both tabs.
- Custom challenge sheet (icon picker grid stays LTR per Phase-7 rule, everything else mirrors).
- Completion modal (text + button alignment).
- Sign-in on a second device → unified restore dialog → Restore.

11.3. Tone audit (mission #1) on every new visible string — `app_en.arb` and `app_ar.arb` — using the Phase-7 / Phase-8 blocklists:
- English: *invalid, illegal, denied, forbidden, failure, error code, discard, lose, missed*. (Note: *missed* is added to the blocklist for this phase — see §3.5 of `requirements.md`.)
- Arabic: `خطأ، فشل، ممنوع، غير مسموح، غير صالح، محظور، فاتك`.

11.4. Update `api/README.md`: one paragraph on the new `/v1/challenges/*` surface and the schema additions.

11.5. Update root `README.md`: one short paragraph linking the weekly challenges story (subscribe → derive progress → celebrate).

11.6. Update `spec/roadmap.md`: tick Phase 9; move the *"first batch of challenges"* exit criterion to *Done*; promote any deferred items (history list, manual source kind, push notifications for challenge milestones) into the *Post-Roadmap* backlog with a one-liner each.

11.7. Update `spec/tech-stack.md` *Data Model* section: replace the existing *"`challenges` — optional weekly goals (Phase ≥ 6)"* note with a concrete reference to the three new tables.

11.8. Manual QA against every checkbox in `validation.md`; record a ≤ 90-second demo of:
- Home strip → zero-state → tap → Browse → subscribe.
- Complete the underlying task on consecutive days → home strip advances.
- Final day → confetti modal opens → dismiss → checklist row shows the soft-green chip.
- Switch *Week start* to Sunday → snackbar → next week's row materializes on Sunday.
- Two-device sign-in → unified restore dialog → tap Restore → home matches device A.

**Exit:** Every checkbox in `validation.md` ticked; branch ready to merge.

---

## Group 12 — Demo & merge prep

**Goal:** Ship.

12.1. Author the merge-commit body summary: one paragraph on the auto-from-logs derivation model, one on the Saturday-default week with Settings override, one on the new sync surface, one *"What's deferred"* listing challenge history list, manual source kind, milestone notifications, hard-delete.

12.2. Confirm CI is green on the branch (`api/test`, `api/test:e2e`, `flutter analyze`, `flutter test`, `flutter integration_test`, icon parity, challenge-template parity).

12.3. Open a PR titled `Phase 9 — Weekly Challenges` referencing this plan and `validation.md`.

**Exit:** PR opened, demo attached, all gates green.
