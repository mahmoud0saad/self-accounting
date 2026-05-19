# Requirements — Phase 8: Tasks & Category Sync

**Phase:** 8 of the roadmap
**Branch:** `phase-8-2026-05-19-tasks-category-sync`
**Created:** 2026-05-19
**Status:** Spec — pre-implementation
**Estimated duration:** 4 days (per roadmap)

---

## 1. Context

After Phase 7 every user — anonymous or signed-in — can fully tailor their checklist locally:

- `UserCategory` / `UserCategoryOverride` / `UserTask` / `UserTaskOverride` rows live in both SQLite (Drift) and MySQL (Prisma).
- `GET /v1/catalog` returns the full per-user effective catalog payload.
- `PUT /v1/customizations/batch` accepts mixed-op batches drained from `pending_sync_ops`.
- `SyncService.runFirstSignInMigrationIfNeeded()` already handles **log** migration on first sign-in (`pullDeltas()` then enqueue + drain local logs) — but **it does nothing for customizations**.

The gap Phase 8 closes is the **restore path on sign-in across devices/reinstalls**. Today, if a user customizes their checklist on phone A, signs out, and signs in on phone B (or wipes and reinstalls on phone A), phone B sees the seeded defaults and the user has to recreate everything manually. The push side already replicates new edits to the server — what is missing is the **pull-down of an existing server snapshot when the local DB has no equivalent customization yet**.

This phase also tightens one Phase-7 UX detail that produced confusion in QA: the visibility toggle on the Manage screen used to read as "delete" to users when applied to user-owned items. Phase 8 makes it unambiguous: **toggle = deactivate (reversible, never removes the row)**; hard removal lives behind a separate, explicit *Remove permanently* affordance.

Mission constraints that shape every decision below:

- **#4 — Local-first.** Anonymous users still customize freely; sync is opt-in. The restore flow only runs *after* a successful sign-in + email confirmation.
- **#5 — Honest measurement.** Server data wins on restore when both sides have content — the account is the source of truth, not whatever was tinkered with on a fresh install before sign-in.
- **#1 — Niyyah-first.** The user is informed before any destructive restore step happens; no silent data loss without consent.

## 2. Goal (in one sentence)

When a confirmed user signs in, the app reconciles their customization catalog with the server in one direction at a time — push local up if the server is empty, otherwise pull server down and discard pending local customization edits — and from then on the Phase-7 push queue keeps the account in sync; on the Manage screen, hiding/showing a task or category never removes the row from the database, while a separate *Remove permanently* affordance keeps the existing hard-delete behavior for user-owned items with zero historical logs.

## 3. In Scope

### 3.1 Restore decision tree (server-snapshot-wins)

On the **first foreground after sign-in** of a confirmed account on a given device (tracked by `TokenStorage.isFirstSyncDone(userId)` — re-used from Phase 6), the client runs `CustomizationRestoreService.restore()`. The flow:

```
1. Ask the server: "Do you already have customizations for this account?"
2. If NO server snapshot:
     → push-up path: enqueue every local user-owned row + override row as an
       upsert op, then drain (existing Phase-7 outbound path).
     → equivalent to Phase 6/7 first-sign-in semantics, just extended to
       customizations.
3. If YES server snapshot:
     → pull-down path:
       a. Drop every customization-typed entry from `pending_sync_ops`
          (opTypes: upsert_user_category, delete_user_category,
                    upsert_user_category_override,
                    upsert_user_task, delete_user_task,
                    upsert_user_task_override).
          Log ops (`batch_log`) are NOT touched.
       b. Truncate local `user_categories`, `user_tasks`,
          `user_category_overrides`, `user_task_overrides`.
       c. Replay the server snapshot from `GET /v1/catalog` into those four
          tables (one transaction).
       d. Prune `daily_logs.userTaskId` rows whose target no longer exists.
          Logs against default-task codes are preserved.
4. Mark `customizationFirstSyncDone(userId) = true` (separate flag from
   the Phase-6 log flag, so a partial Phase-6 install can still run this
   pass exactly once when upgraded).
```

