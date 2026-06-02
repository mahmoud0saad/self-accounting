# Validation — Phase 9: Weekly Challenges

How we know Phase 9 is **done, working, and safe to merge** into `master`. Every section below must be checkable; ambiguity means it's not validation.

> Branch: `phase-9-2026-05-19-weekly-challenges`
> Pair with: `requirements.md`, `plane.md`

---

## 1. Roadmap exit criterion (must pass)

From `spec/roadmap.md` Phase 9:

> *Predefined challenge templates (e.g., "Read 1 Juz' this week", "Pray all Fajr in congregation").*
> *Custom user-defined challenges.*
> *Challenge progress widget on home + completion celebration.*
> *Exit: First batch of challenges live; users can opt in/out weekly.*

**How we test it (one consolidated scenario):**

- [ ] **Device A** (fresh install, signed in as `qa+phase9@example.com`, already confirmed):
  1. Open the app → home → tap the *"This week: start a challenge"* card → Challenges screen opens.
  2. Tab to **Browse** → subscribe to *Pray every Fajr in congregation*, *Pray Witr every night*, and *Read Qur'an every day*.
  3. Tab to **+ Create custom challenge** → title *"Memorize 3 ayat"*, icon `auto_stories`, source = default category *Quran & Fasting*, goal = 5 → Create.
  4. Return to home → strip shows 4 active challenges as a horizontal chip row.
- [ ] Complete `fajr_first_congregation` on five distinct dates this week → the *Pray every Fajr* chip shows `5 / 7`.
- [ ] Complete `fajr_first_congregation` on the remaining two dates → the soft-green **confetti modal** opens, dismisses on *Continue*; the Fajr congregation rows on the home checklist show the tiny soft-green completed-this-week chip; the chip in the strip flips to *7 / 7* with a checkmark.
- [ ] Sign out on Device A.
- [ ] **Device B** (fresh install, signing into the same account for the first time):
  1. Complete sign-in + email confirm.
  2. Within 30 seconds of the first foreground, the unified restore dialog appears ("We found your saved checklist **and** your saved challenges on this account…") → tap **Restore**.
  3. Within 15 seconds the home strip on Device B shows the same four active challenges and the same per-week progress as Device A (including the COMPLETED Fajr chip with the checkmark).
- [ ] Still on Device B: tap the Fajr congregation chip → land on Challenges → *This week* tab → that challenge sits at the top with `7 / 7`, status COMPLETED, and the celebration modal **does not re-open** (the `celebrationSeenAt` synced with the row).
- [ ] Still on Device B: open Challenges → toggle *Pray Witr every night* **off** → it disappears from the strip on home. Toggle it back **on** → it returns with the **same** per-week progress (proving the row was archived, not deleted).

---

## 2. Decision-specific acceptance

### 2.1 Progress model — auto-derived from `daily_logs` (decision §4.1)

- [ ] No new user-facing affordance for "I did the challenge today" exists anywhere in the app. Verified by a UI audit + a unit test asserting that no widget under `app/lib/features/challenges/presentation/widgets/` calls any write method named `markDone`, `tick`, or similar.
- [ ] The `customSourceKind` enum exists in code and accepts the literal string `MANUAL`, but `POST /v1/challenges` rejects any custom challenge with `customSourceKind = MANUAL` with HTTP 422 and body `{ code: "MANUAL_NOT_SUPPORTED_PHASE_9" }`.
- [ ] Every seeded `ChallengeTemplate` has `sourceKind ∈ { TASK_WEEKLY_COUNT, CATEGORY_WEEKLY_COUNT }` and a `sourceRef` that resolves to an entry in `api/src/challenges/source-refs.ts` (asserted by `api/test/challenges/seed.spec.ts`).
- [ ] For `TASK_WEEKLY_COUNT`, the engine counts **distinct dates**, not log rows — verified by a unit test where two completions for the same `(taskId, date)` exist and the engine still counts that day as `1`.
- [ ] For `CATEGORY_WEEKLY_COUNT`, a day counts iff the **effective** category bar is `1.0` (using `DailyProgress.forCategory` — Phase 4). Tested with a Fajr block containing 3 visible tasks: 2 completed → day not counted; 3 completed → day counted.
- [ ] Monotonic guard: `achievedCount` never decreases on recomputation. Test: persisted=5, derived=3 → persisted stays 5. Persisted=3, derived=5 → persisted advances to 5.

