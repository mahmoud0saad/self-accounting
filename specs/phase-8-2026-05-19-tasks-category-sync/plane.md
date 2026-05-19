# Plan — Phase 8: Tasks & Category Sync

A series of **numbered task groups**, ordered so each group leaves the repo in a working, demoable state. Tick boxes as you complete them. Each group should be one PR (or one well-titled commit on this branch).

> Branch: `phase-8-2026-05-19-tasks-category-sync`
> Companion docs: `requirements.md`, `validation.md`

---

## Group 1 — Backend: snapshot-state endpoint

**Goal:** A tiny, cheap head endpoint the client can hit to decide push-up vs. pull-down.

1.1. Add `GET /v1/catalog/snapshot-state` to `api/src/customization/catalog.controller.ts`:
- Reuses `JwtAuthGuard` + `EmailConfirmedGuard` (Phase 6).
- Calls a new `CatalogService.getSnapshotState(userId)` method.

1.2. Implement `CatalogService.getSnapshotState(userId)`:
- Single Prisma transaction running four `count` queries in parallel: `userCategories`, `userTasks`, `userCategoryOverrides`, `userTaskOverrides`. All four are filtered by `userId`; `archivedAt` is **not** filtered out (an archived row still counts as a snapshot).
- Compute `lastUpdatedAt = max(updatedAt)` across all four tables (omit if all empty).
- Return: `{ hasSnapshot: totalCount > 0, totals: { userCategories, userTasks, categoryOverrides, taskOverrides }, lastUpdatedAt? }`.

1.3. Add OpenAPI annotations: response DTO `SnapshotStateDto` with example values; group under the existing `Customization` tag; mark as `200` + `401` + `403` (consistent with the rest of the customization surface).

1.4. Backend unit tests (`api/test/customization/catalog.service.spec.ts`):
- Zero-row user → `{ hasSnapshot: false, totals: { 0, 0, 0, 0 } }`, no `lastUpdatedAt`.
- One user-owned category + one override → `hasSnapshot: true`, totals match, `lastUpdatedAt = max(updatedAt)`.
- Archived user task still counts (`hasSnapshot: true`).

1.5. Backend e2e tests (`api/test/customization/snapshot-state.e2e.spec.ts`):
- Anonymous (no JWT) → 401.
- Authed unconfirmed → 403.
- Authed confirmed empty → 200 + `hasSnapshot: false`.
- Authed confirmed populated → 200 + counts mirror `/v1/catalog` array lengths exactly.

**Exit:** `curl -H "Authorization: Bearer <jwt>" /v1/catalog/snapshot-state` returns the expected payload for empty, populated, and archived-only users. CI green.

---

## Group 2 — Client storage: customization-first-sync flag

**Goal:** Persistent, per-user flag that gates the restore pass.

2.1. Extend `app/lib/features/auth/data/token_storage.dart` with three async methods:
- `Future<bool> isCustomizationFirstSyncDone(String userId)`.
- `Future<void> markCustomizationFirstSyncDone(String userId)`.
- `Future<void> clearCustomizationFirstSyncFlag(String userId)`.

Key namespace: `customization_first_sync_done:<userId>` to avoid collision with the Phase-6 log flag.

2.2. Unit test in `app/test/features/auth/token_storage_test.dart`: round-trip set/get/clear; different users isolated; clear leaves the log-side Phase-6 flag intact.

**Exit:** Tests green; no behavior change yet (the flag is only read by code shipped in Group 3).

---

## Group 3 — Client: `CustomizationRestoreService` (skeleton + push-up branch)

**Goal:** Ship the no-snapshot branch end-to-end and the service shell.

3.1. New file `app/lib/features/sync/data/customization_restore_service.dart` with:

```dart
enum CustomizationRestoreState {
  idle, checking, pushing, restoring, done, cancelledByUser, error,
}

class CustomizationRestoreEvent {
  final CustomizationRestoreState state;
  final int restoredCount;
  final String? message;
}

class CustomizationRestoreService {
  Future<void> restoreIfNeeded({
    bool force = false,
    required Future<bool> Function(int totals) confirmReplacePrompt,
  });
  Stream<CustomizationRestoreEvent> events;
}
```