The user sees a single, calm dialog **before step 3** explaining: *"We found your saved checklist on this account. Restoring it will replace the customizations on this device — your daily progress is kept."* with **Restore** (primary) and **Cancel** (secondary). Cancel skips restore and marks the flag done; the user can still push manual edits and they will sync via the normal queue (effectively merging into the server snapshot under existing Phase-7 LWW).

### 3.2 Snapshot detection endpoint

To answer step 1 without downloading the full catalog twice, the API gets a small head endpoint:

- `GET /v1/catalog/snapshot-state` → `{ hasSnapshot: boolean, totals: { userCategories: int, userTasks: int, categoryOverrides: int, taskOverrides: int }, lastUpdatedAt?: ISO8601 }`
- `hasSnapshot = (userCategories + userTasks + categoryOverrides + taskOverrides) > 0` — anything more than zero customization rows for the user means we treat the server as authoritative on restore.
- Requires the same Phase-6 email-confirmed JWT guard.
- Returns 200 even for zero-row users (`hasSnapshot: false`) so the client can branch deterministically.

The same data could be inferred from `GET /v1/catalog`, but a head endpoint keeps cold-start cost low and the decision contract explicit. The full snapshot is fetched in step 3c via `GET /v1/catalog` (existing Phase-7 endpoint, unchanged).

### 3.3 Toggle vs. Remove permanently (Manage screen UX clarification)

From decision §4.2 (and confirming the roadmap line *"don't remove from db only deactivate and can active again when toggle"*), the Manage screen has **two clearly different controls**:

| Action | Default category / task | User-owned category / task |
|---|---|---|
| **Visibility toggle** (switch) | Upserts an override with `hidden=true` / `hidden=false`. Row stays in DB. Re-toggling restores. | Sets / clears `archivedAt`. Row stays in DB. Re-toggling restores. |
| **Remove permanently** (overflow menu → soft-amber sheet) | **Not offered** — defaults are global, only their overrides can be toggled. | Hard-deletes the row **only if** the row has zero referencing `DailyLog`s and zero user-tasks referencing it (for categories). Otherwise the sheet swaps to *"This category/task has history. Hide it instead."* (calls the visibility toggle). |

The visibility toggle is the *only* control surfaced for default rows. The Remove-permanently action only appears in the user-owned row's overflow menu, behind one confirmation that uses soft amber (no red), with the calm copy *"This removes the entry and cannot be undone. Your daily progress and history are not affected."*.

The underlying DB shape from Phase 7 is **not changed** — `hidden`, `archivedAt`, and the override/user-owned split all remain. The change is purely:
- UI affordances renamed and split into two unambiguous controls.
- Re-toggle path explicitly tested: hide → show on a default removes the override row (or sets `hidden=false`) and the home checklist reflects the seeded default again; archive → unarchive on a user-owned task clears `archivedAt` and the row reappears.
- *No* hard-delete is ever wired to the visibility toggle, even on the user-owned side (a Phase-7 corner case that QA flagged).

### 3.4 Continuous sync (out of scope, but worth naming)

Per decision §4.1, Phase 8 does **not** add foregrounded periodic pulls or live multi-device sync. The Phase-7 outbound queue continues to push edits from the local device to the server in chunks; the server is the cross-device source of truth, and the restore step in §3.1 is the only point at which the server overwrites the client. A subsequent phase can add periodic pull-down if real-device usage shows a need; the contract in §3.2 is forward-compatible (the same endpoint can drive a delta cursor later).

### 3.5 Backend changes (NestJS + Prisma + MySQL)

New / changed endpoints:

- **NEW** `GET /v1/catalog/snapshot-state` — described in §3.2. Added to `CatalogController` next to the existing `GET /v1/catalog`. Tagged `Customization` in OpenAPI.
- `GET /v1/catalog` — **unchanged** payload shape, but the response handler must guarantee deterministic ordering by `(id, code)` so a snapshot diff in QA is stable.
- `PUT /v1/customizations/batch` — **unchanged** wire format. One internal tightening: when applying an `upsert_*` op with `clientUpdatedAt` older than the server row's `updatedAt`, the response keeps the existing Phase-7 `STALE` outcome; Phase 8 just leans on this contract — no new behavior on the server.
- `DELETE /v1/user-tasks/:id` and `DELETE /v1/user-categories/:id` — **unchanged**; still the only paths for hard delete. Phase 8 wires the UI to call them only from the *Remove permanently* affordance.

No new Prisma schema columns. No migration.

### 3.6 Flutter client changes

#### 3.6.1 New service

`app/lib/features/sync/data/customization_restore_service.dart`

```dart
class CustomizationRestoreService {
  Future<void> restoreIfNeeded({ required Future<bool> Function() confirmReplacePrompt });
}
```

- Reads `TokenStorage.isCustomizationFirstSyncDone(userId)`; returns immediately if true.
- Calls `GET /v1/catalog/snapshot-state`.
- Branches per §3.1.
- When the snapshot branch is `yes`, awaits `confirmReplacePrompt()` (UI-provided) before touching local state. On `false`, the flag is still set so the user is not nagged on every foreground.
- Emits structured progress events for the Settings screen status row: `idle`, `checking`, `pushing`, `restoring`, `done(restoredCount)`, `cancelledByUser`, `error(message)`.

#### 3.6.2 SyncService integration

`SyncService.runFirstSignInMigrationIfNeeded()` is extended:

1. Pull log deltas (existing).
2. **NEW**: call `CustomizationRestoreService.restoreIfNeeded(...)`.
3. Enqueue local log ops + customization push ops (only on the no-snapshot branch — push-up path).
4. Drain outbound (existing).
5. Mark log + customization flags done.

The confirmation prompt is wired via Riverpod from the Settings screen overlay (or a Home-screen-level scaffold) so the service never imports Flutter widgets directly.

#### 3.6.3 Manage screen (split visibility vs. remove permanently)

`app/lib/features/customization/presentation/manage_checklist_screen.dart`:

- Replace the trailing trash icon (Phase 7) on user-owned rows with an overflow menu (`MoreVert`) holding two items:
  1. **Edit** — opens the existing editor sheet.
  2. **Remove permanently** — soft-amber confirm sheet, only enabled when the safety check (zero logs / zero referencing user-tasks) passes; otherwise the sheet body explains why and offers the *Hide* action instead, closing on tap.
- The leading visibility `Switch` stays exactly where it is on every row (default and user-owned). Its semantics are clarified in tooltips: *"Hide from today — keeps your history."* / *"Show on today's list."*.
- No new routes; both editors and sheets reuse existing Phase-7 components.

#### 3.6.4 Settings screen: "Restore from cloud" affordance

A new `ListTile` in Settings, visible only when signed in + email confirmed:

- **Label:** *"Restore checklist from your account"*.
- **State row:** *"Last restored: <relative date>"* or *"Never restored on this device"*.
- **On tap:** calls `CustomizationRestoreService.restoreIfNeeded(force: true)` — the `force` parameter bypasses the `customizationFirstSyncDone` flag so the user can re-pull at will. Same confirmation prompt as the automatic flow.

This is the manual escape hatch for the *"I tapped Cancel by mistake on first sign-in"* case.

#### 3.6.5 i18n

Every new visible string in **both**:

- `app/l10n/app_en.arb`
- `app/l10n/app_ar.arb`

Including: the restore confirmation title + body, the *"We found your saved checklist…"* copy, the visibility-toggle tooltip variants, the *Remove permanently* menu label + confirm body, the *"This category/task has history. Hide it instead."* fallback, the Settings *Restore* tile, and every state-row variant.

### 3.7 `TokenStorage` extension

`app/lib/features/auth/data/token_storage.dart`:

- `Future<bool> isCustomizationFirstSyncDone(String userId)`.
- `Future<void> markCustomizationFirstSyncDone(String userId)`.
- `Future<void> clearCustomizationFirstSyncFlag(String userId)` — invoked by the *Restore from cloud* manual action so the next foreground re-runs the gate.

