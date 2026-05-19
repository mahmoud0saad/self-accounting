# Validation — Phase 8: Tasks & Category Sync

How we know Phase 8 is **done, working, and safe to merge** into `master`. Every section below must be checkable; ambiguity means it's not validation.

> Branch: `phase-8-2026-05-19-tasks-category-sync`
> Pair with: `requirements.md`, `plane.md`

---

## 1. Roadmap exit criterion (must pass)

From `spec/roadmap.md` Phase 8:

> *sync category and tasks from server to db device if has backup.*
> *upload new customization (task, category) to account after change.*
> *when toggle (task, category) from manage don't remove from db only deactivate and can active again when toggle.*

**How we test it (one consolidated scenario):**

- [ ] On **Device A** (fresh install, signed in as `qa+phase8@example.com`, already confirmed):
  1. Open `Manage checklist`.
  2. Create category `Tafsir study` with the `menu_book` icon.
  3. Add two tasks under it: `Read 5 ayat with tafsir` (8 pts, `book_5`) and `Write reflection` (5 pts, `psychology`).
  4. Hide the default task `Tahajjud (3+ rakaat)` via its visibility toggle.
  5. Force a sync (cold-start the app once).
- [ ] On **Device B** (fresh install, signing into the same account for the first time):
  1. Complete sign-in + email confirm flow.
  2. The *"We found your saved checklist on this account…"* dialog appears within 30 seconds of the first foreground.
  3. Tap **Restore**.
  4. Within 15 seconds the home checklist on Device B shows `Tafsir study` with both tasks, and `Tahajjud (3+ rakaat)` is hidden.
- [ ] Still on Device B: open Manage checklist, toggle `Tahajjud (3+ rakaat)` **back to visible**. The home checklist shows it again with its **seeded default point value** (no override row remains, or `hidden=false` was written — either is valid).
- [ ] Still on Device B: open Manage checklist, toggle `Read 5 ayat with tafsir` **off**. The home checklist hides it. Toggle it **on again** — it returns with the same point value (8 pts) and the same icon (`book_5`) — proving the row was deactivated, not deleted.

---

## 2. Decision-specific acceptance

### 2.1 Pull trigger — sign-in only (decision §4.1)

- [ ] First foreground after sign-in (on a device where `customizationFirstSyncDone[userId] = false`) calls `GET /v1/catalog/snapshot-state` **exactly once**, verified by a request-log assertion in the integration test.
- [ ] Subsequent foregrounds on the same signed-in session do **not** call `GET /v1/catalog/snapshot-state` (verified by the same log assertion across 5 consecutive foregrounds).
- [ ] Sign-out + sign-in **on the same device** with the same `userId` does **not** re-trigger the restore prompt unless the user explicitly taps *Restore checklist from your account* in Settings (verified by sign-out → sign-in → no dialog).
- [ ] After tapping *Restore checklist from your account* in Settings, the flag is cleared and the prompt does re-appear on the next foreground if `hasSnapshot=true`.

### 2.2 Toggle vs. *Remove permanently* (decision §4.2)

- [ ] Default category row in Manage screen shows **only**: leading `Switch`, trailing edit affordance. **No** *Remove permanently* item in any menu.
- [ ] User-owned category row in Manage screen shows: leading `Switch`, trailing overflow menu with `Edit` + `Remove permanently`.
- [ ] User-owned task row with **zero** `daily_logs` references → `Remove permanently` is enabled; tapping it shows a soft-amber confirm sheet with **Cancel** + **Remove permanently** buttons; confirming hits the existing Phase-7 `DELETE /v1/user-tasks/:id` (no `?archive`) and the row vanishes from local DB.
- [ ] User-owned task row with **one or more** `daily_logs` references → `Remove permanently` shows the *"This category/task has history. Hide it instead."* body and a single **Hide** button that invokes the visibility toggle path.
- [ ] Default task row → toggle off → no row removed from `tasks` (DB snapshot before and after assertion); toggle on → `user_task_overrides` row is either absent or has `hidden=false`; the home checklist re-shows the seeded values for `name`, `points`, `icon`.
- [ ] User-owned task row → toggle off → `user_tasks.archivedAt` becomes non-null; toggle on → `archivedAt` is cleared; the row's `name`, `points`, `icon` are unchanged across both toggles (verified by row-snapshot comparison).
- [ ] No code path in the visibility toggle calls `DELETE /v1/user-tasks/:id` or `DELETE /v1/user-categories/:id` — verified by a unit test that mocks `SyncApi` and asserts only `PUT /v1/user-task-overrides/...` / `PATCH /v1/user-tasks/...` (for `archivedAt`) are reached.