3.2. Implement the `force=false` + zero-snapshot path:
- If flag is set and `force=false` → `events.add(idle)` and return.
- Hit `GET /v1/catalog/snapshot-state`.
- If `hasSnapshot=false`:
  - `events.add(pushing)`.
  - Read every local `user_categories`, `user_tasks`, `user_category_overrides`, `user_task_overrides` row via `CatalogRepository` (Phase 7).
  - For each row, enqueue the corresponding customization op (`upsert_user_category`, `upsert_user_task`, etc.) into `pending_sync_ops` via `SyncService.enqueueCustomizationOp(...)` (already exists from Phase 7, including coalescing).
  - Call `SyncService.drainOutbound()` (Phase 6 / Phase 7).
  - On success: `events.add(done(restoredCount: <ops enqueued>))`, mark flag done.
  - On failure: keep flag false, `events.add(error(message))`.

3.3. Riverpod provider in the same file:

```dart
final customizationRestoreServiceProvider =
    Provider<CustomizationRestoreService>((ref) => CustomizationRestoreService(
      db: ref.watch(appDatabaseProvider),
      api: ref.watch(syncApiProvider),
      storage: ref.read(tokenStorageProvider),
      ref: ref,
    ));
```

3.4. Tests (`app/test/features/sync/customization_restore_service_test.dart`):
- Fake `SyncApi` returning `hasSnapshot=false`; pre-populate the local DB with 1 user category + 2 user tasks; call `restoreIfNeeded(...)`; assert four ops landed in `pending_sync_ops`, then assert `drainOutbound` was called and the flag was set.
- Repeat call with flag set → service no-ops (`idle` event emitted, no API hit).

**Exit:** New device, fresh sign-in, empty server → all local customizations land on the server via the standard outbound queue. No UI yet.

---

## Group 4 — Client: snapshot-wins restore branch (the destructive one)

**Goal:** Implement step 3 of the §3.1 decision tree behind a UI confirmation hook.

4.1. Extend `CustomizationRestoreService.restoreIfNeeded(...)`:
- If `hasSnapshot=true`:
  - `events.add(checking)`.
  - Await `confirmReplacePrompt(totals)` — if `false`, mark flag done, `events.add(cancelledByUser)`, return.
  - `events.add(restoring)`.
  - In one Drift transaction:
    1. Delete every row in `pending_sync_ops` whose `opType` is in the customization opType set (constant `kCustomizationOpTypes`).
    2. Delete all rows in `user_categories`, `user_tasks`, `user_category_overrides`, `user_task_overrides`.
    3. `GET /v1/catalog` → repopulate the four tables. Server ids and timestamps are preserved.
    4. Delete every `daily_logs` row whose `userTaskId IS NOT NULL` and does not match a now-existing `user_tasks.id` (orphan-prune; logs with `userTaskId IS NULL` against default task codes are kept).
  - Mark flag done, `events.add(done(restoredCount: <sum of all four arrays>))`.

4.2. Define `kCustomizationOpTypes = const { 'upsert_user_category', 'delete_user_category', 'upsert_user_category_override', 'upsert_user_task', 'delete_user_task', 'upsert_user_task_override' }` in a shared constants file under `app/lib/features/sync/`.

4.3. Tests (`app/test/features/sync/customization_restore_service_test.dart`):
- Server returns 2 categories + 5 tasks + 3 overrides; local DB starts with 1 different user category + a `pending_sync_ops` row of type `upsert_user_task` + a `daily_logs` row whose `userTaskId` points at the local-only task.
- After `restoreIfNeeded(...)` with `confirmReplacePrompt → true`: the four customization tables match the server exactly; the customization-typed pending op is gone; the orphan log is gone; one `pending_sync_ops` row of type `batch_log` (added beforehand) survives untouched.
- Repeat with `confirmReplacePrompt → false`: nothing is touched, flag is set, `cancelledByUser` is emitted.