### 2.2 Backend scope — full stack this phase (decision §4.2)

- [ ] `api/prisma/migrations/*_phase_9_challenges/migration.sql` exists and is purely additive (no `DROP`, no `ALTER ... DROP`, no `MODIFY`).
- [ ] `npx prisma migrate diff --from-migrations --to-schema-datamodel` is empty after the migration is applied.
- [ ] `GET /v1/challenges/templates`, `GET /v1/challenges`, `POST /v1/challenges`, `PATCH /v1/challenges/:id`, `PUT /v1/challenges/:id/weeks/:weekStart`, `GET /v1/challenges/snapshot-state`, `PUT /v1/challenges/batch` — all six + batch — are present in OpenAPI under the `Challenges` tag with full DTO examples.
- [ ] Drift `schemaVersion` is `6`. Re-opening a v5 database upgrades cleanly: no data loss in `daily_logs`, `user_categories`, `user_tasks`, `user_category_overrides`, `user_task_overrides`, `pending_sync_ops`, `app_settings`, `category_notification_schedules`, `task_notification_toggles`.
- [ ] The Drift seed for `challenge_templates` produces exactly the same six rows by `code` as the Prisma seed. Asserted by `tools/check_challenge_template_parity.dart` exiting `0`.

### 2.3 UX & validation — Sat→Fri week + 1-line strip + confetti (decision §4.3)

- [ ] Default `app_settings.week_start_dow` on a fresh install is `sat`.
- [ ] Settings → *Week start* radio offers Saturday / Sunday / Monday only; default Saturday. Subtitle reads *"Applies to next week."*.
- [ ] Changing *Week start* on Tuesday does **not** retroactively re-window the current `UserChallengeWeek` rows. Verified by a Drift snapshot before and after toggle: `weekStart` values are unchanged.
- [ ] On the **next** week boundary (the chosen `dow`), the freshly-created `UserChallengeWeek` rows use the new `weekStart`. Verified by a clock-shift integration test.
- [ ] The home strip lives in `checklist_screen.dart` **immediately below** `StreakPills` and **above** the first category section. Verified by a widget tree assertion (`tester.getTopLeft(StreakPills).dy < tester.getTopLeft(WeeklyChallengeStrip).dy < tester.getTopLeft(first EffectiveCategorySection).dy`).
- [ ] The strip is never taller than 56 px in any of its three render modes (zero / one / many). Verified by `tester.getSize(WeeklyChallengeStrip).height <= 56` in each pumped mode.
- [ ] Completion celebration:
  - [ ] Modal opens **once** when `(status: IN_PROGRESS → COMPLETED ∧ celebrationSeenAt == null)`. Verified by a Riverpod listener test that triggers the transition twice (un-tick + re-tick a task on the final day) and asserts the modal is built exactly once.
  - [ ] Modal uses **soft green**, not red. Asserted by a colour-token grep on `completion_celebration_modal.dart` + a golden test against the calm palette.
  - [ ] *Reduce animations* setting (Phase 5) on → confetti widget is **not** in the tree; modal still opens with text only. Verified by a widget test.
  - [ ] Dismiss writes `celebrationSeenAt = now()` locally and enqueues `upsert_user_challenge_week` to `pending_sync_ops`. Verified by a repository test.
  - [ ] Soft-green completed-this-week chip appears on every `EffectiveCategorySection` row whose task / category matches the `sourceRef` of any `COMPLETED` weekly challenge for the current week. Verified by a widget test.
  - [ ] The chip disappears at the next `weekStart` (cross-week boundary). Verified by a clock-shift widget test.

---

## 3. Backend API contract

### 3.1 New endpoint smoke matrix