### 2.3 Restore decision tree (decision §4.3)

- [ ] **No-snapshot branch**: a freshly-signed-in user with 2 local user-owned categories + 5 local user-owned tasks (created while anonymous) is asked **no** confirmation dialog and ends up with all 7 rows on the server (verified by `GET /v1/catalog` on a separate curl).
- [ ] **Snapshot branch**: a user with 0 local customizations but 4 server categories + 12 server tasks + 3 overrides sees the confirmation dialog and, after tapping Restore, ends up with exactly those 4 + 12 + 3 rows locally (verified by `CatalogRepository.watch()` after the restore completes).
- [ ] **Snapshot branch + local divergence**: user has 1 local user-owned task that doesn't exist on the server, AND a pending `upsert_user_task` op in `pending_sync_ops` for that local task → after tapping Restore: the local task row is gone, the pending op is gone, the server snapshot is replayed locally.
- [ ] **Snapshot branch + Cancel**: tapping Cancel on the confirmation dialog sets `customizationFirstSyncDone = true`, emits `cancelledByUser`, leaves the local DB untouched, and does **not** re-prompt on the next foreground.
- [ ] **Orphan log prune**: on the snapshot branch, a `daily_logs` row with a `userTaskId` that doesn't exist after replay is deleted; a `daily_logs` row referencing a **default** task code (via `taskId`, not `userTaskId`) survives (verified by row counts before and after).
- [ ] `pending_sync_ops` rows with `opType = 'batch_log'` are **not** touched on the snapshot branch (verified by row count + payload snapshot).

---

## 3. Backend API contract

### 3.1 New endpoint smoke matrix

| Endpoint | Anon | Authed unconfirmed | Authed confirmed empty | Authed confirmed populated |
|---|---|---|---|---|
| `GET /v1/catalog/snapshot-state` | 401 | 403 | 200 `{ hasSnapshot: false, totals: {0,0,0,0} }` | 200 `{ hasSnapshot: true, totals: {...>0...}, lastUpdatedAt: <ISO8601> }` |

- [ ] Every cell above is covered by a passing e2e test in `api/test/customization/snapshot-state.e2e.spec.ts`.
- [ ] `totals.userCategories + totals.userTasks + totals.categoryOverrides + totals.taskOverrides > 0 ⇔ hasSnapshot === true` — asserted by a property test with random inputs.

### 3.2 `snapshot-state` ↔ `/v1/catalog` consistency

- [ ] For 10 randomly-generated populated users, the counts returned by `snapshot-state` match `(arr.length for arr in [userCategories, userTasks, userCategoryOverrides, userTaskOverrides])` from the same user's `/v1/catalog` payload — verified by a single integration test that hits both endpoints back-to-back.
- [ ] Archived user-tasks (`archivedAt IS NOT NULL`) count toward `hasSnapshot = true` and toward `totals.userTasks` (i.e., archived ≠ absent; they are still part of the snapshot).

### 3.3 Backward compatibility

- [ ] `GET /v1/catalog`, `PUT /v1/customizations/batch`, `POST /v1/user-categories`, `PATCH /v1/user-categories/:id`, `DELETE /v1/user-categories/:id`, `POST /v1/user-tasks`, `PATCH /v1/user-tasks/:id`, `DELETE /v1/user-tasks/:id`, `PUT /v1/user-category-overrides/:categoryCode`, `PUT /v1/user-task-overrides/:taskCode` — all return identical responses byte-for-byte against the Phase-7 e2e fixtures (no schema drift, no DTO break). Verified by re-running the Phase-7 e2e suite against the Phase-8 server with no edits.
- [ ] `prisma migrate diff --from-migrations --to-schema-datamodel` is empty (Phase 8 ships zero migrations).