**Exit:** Two-device demo: device A creates a custom category + 3 tasks, signs out. Device B (different account state) signs in → confirmation dialog appears → tapping Restore replaces local data with device A's snapshot.

---

## Group 5 — Client: hook into `SyncService.runFirstSignInMigrationIfNeeded`

**Goal:** Make the restore service run automatically on first sign-in.

5.1. In `app/lib/features/sync/data/sync_service.dart`:
- After the existing `pullDeltas()` call inside `runFirstSignInMigrationIfNeeded()`, await `CustomizationRestoreService.restoreIfNeeded(confirmReplacePrompt: ...)`.
- The `confirmReplacePrompt` is wired from the calling layer (Home or Settings) via a `Ref.read` of a UI-facing `customizationRestorePromptProvider` (an `AsyncValue<bool> Function(int totals)`). Default implementation returns `true` only after the user taps the confirmation dialog button.

5.2. Update the post-sign-in / post-confirmation toast logic to surface the restore service events:
- *Checking your saved checklist…*
- *Restoring your saved checklist…*
- *Restored N items from your account.* (snapshot branch)
- *Saved your checklist to your account.* (push-up branch)
- *Restore cancelled — you can do it later from Settings.*

5.3. Tests (integration, `app/integration_test/first_sign_in_phase8_test.dart`):
- Snapshot branch end-to-end: stub server with a populated catalog, fresh client, sign in (already confirmed), tap Restore on the dialog, assert the home checklist now matches the server.
- Push-up branch: stub server with an empty catalog, fresh client with locally-created custom items, sign in, no dialog appears, items land on the server, home checklist unchanged.

**Exit:** Manual test on emulator: sign-in flow shows the right dialog with the right copy in both branches; flag prevents re-prompt on second foreground.

---

## Group 6 — Client: Manage screen — split visibility vs. *Remove permanently*

**Goal:** Settle the Phase-7 UX ambiguity that triggered Phase 8's third roadmap bullet.

6.1. Refactor `app/lib/features/customization/presentation/manage_checklist_screen.dart`:
- Each user-owned row: keep the leading `Switch` (visibility toggle), keep the trailing chevron for *Edit*, and **add** a trailing `PopupMenuButton` with items `Edit` and `Remove permanently`.
- Each default row: leading `Switch` only; trailing `IconButton` opens the editor sheet (for override). **No** *Remove permanently* affordance.

6.2. Implement the *Remove permanently* sheet (`app/lib/features/customization/presentation/widgets/remove_permanently_sheet.dart`):
- Pre-flight check: query the local `daily_logs` count for the target and (for categories) count of user-tasks pointing at it. If non-zero, the sheet body shows *"This category/task has history. Hide it instead."* and a single *Hide* button that calls the existing visibility toggle path.
- Otherwise: soft-amber confirm with *Remove permanently* + *Cancel*. On confirm, call the existing Phase-7 `CatalogRepository.deleteUserTask({force: ...})` / `deleteUserCategory({force: ...})` path. If the server returns 409 (logs exist server-side after a recent sync), fall back to the Hide variant inline.

6.3. Update tooltips on the visibility `Switch`:
- Hidden state: *"Show on today's list."*
- Visible state: *"Hide from today — keeps your history."*

6.4. Widget tests (`app/test/features/customization/manage_checklist_screen_test.dart`):
- Default row: no *Remove permanently* item in the overflow menu.
- User-owned row with zero logs: *Remove permanently* enabled; confirm sheet appears; tapping confirm deletes locally.
- User-owned row with logs: *Remove permanently* shows the *Hide instead* body, no destructive button.
- Toggle a default row hidden then visible → no override row remains (or `hidden=false` row remains; either is acceptable by Phase 7); the home checklist re-shows the default with default values.

**Exit:** QA can reproduce the Phase-7 "toggle off ≠ delete" promise without surprise. Recording: toggle a default off → toggle it on → seeded values return.

---

## Group 7 — Client: Settings — *Restore checklist from your account*

**Goal:** Manual escape hatch + status visibility.