| Endpoint | Anon | Authed unconfirmed | Authed confirmed empty | Authed confirmed populated |
|---|---|---|---|---|
| `GET /v1/challenges/templates` | 401 | 403 | 200 + 6 rows | 200 + 6 rows (templates are global) |
| `GET /v1/challenges` | 401 | 403 | 200 `[]` | 200 + N rows |
| `POST /v1/challenges` | 401 | 403 | 201 (new) / 409 (dup template) / 422 (invalid custom) | same |
| `PATCH /v1/challenges/:id` | 401 | 403 | 404 | 200 / 422 (forbidden field edit) |
| `PUT /v1/challenges/:id/weeks/:weekStart` | 401 | 403 | 404 (no challenge) | 200 / 409 (goalCount mismatch) / 422 (bad weekStart dow) |
| `GET /v1/challenges/snapshot-state` | 401 | 403 | 200 `{ hasSnapshot: false, totals: {0,0} }` | 200 `{ hasSnapshot: true, totals: {...>0...}, lastUpdatedAt: <ISO8601> }` |
| `PUT /v1/challenges/batch` | 401 | 403 | 200 `[]` | 200 + per-op outcomes |

- [ ] Every cell above is covered by a passing e2e test in `api/test/challenges/`.
- [ ] `totals.userChallenges + totals.userChallengeWeeks > 0 ⇔ hasSnapshot === true` — asserted by a property test with random inputs.

### 3.2 `snapshot-state` ↔ `/v1/challenges` consistency

- [ ] For 10 randomly-generated populated users, the counts returned by `GET /v1/challenges/snapshot-state` match `(arr.length for arr in [userChallenges, derivedWeekRows])` from the same user's `GET /v1/challenges` payload — verified by a single integration test that hits both endpoints back-to-back.
- [ ] Archived `UserChallenge` rows (`archivedAt IS NOT NULL`) count toward `hasSnapshot=true` and toward `totals.userChallenges` (i.e., archived ≠ absent; they are still part of the snapshot).

### 3.3 Write-endpoint contract

- [ ] `POST /v1/challenges` with `{ templateCode: "fajr_in_jamaah" }` on an empty user → 201 + a `UserChallenge` with `templateCode` set, all `custom*` fields null.
- [ ] `POST /v1/challenges` twice with the same `templateCode` → second call returns 409 `{ code: "ALREADY_SUBSCRIBED" }`.
- [ ] `POST /v1/challenges` with `templateCode` for a previously-archived row → 201 (new row; old archived row preserved).
- [ ] `POST /v1/challenges` with `{ customTitle: "X", customIcon: "star", customSourceKind: "TASK_WEEKLY_COUNT", customSourceRef: "<non-existent>", customGoalCount: 7 }` → 422 `{ code: "INVALID_SOURCE_REF" }`.
- [ ] `POST /v1/challenges` with `customGoalCount: 8` → 422.
- [ ] `POST /v1/challenges` with `customGoalCount: 0` → 422.
- [ ] `PATCH /v1/challenges/:id` with `customSourceKind` or `customSourceRef` → 422 `{ code: "SOURCE_NOT_EDITABLE" }`.
- [ ] `PATCH /v1/challenges/:id` with `archivedAt: null` on an archived row → 200, row resurfaces.
- [ ] `PUT /v1/challenges/:id/weeks/:weekStart` with `weekStart` on a Tuesday → 422 `{ code: "WEEK_START_DOW_INVALID" }`.
- [ ] `PUT /v1/challenges/:id/weeks/:weekStart` twice with the same row but different `goalCount` → second call 409 `{ code: "GOAL_COUNT_LOCKED" }`.
- [ ] `PUT /v1/challenges/batch` with a stale `clientUpdatedAt` on an `upsert_user_challenge_week` op → that op returns outcome `STALE`; other ops in the same batch are unaffected (per-op LWW, not per-batch).

### 3.4 Backward compatibility