### 3.4 OpenAPI

- [ ] `GET /v1/docs` shows `GET /v1/catalog/snapshot-state` under the `Customization` tag with a complete `SnapshotStateDto` example.
- [ ] No previously-documented endpoint has been removed or changed shape.

---

## 4. Flutter client

### 4.1 First sign-in restore — automatic flow

- [ ] On a freshly-installed app, signing in to an account where `hasSnapshot = true` shows the restore confirmation dialog **before** any local DB mutation; cancelling leaves the local DB byte-for-byte unchanged (verified by Drift table hash before and after).
- [ ] On the same flow but `hasSnapshot = false`, **no** dialog appears; the local customizations are pushed up and end up on the server within 30 seconds (verified by a follow-up `/v1/catalog` curl).
- [ ] The flag `customizationFirstSyncDone[userId]` is set on every terminal state of the service: `done`, `cancelledByUser`, **but not** on `error` (so an offline blip on first foreground retries on next foreground).
- [ ] In `error` state, the in-memory backoff limits retries to once per 5 minutes per app session — verified by a unit test that calls `restoreIfNeeded` 3 times in a row with a failing API stub and asserts only the first call hits the network.

### 4.2 Settings — *Restore checklist from your account*

- [ ] The tile is **hidden** when signed-out.
- [ ] The tile is **hidden** when signed-in but `emailConfirmedAt` is null.
- [ ] The tile is **visible** when signed-in + confirmed; subtitle reads *"Never restored on this device"* before the first restore and *"Last restored: <relative time>"* afterwards (relative formatting uses the existing `app_en.arb` / `app_ar.arb` helpers).
- [ ] Tapping the tile clears the flag and re-runs the service; if `hasSnapshot=true`, the confirmation dialog appears.
- [ ] If the tap occurs offline, an inline toast *"You're offline — restore will run when you're back online."* appears; the flag is **not** cleared until the user has re-confirmed online (so they don't accidentally lose state).

### 4.3 Manage screen — visibility vs. *Remove permanently*

- [ ] The leading `Switch` on every row has two distinct tooltips depending on state (verified by widget test):
  - Hidden: *"Show on today's list."*
  - Visible: *"Hide from today — keeps your history."*
- [ ] Toggling a default row off and on, repeatedly, never enqueues a `delete_user_task` or `delete_user_category` op (verified by inspecting `pending_sync_ops` after each toggle).
- [ ] The *Remove permanently* item is **absent** on every default row and **present** on every user-owned row.
- [ ] On a user-owned task with zero referencing logs, *Remove permanently* opens a soft-amber sheet; the confirm button is **soft amber, not red** (verified by a golden test or a colour assertion).
- [ ] On a user-owned task with ≥1 referencing log, the same overflow item opens a sheet whose body explains the history and offers only a **Hide** button.
- [ ] If the server returns 409 on a `Remove permanently` attempt (because logs exist server-side that the client didn't know about), the UI swaps to the *Hide instead* variant inline without throwing.

### 4.4 Sync queue interplay

- [ ] During the snapshot-wins restore: the customization-typed pending ops (`upsert_user_category`, `delete_user_category`, `upsert_user_category_override`, `upsert_user_task`, `delete_user_task`, `upsert_user_task_override`) are removed from `pending_sync_ops`; `batch_log` ops are **not** touched (verified by row count).
- [ ] After restore, any subsequent customization edit enqueues a normal Phase-7 op and drains within the next sync cycle (verified end-to-end on a real device).

### 4.5 Localization

- [ ] Every new visible string exists in **both** `app/l10n/app_en.arb` and `app/l10n/app_ar.arb`. Strings include (non-exhaustive): the restore dialog title + body + Restore + Cancel labels, the Settings tile title + subtitle (both variants), the *Remove permanently* menu item + sheet copy (both variants — destructive + history-protected), the visibility-switch tooltips, the *"Saved your checklist to your account."* toast, the *"Restored N items from your account."* toast.
- [ ] Arabic RTL pass: walk through the §1 scenario in Arabic on a real device or RTL emulator; layouts mirror correctly; the icon picker grid (Phase-7) stays LTR.

### 4.6 Tone (mission #1)

- [ ] No new visible string contains words from the blocklist:
  - English (`rg -i` against the **diff** of `app/l10n/app_en.arb`): *invalid, illegal, denied, forbidden, failure, error code, discard, lose*.
  - Arabic (`rg` against the diff of `app/l10n/app_ar.arb`): `خطأ`, `فشل`, `ممنوع`, `غير مسموح`, `غير صالح`, `محظور`.
- [ ] The restore confirmation body uses *"replace"* + *"keep"* (positive framing), never *"overwrite"* or *"delete"*.
- [ ] Every destructive button in this phase (the single *Remove permanently* confirm) uses soft amber; **no red buttons are introduced** (verified by a colour-token grep in `app/lib/features/customization/`).

---

## 5. Tests (must be green in CI)

- [ ] Backend: `npm run test` — all suites pass, including the new `catalog.service.spec.ts` cases.
- [ ] Backend: `npm run test:e2e` — covers §3.1 matrix and §3.2 consistency.
- [ ] Backend: `npm run lint` — 0 errors.
- [ ] Backend: `prisma migrate diff --from-migrations --to-schema-datamodel` — empty.
- [ ] Flutter: `flutter analyze` — 0 errors.
- [ ] Flutter: `flutter test` — all suites pass, including new tests for `CustomizationRestoreService`, the snapshot-state branch, the Manage screen overflow menu, and the Settings *Restore* tile.
- [ ] Flutter: `integration_test/first_sign_in_phase8_test.dart` — passes on both Android emulator and iOS simulator.
- [ ] Icon-parity script (`tools/check_icon_parity.dart`) — still exits zero.
- [ ] GitHub Actions CI on this branch is green end-to-end.

---

## 6. Security & data-integrity gates

- [ ] `GET /v1/catalog/snapshot-state` returns counts **only for `req.user.id`**; forging a body or query userId is impossible (no userId parameter is read from the request).
- [ ] No PII in any new server log line — verified by `rg` over the new code under `api/src/customization/`. Log lines may include user id and counts; they must **not** include task names, category names, or icon codes.
- [ ] On the snapshot branch, the local DB mutation is wrapped in **one Drift transaction** so an app crash mid-restore leaves the DB in either pre-restore or post-restore state — never partial. Verified by a fault-injection unit test that throws after step 3c and asserts the DB matches the pre-restore snapshot.
- [ ] On the no-snapshot branch, a network failure during outbound drain leaves the customization-typed ops in `pending_sync_ops` for the next cycle to pick up; nothing is silently dropped.
- [ ] The `customizationFirstSyncDone` flag is per-user (namespaced by `userId`) — verified by a unit test that signs out as user A and signs in as user B on the same device and confirms the gate runs again.

---

## 7. Documentation

- [ ] `README.md`: short paragraph on cross-device restore (sign-in only) and the unchanged visibility-toggle model.
- [ ] `api/README.md`: section describing the `snapshot-state` endpoint and the "zero schema changes" posture of this phase.
- [ ] `spec/roadmap.md`: Phase 8 ticked; any deferred items (continuous pull, cross-device user-owned-log sync) listed under Phase 9 prep.
- [ ] `spec/tech-stack.md`: confirm the Data Model section still matches what's built; no edits required unless a divergence is found.

---

## 8. Mergeability gate (final checklist)

Phase 8 is merged into `master` only when **all** of these are true:

- [ ] Every checkbox in §1, §2 (all sub-sections), §3, §4 (all sub-sections), §5, §6, §7 is ticked.
- [ ] Manual demo recorded (≥ 60s screen capture) showing: Device A customizes → Device B signs in → restore dialog → Restore tap → home checklist matches → Manage screen toggle a default off and on (seeded values return) → Settings *Restore checklist from your account* runs successfully.
- [ ] Two-device convergence verified once on real hardware (not only emulators) — at least one of the devices must be a real Android phone (the platform with the largest user base for this app).
- [ ] No secrets, no `.env` files, no real email passwords in the diff.
- [ ] A short *"What's deferred to Phase 9"* paragraph is added to the merge commit body (continuous pull, cross-device user-owned daily-log sync).