7.1. In `app/lib/features/settings/presentation/settings_screen.dart`, add a `ListTile` (signed-in + email-confirmed only):
- Title: *Restore checklist from your account*.
- Subtitle: *Last restored: <X days ago>* or *Never restored on this device*.
- Trailing: chevron.
- On tap: clear the customization-first-sync flag (`TokenStorage.clearCustomizationFirstSyncFlag(userId)`), then call `CustomizationRestoreService.restoreIfNeeded(force: true, ...)`.

7.2. Last-restored timestamp is read from a small Drift table `app_settings` (already exists from Phase 5/6) with key `customization_last_restored_at`. The restore service writes it on every successful `done` (both branches).

7.3. i18n: add the new strings to `app/l10n/app_en.arb` and `app/l10n/app_ar.arb`.

7.4. Widget test: the tile is hidden when signed-out; visible + correctly-labeled when signed-in; tapping it runs the service.

**Exit:** Power user can re-pull at will. Subtitle reflects reality.

---

## Group 8 — Forward compatibility for `snapshot-state` + delta cursor

**Goal:** Make the new endpoint future-proof without adding behavior.

8.1. Document — as a one-line OpenAPI description in `CatalogController` — that `snapshot-state` is allowed to grow a `since` query param later (returning a delta payload) without breaking existing callers.

8.2. In `CustomizationRestoreService`, read `lastUpdatedAt` from the response and write it to `app_settings.customization_server_last_seen_at` on every `checking` event — so a future delta-pull phase has a cursor already in place.

8.3. No new tests required; this is documentation-grade scaffolding.

**Exit:** A reviewer can read `snapshot-state` + the saved cursor and immediately see the path to continuous pull.

---

## Group 9 — Hardening, polish, and i18n parity

**Goal:** Make Phase 8 mergeable.

9.1. Run the Phase-7 icon parity script (`tools/check_icon_parity.dart`) — Phase 8 doesn't add icons but must not break the check.

9.2. RTL pass: switch device to Arabic, walk through:
- Sign-in on a populated account → restore dialog.
- Tap Cancel → land on home.
- Settings → *Restore checklist from your account* → dialog again.
- Manage screen → toggle a default off and on → both tooltip variants render RTL.
- Manage screen → *Remove permanently* sheet on a user-owned task with no logs.

9.3. Tone audit (mission #1) on every new visible string — `app_en.arb` and `app_ar.arb` — using the Phase-7 blocklists:
- English: *invalid, illegal, denied, forbidden, failure, error code, discard, lose*.
- Arabic: `خطأ، فشل، ممنوع، غير مسموح، غير صالح، محظور`.

9.4. Update `api/README.md`: one paragraph on the new `snapshot-state` endpoint and the no-schema-change posture of this phase.

9.5. Update root `README.md`: one short paragraph linking the cross-device restore story.

9.6. Update `spec/roadmap.md`: tick Phase 8; promote any deferred items (continuous pull, cross-device user-owned-log sync) to a *"Phase 9 prep"* note.

9.7. Manual QA against every checkbox in `validation.md`; record a ≤ 90-second demo of:
- New device sign-in → server has snapshot → Restore → home checklist matches.
- Same device → Settings → *Restore checklist from your account* → second restore cycle.
- Manage screen → toggle a default off and on → seeded values return.
- Manage screen → *Remove permanently* on a user-owned task with no logs.

**Exit:** Every checkbox in `validation.md` ticked; branch ready to merge.

---

## Group 10 — Demo & merge prep

**Goal:** Ship.

10.1. Author the merge-commit body summary: one paragraph on the restore decision tree, one on the UI split (toggle vs. *Remove permanently*), one *"What's deferred"* listing continuous pull and cross-device user-owned-log sync.

10.2. Confirm CI is green on the branch (`api/test`, `api/test:e2e`, `flutter analyze`, `flutter test`, icon-parity).

10.3. Open a PR titled `Phase 8 — Tasks & Category Sync` referencing this plan and `validation.md`.

**Exit:** PR opened, demo attached, all gates green.