- [ ] Re-running the Phase-8 e2e suite (`api/test/customization/`) against the Phase-9 server passes byte-for-byte. No drift on `GET /v1/catalog`, `PUT /v1/customizations/batch`, `GET /v1/catalog/snapshot-state`, `POST /v1/user-categories`, `PATCH /v1/user-categories/:id`, `DELETE /v1/user-categories/:id`, `POST /v1/user-tasks`, `PATCH /v1/user-tasks/:id`, `DELETE /v1/user-tasks/:id`, `PUT /v1/user-category-overrides/:categoryCode`, `PUT /v1/user-task-overrides/:taskCode`.
- [ ] Phase-6 auth & confirmation flows pass unchanged. Phase-5 / Phase-6 log endpoints pass unchanged.

### 3.5 OpenAPI

- [ ] `GET /v1/docs` shows the new `Challenges` tag with all seven endpoints + DTO examples for `ChallengeTemplateDto`, `UserChallengeDto`, `UserChallengeWeekDto`, `SnapshotStateDto`, `ChallengeBatchOpDto`, `ChallengeBatchResultDto`.
- [ ] No previously-documented endpoint has been removed or changed shape.

---

## 4. Flutter client

### 4.1 Home strip

- [ ] Zero subscriptions → strip renders the *"This week: start a challenge"* card; tapping it navigates to `/challenges`.
- [ ] One subscription → strip renders single row with icon + title + `N / goal` + progress indicator.
- [ ] 2+ subscriptions → strip renders a horizontally-scrollable chip row, one chip per active challenge.
- [ ] During `effectiveCatalogProvider.loading` or `.error` the strip renders `SizedBox.shrink()` — verified by a widget test.
- [ ] Strip respects RTL (Arabic locale) — verified by a golden test against an Arabic locale snapshot.
- [ ] Strip height is `≤ 56 px` in every render mode (golden + size assertion test).

### 4.2 Challenges screen

- [ ] **This week** tab lists only non-archived challenges. Empty state copy is calm and offers a *Browse templates* CTA.
- [ ] **Browse** tab lists exactly the six seeded templates grouped by source category. Each tile has a *Subscribe* / *Subscribed* trailing button; tapping flips state immediately (optimistic) and enqueues a `pending_sync_ops` row.
- [ ] Custom challenge sheet:
  - [ ] Title text field max length 60 chars (the 61st keystroke is silently dropped, no shaming error).
  - [ ] Icon picker is the same Phase-7 grid; can be searched.
  - [ ] Source picker shows `Task` / `Category` tabs; populated from `effectiveCatalogProvider`; both default and user-owned items appear.
  - [ ] Goal slider: `1..7`, default `7`. Slider label reads e.g. *"Goal: 5 days this week"*.
  - [ ] Create button writes locally + enqueues + closes sheet + the new card appears on *This week*.
- [ ] Toggling the *subscribed* switch off on a challenge that has a `COMPLETED` week → the challenge disappears from *This week*; the `UserChallengeWeek` for the current week remains (`status` transitions to `CANCELLED`); re-toggling **on** restores the prior week row with its `achievedCount` intact.

### 4.3 Settings — Week start

- [ ] Radio control is **visible** in Settings regardless of sign-in state (challenges are local-first).
- [ ] Default value on a fresh install is Saturday.
- [ ] Toggling shows a snackbar *"Your new week starts <weekday>."* — verified by a widget test.
- [ ] The change does not retroactively re-window existing `UserChallengeWeek` rows. Verified by a Drift snapshot before and after.

### 4.4 Sync queue interplay

- [ ] Every local write (`subscribe`, `archive`, `un-archive`, `create custom`, `upsert week`, `mark celebration seen`) enqueues exactly one matching `pending_sync_ops` row of type in `kChallengeOpTypes`.
- [ ] Coalescing: ten rapid `upsert_user_challenge_week` writes for the same `(challengeId, weekStart)` produce exactly one queued op (latest payload wins). Verified by a sync repository test.
- [ ] During the snapshot-wins restore: the challenge-typed pending ops (`upsert_user_challenge`, `delete_user_challenge`, `upsert_user_challenge_week`) are removed from `pending_sync_ops`; `batch_log` ops + customization-typed ops are **not** touched (verified by row count + payload snapshot).
- [ ] After restore, any subsequent challenge edit enqueues a normal Phase-9 op and drains within the next sync cycle (verified end-to-end on a real device).