Stored alongside the existing log-side flag (same secure storage; namespaced key).

## 4. Decisions (from clarification questions, 2026-05-19)

### 4.1 Pull trigger — **Sign-in only (one-shot restore)**

The restore pass runs once per device per signed-in account (gated by `customizationFirstSyncDone`). No periodic foreground pulls; no live multi-device convergence. Push-up edits keep the server in sync between devices, and a future phase can layer continuous pull on top of the snapshot-state endpoint without breaking this contract.

Implications:
- Multi-device users see edits from device A on device B only after **either** an explicit *Restore from cloud* tap **or** a reinstall / sign-out + sign-in cycle on B. This is documented under §6 (out-of-scope-but-named) so future bug reports get triaged against the intended behavior.
- The `snapshot-state` endpoint is intentionally tiny and cheap — it's only hit on the sign-in foreground and the manual restore tap.

### 4.2 Toggle vs. delete — **Keep the Phase-7 model; split the UI into two controls**

The toggle (default override or `archivedAt`) keeps the row in the DB; *Remove permanently* is a separate, explicit affordance for user-owned items with zero referencing logs (Phase-7's hard-delete path, kept intact).

Implications:
- Zero schema churn — existing migrations stand.
- The Phase-7 batch endpoint, sync ops, and LWW are unchanged.
- The work is concentrated in the Flutter Manage screen, the new restore service, and copy.

### 4.3 Conflict resolution on restore — **Server-snapshot-wins (only when a server snapshot exists)**

If the server has zero customization rows for the user, we push local up. If it has any, we discard local pending customization edits and the local user-owned customization rows, then replay the server snapshot. The user must explicitly **Restore** in the confirmation prompt before any local state is touched on the snapshot-wins branch.

Implications:
- No field-level LWW on restore — restore is a *transactional snapshot replay*, not a merge. Cleaner semantics, easier to reason about, easier to test.
- Local-only daily logs against vanished user-owned tasks are pruned (their `userTaskId` no longer resolves). Logs against default task codes survive untouched, so the user's day-by-day completion history on default rows is preserved end-to-end. This is the calm-copy promise *"Your daily progress is kept."* — true for every default-keyed log and for every user-owned log whose target survives the restore.
- The Phase-7 LWW path inside `PUT /v1/customizations/batch` is unaffected; it still arbitrates *push* conflicts (e.g., a future continuous-sync world), and it is the contract the no-snapshot branch relies on when flushing the queue.

## 5. Non-Goals (this phase)

- **Periodic / continuous pull** of server changes after sign-in — see §3.4. The push queue alone keeps the account current from this device's perspective.
- **Real-time multi-device sync** (WebSockets, push notifications carrying deltas, etc.).
- **Field-level merge / three-way diff** on restore — restore is whole-snapshot replay.
- **Cross-device daily-log migration of user-owned tasks** — logs against default task codes already sync via Phase 6's log path; logs against user-owned tasks remain local-only in Phase 8 (their cross-device behavior is a backlog item once real users ask).
- **Server-side audit log** of which device performed which restore (privacy principle #6).
- **Bulk re-keying of orphaned daily logs** to plausibly-matching server tasks on restore (string-similarity matching, etc.) — too magical, deferred to a backlog ticket.
- **Schema changes on the Prisma or Drift side** — Phase 8 deliberately ships zero migrations.

## 6. Out-of-Scope but Documented for Later

- **Continuous pull / live multi-device sync** — Phase 8 + 1 candidate. The `snapshot-state` endpoint can grow a `since` cursor and a delta payload without breaking existing callers.
- **Cross-device daily-log sync of user-owned task completions** — relies on stable user-owned task ids surviving the snapshot replay, which Phase 8's restore explicitly does not guarantee on first-restore. A follow-up can add a deterministic `(userId, code)` shape to user-owned tasks so logs become cross-device.
- **Manual export / re-import** of a customization snapshot to local file — backlog.
- **Conflict resolution UI** for a future field-level merge mode — backlog.

## 7. Constraints & Cross-Cutting Concerns

- **Offline-first** (mission #4): the restore service no-ops gracefully when offline; the first online foreground after sign-in is the trigger.
- **Niyyah-first tone** (mission #1): the snapshot-wins confirmation never uses words from the Phase-7 tone blocklist (no *"failure"*, no *"error"*, no *"discard"* — prefer *"replace"* + *"keep"*).
- **Calm palette** (mission #2): the *Remove permanently* sheet uses soft amber; the restore confirmation uses the default soft-green primary for the **Restore** button.
- **Privacy** (mission #6): no analytics on which restore branch was taken, no PII in any new server log line. The `snapshot-state` response carries only counts and a timestamp — no names, no icons, no point values.
- **Versioned API**: all routes under `/v1`.
- **Backward compatibility**: a client built against Phase 7 must keep working — the new `snapshot-state` endpoint is purely additive; the Manage UI split is a UI-only change; no DTO or schema breaks.

## 8. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| User taps *Cancel* on the restore confirmation by accident and assumes their cloud data is lost | Medium | Settings → *Restore checklist from your account* tile is always reachable; `force=true` re-runs the gate. Confirmation copy never implies destruction of server data. |
| Pruning orphaned daily logs surprises a user who customized while anonymous, then signed into a different account | Low-Medium | Confirmation copy is explicit: *"Restoring will replace this device's customizations."* Daily progress on default tasks is preserved; the only loss is logs against vanished user-owned tasks, which the user is consciously discarding. |
| `snapshot-state` endpoint count drifts from the actual `/v1/catalog` payload (e.g., due to a soft-delete being counted differently) | Medium | One service method backs both endpoints; an integration test snapshots both and asserts `hasSnapshot = (counts > 0)` and `(counts) === (lengths from /v1/catalog)`. |
| Restore runs on every foreground because the flag isn't being set on success | Medium | Wrap the entire restore branch in a `try / finally` that always sets the flag on `done` or `cancelledByUser`. Error path keeps the flag false but is rate-limited with an in-memory backoff (no more than once per 5 minutes per app session). |
| User-owned `daily_log` rows referencing vanished `userTaskId`s linger after a restore and corrupt the dashboard | Medium | The restore transaction explicitly deletes those rows in step 3d; a follow-up startup sanity check (`drift` migration step) also prunes orphans on every cold start. |
| Two-device race: device A pushes a new task while device B is restoring | Low | Restore reads `/v1/catalog` once; any push from A after that read is the next push-up sync from A. Eventually consistent. Documented under §3.4. |
| Manage screen *Remove permanently* hits an item with logs because the local-side guard is stale | Low | The control queries the live `daily_logs` count via the existing repo; server-side `DELETE` is still the source of truth (returns 409 if logs exist) and the UI surfaces that response as the *Hide instead* fallback. |

## 9. Dependencies

- Phase 7 must be merged. ✅ (verify on branch creation: `git log master -- specs/phase-7-2026-05-19-task-customization`).
- Phase 7 `GET /v1/catalog` + `PUT /v1/customizations/batch` + `pending_sync_ops` schema + `CatalogRepository`.
- Phase 6 `TokenStorage`, `SyncService.runFirstSignInMigrationIfNeeded`, email-confirmed JWT guard.
- Phase 5 nothing (no notification interplay).
- Phase 4 dashboard providers re-derive from `EffectiveCatalog` (Phase 7), so they automatically reflect a snapshot replay — no edits needed here.

## 10. References

- `spec/roadmap.md` — Phase 8 entry (the three goal bullets).
- `spec/mission.md` — principles #1, #2, #4, #5, #6.
- `spec/tech-stack.md` — Data Model section (no edits required this phase).
- `specs/phase-6-2026-05-18-backend-optional-sync/requirements.md` — first-sign-in migration contract this phase extends.
- `specs/phase-7-2026-05-19-task-customization/requirements.md` — customization model + sync queue + `/v1/catalog` shape this phase pulls from.