### 4.5 First sign-in restore — automatic flow

- [ ] On a freshly-installed app, signing into an account where `GET /v1/challenges/snapshot-state` returns `hasSnapshot=true` triggers the unified restore confirmation **before** any local DB mutation under `user_challenges` / `user_challenge_weeks`; cancelling leaves those two tables byte-for-byte unchanged (verified by Drift table hash before and after).
- [ ] On the same flow but `hasSnapshot=false`, **no** challenge-specific dialog appears; the local subscriptions + week rows are pushed up and end up on the server within 30 seconds (verified by a follow-up `/v1/challenges` curl).
- [ ] The flag `challengeFirstSyncDone[userId]` is set on every terminal state of the service: `done`, `cancelledByUser`, **but not** on `error` (so an offline blip on first foreground retries on next foreground).
- [ ] Restore order is **logs → customizations → challenges**, verified by a request-log assertion in the integration test.
- [ ] On the snapshot branch the local mutation is wrapped in **one Drift transaction** so an app crash mid-restore leaves the DB in either pre-restore or post-restore state — never partial. Verified by a fault-injection unit test that throws after the `GET /v1/challenges` response is parsed and asserts the DB matches the pre-restore snapshot.
- [ ] The `challenge_templates` table is **never** truncated by the restore service. Verified by a repository test: pre-populate the table with the six seeded rows + a fake seventh row from a hypothetical future seed; run restore; the seventh row is still there.

### 4.6 Localization

- [ ] Every new visible string exists in **both** `app/l10n/app_en.arb` and `app/l10n/app_ar.arb`. Strings include (non-exhaustive): the six template titles, the *This week: start a challenge* zero-state, the *Browse templates* CTA, the *Subscribe* / *Subscribed* labels, the custom-challenge sheet labels (Title, Icon, Source, Goal: N days this week), the Settings *Week start* labels, the three weekday names (Saturday, Sunday, Monday) if not already present from Phase-3 streak strip, the unified restore dialog title + body, the celebration modal copy (*Mā shā' Allāh*, *<title>*, *<goal> of <goal> days this week*), the *Continue* / *View challenge* buttons, the *Completed this week.* tooltip on the row chip, the *Your new week starts <weekday>.* snackbar.
- [ ] Arabic RTL pass: walk through the §1 scenario in Arabic on a real device or RTL emulator; layouts mirror correctly; the icon picker grid stays LTR (per Phase-7 rule).

### 4.7 Tone (mission #1)

- [ ] No new visible string contains words from the blocklist:
  - English (`rg -i` against the **diff** of `app/l10n/app_en.arb`): *invalid, illegal, denied, forbidden, failure, error code, discard, lose, missed*.
  - Arabic (`rg` against the diff of `app/l10n/app_ar.arb`): `خطأ`, `فشل`, `ممنوع`, `غير مسموح`, `غير صالح`, `محظور`, `فاتك`.
- [ ] The completion modal body uses *"Mā shā' Allāh"* + a positive phrasing; never *"Done!"* alone, never any imperative shaming.
- [ ] The "this week's row not completed" chip body reads *"Next week starts <weekday>"* in soft grey — never *"Missed"*.
- [ ] No new button is red. Verified by a colour-token grep in `app/lib/features/challenges/`.

---

## 5. Tests (must be green in CI)

- [ ] Backend: `npm run test` — all suites pass, including new `challenges/seed.spec.ts`, `challenges/challenges.service.spec.ts`, `challenges/challenges-write.service.spec.ts`.
- [ ] Backend: `npm run test:e2e` — covers §3.1 matrix, §3.2 consistency, and §3.3 write-endpoint contract.
- [ ] Backend: `npm run lint` — 0 errors.
- [ ] Backend: `npx prisma migrate diff --from-migrations --to-schema-datamodel` — empty.
- [ ] Backend: `npx prisma migrate dev` on a fresh DB applies cleanly and seeds the six templates.
- [ ] Flutter: `flutter analyze` — 0 errors.
- [ ] Flutter: `flutter test` — all suites pass, including new tests for `WeekBoundary`, `ChallengeRepository`, `ChallengeProgressEngine`, `ChallengeRestoreService`, `WeeklyChallengeStrip`, `ChallengesScreen`, `CompletionCelebrationModal`, the checklist row badge, and the v5→v6 Drift migration.
- [ ] Flutter: `integration_test/first_sign_in_phase9_test.dart` — passes on both Android emulator and iOS simulator.
- [ ] Icon-parity script (`tools/check_icon_parity.dart`) — still exits `0`.
- [ ] Challenge-template parity script (`tools/check_challenge_template_parity.dart`) — exits `0`.
- [ ] GitHub Actions CI on this branch is green end-to-end.

---

## 6. Security & data-integrity gates

- [ ] `GET /v1/challenges/snapshot-state` returns counts **only for `req.user.id`**; forging a body or query userId is impossible (no userId parameter is read from the request).
- [ ] `POST /v1/challenges` rejects a `customSourceRef` referencing a `UserTask` or `UserCategory` owned by another user with 422 `{ code: "INVALID_SOURCE_REF" }`. Verified by an e2e test that creates a challenge under user A pointing at user B's user-owned task id.
- [ ] No PII in any new server log line — verified by `rg` over the new code under `api/src/challenges/`. Log lines may include user id and counts; they must **not** include challenge titles, custom titles, or source refs.
- [ ] On the snapshot branch, the local DB mutation is wrapped in **one Drift transaction** so an app crash mid-restore leaves the DB in either pre-restore or post-restore state — never partial (also covered in §4.5).
- [ ] On the no-snapshot branch, a network failure during outbound drain leaves the challenge-typed ops in `pending_sync_ops` for the next cycle to pick up; nothing is silently dropped.
- [ ] The `challengeFirstSyncDone` flag is per-user (namespaced by `userId`) — verified by a unit test that signs out as user A and signs in as user B on the same device and confirms the gate runs again.
- [ ] `UserChallengeWeek.celebrationSeenAt` is enforced as monotonic forward — a server PUT that sets it back to `null` is rejected with 422 `{ code: "CELEBRATION_SEEN_LOCKED" }`. Verified by an e2e test.
- [ ] `UserChallengeWeek.goalCount` is locked on first insert — a server PUT with a different `goalCount` for an existing `(challengeId, weekStart)` returns 409 (also covered in §3.3).

---

## 7. Documentation

- [ ] `README.md`: short paragraph on weekly challenges (auto-derived from daily logs, opt-in templates + custom, Saturday default week start, calm celebration).
- [ ] `api/README.md`: section describing the new `/v1/challenges/*` surface and the three new tables.
- [ ] `spec/roadmap.md`: Phase 9 ticked; any deferred items (history list, `MANUAL` source kind, milestone notifications, hard-delete) listed under *Post-Roadmap (Backlog)*.
- [ ] `spec/tech-stack.md` *Data Model* section: the *"challenges (Phase ≥ 6)"* placeholder is replaced with concrete references to the three new tables.

---

## 8. Mergeability gate (final checklist)

Phase 9 is merged into `master` only when **all** of these are true:

- [ ] Every checkbox in §1, §2 (all sub-sections), §3, §4 (all sub-sections), §5, §6, §7 is ticked.
- [ ] Manual demo recorded (≥ 60s screen capture) showing: subscribe → progress derives from `daily_logs` → final completion → confetti modal → row badge → Settings *Week start* toggle → second-device sign-in → unified restore → home matches.
- [ ] Two-device convergence verified once on real hardware (not only emulators) — at least one of the devices must be a real Android phone.
- [ ] No secrets, no `.env` files, no real email passwords in the diff.
- [ ] Confetti dependency bundle-size delta on `flutter build web --analyze-size` is **≤ 80 KB**; otherwise the celebration modal ships text-only (also acceptable for merge — see `plane.md` §9.1).
- [ ] A short *"What's deferred to Phase 10"* paragraph is added to the merge commit body (challenge history list, `MANUAL` source kind, milestone notifications, hard-delete affordance for user challenges, shared / household challenges).
