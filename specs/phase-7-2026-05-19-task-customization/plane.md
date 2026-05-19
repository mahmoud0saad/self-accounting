# Plan — Phase 7: Task Customization

A series of **numbered task groups**, ordered so each group leaves the repo in a working, demoable state. Tick boxes as you complete them. Each group should be one PR (or one well-titled commit on this branch).

> Branch: `phase-7-2026-05-19-task-customization`
> Companion docs: `requirements.md`, `validation.md`

---

## Group 1 — Domain model & curated icon allowlist

**Goal:** Lock the shapes before anything is wired.

1.1. Add `api/src/tasks/icons.constants.ts` exporting `CURATED_ICONS: readonly string[]` — the ~40 Material Symbols codes from `requirements.md` §3.5.
1.2. Add `app/lib/core/icons/curated_icons.dart` mirroring the same list (top-level `const List<String> kCuratedIcons`).
1.3. Add `app/lib/features/customization/domain/effective_catalog.dart` — pure function `EffectiveCatalog effectiveCatalog({ required List<Category> defaults, required List<UserCategory> userCategories, required List<UserCategoryOverride> categoryOverrides, required List<Task> defaultTasks, required List<UserTask> userTasks, required List<UserTaskOverride> taskOverrides })`. No dependencies on Drift or Riverpod — pure data in / data out.
1.4. Property tests in `app/test/features/customization/effective_catalog_test.dart` (≥ 30 cases) covering: override on hidden default; override on user-owned (must throw — not allowed); deletion of user category with referencing user tasks; reordering with mixed default + user-owned categories; fard-prayer category code allowlist.
1.5. CI parity check: `tools/check_icon_parity.dart` (or simple Node script in `api/scripts/`) that reads both files and exits non-zero if the sets diverge. Wire into `.github/workflows/`.

**Exit:** Pure-function tests green; CI parity check runs locally.

---

## Group 2 — Prisma schema & migration

**Goal:** Persistence shape on the backend.

2.1. Extend `api/prisma/schema.prisma`:
- `Category` { id, code (unique), defaultName, defaultIcon, defaultSortOrder, isFard (Boolean, default false), createdAt }
- Backfill default categories in the existing seed; mark the five fard-prayer rows `isFard = true`.
- `UserCategory` { id, userId, name, icon, sortOrder, archivedAt?, updatedAt }; index `(userId, archivedAt)`.
- `UserCategoryOverride` { id, userId, categoryCode (FK by code), hidden (default false), customName?, customIcon?, sortOrder?, updatedAt }; unique `(userId, categoryCode)`.
- Update existing `Task` model: add `categoryCode` (FK), `defaultIcon`, ensure `defaultPoints ∈ [1, 20]` documented in comments (DB constraint at app layer, not schema).
- `UserTask` { id, userId, categoryRef (string — either `category:<code>` or `userCategory:<id>`), name, points, icon, sortOrder, archivedAt?, updatedAt }; index `(userId, archivedAt)`.
- `UserTaskOverride` { id, userId, taskCode (FK by code), hidden (default false), customName?, customPoints?, customIcon?, customCategoryRef?, sortOrder?, updatedAt }; unique `(userId, taskCode)`.

2.2. Generate migration `phase7_customization`.
2.3. Update `api/prisma/seed.ts` to backfill `Category` rows derived from the Phase 1 hard-coded catalog; relink each existing `Task.code` to the right `categoryCode`.
2.4. Verify: `prisma migrate dev` is idempotent on a clean DB and on a Phase-6 DB.

**Exit:** Migration applies on top of a Phase-6 database without data loss; `prisma db seed` is idempotent.

---

## Group 3 — Backend: catalog read endpoint

**Goal:** One canonical read path for the client.

3.1. New `CatalogModule` with `GET /v1/catalog` returning the six arrays defined in `requirements.md` §3.6.
3.2. Mark `GET /v1/tasks` `@ApiDeprecated()` in OpenAPI; keep behavior unchanged for back-compat.
3.3. Add an integration test: a freshly registered user with no overrides receives the seeded defaults and **empty** user-* arrays.
3.4. Add a test where a user has one of each (one custom category, one custom task, one override of each kind) and the payload is correct.

**Exit:** `GET /v1/catalog` returns deterministic JSON for any user state; OpenAPI shows it under `/v1/docs`.

---

## Group 4 — Backend: customization write endpoints

**Goal:** All mutation paths land.

4.1. `UserCategoriesController`:
- `POST /v1/user-categories` (name, icon, sortOrder?).
- `PATCH /v1/user-categories/:id`.
- `DELETE /v1/user-categories/:id` — 409 if referencing user tasks exist and `?force=false`; `?force=true` reassigns those tasks to `category:misc`.

4.2. `UserCategoryOverridesController`:
- `PUT /v1/user-category-overrides/:categoryCode` — body is the full override; deletes the row when payload is all-defaults.
- Reject `hidden=true` for fard categories with `422 FARD_CATEGORY_LOCKED`.
- Reject `customName` for fard categories.

4.3. `UserTasksController`:
- `POST /v1/user-tasks` (name, categoryRef, points, icon).
- `PATCH /v1/user-tasks/:id`.
- `DELETE /v1/user-tasks/:id` — 409 if `DailyLog` rows reference it and `?archive=false`; `?archive=true` sets `archivedAt`.

4.4. `UserTaskOverridesController`:
- `PUT /v1/user-task-overrides/:taskCode` — analogous to category overrides; fard-prayer task codes accept `hidden=true` but the response includes `warning: "FARD_TASK_HIDDEN"` so the client can show the calm note client-side.

4.5. Validation: import `CURATED_ICONS` from Group 1; class-validator decorators for `points ∈ [1, 20]`, name length, icon membership.
4.6. Per-user limits (configurable via env): `MAX_USER_CATEGORIES=10`, `MAX_USER_TASKS=30`; 422 with `code: LIMIT_EXCEEDED` when breached.

**Exit:** Postman / httpie walkthrough creates a custom category, two tasks under it, hides a default, edits a default's points, then deletes the user category with `?force=true` — all green.

---

## Group 5 — Backend: batch endpoint for sync

**Goal:** Single transactional sync surface.

5.1. `PUT /v1/customizations/batch` accepts up to 200 ops, each `{ opId, opType, payload, clientUpdatedAt }`.
5.2. Apply each op inside a single transaction; collect per-op outcome `{ opId, applied, serverUpdatedAt, error? }`.
5.3. LWW rule: each op compares its `clientUpdatedAt` against the existing row's `updatedAt`; older `clientUpdatedAt` ⇒ `applied: false, error: "STALE"`.
5.4. Test matrix: each `opType` × {new row, newer client, older client, fard violation, limit-exceeded, unknown default code}.

**Exit:** Property tests show ordering of ops within a batch doesn't matter for the final state; convergent across replays.

---

## Group 6 — Flutter: Drift schema & repositories

**Goal:** Local persistence mirrors the server shape.

6.1. New Drift tables in `app/lib/core/db/tables/`:
- `categories_table.dart` (mirrors seeded defaults; populated by initializer on first launch).
- `user_categories_table.dart`.
- `user_category_overrides_table.dart`.
- `user_tasks_table.dart`.
- `user_task_overrides_table.dart`.

6.2. Bump `AppDatabase.schemaVersion`; write a migration step that:
- Seeds the new `categories` table from the existing Phase-1 hard-coded list.
- Re-keys existing `tasks.categoryCode` to point at the seeded categories.
- Leaves `daily_logs` untouched.

6.3. New `CatalogRepository`:
- `Stream<EffectiveCatalog> watch()` — joins all local tables and pipes them through the pure `effectiveCatalog(...)` function from Group 1.
- Mutation methods: `createUserCategory`, `updateUserCategory`, `deleteUserCategory({force})`, `upsertUserCategoryOverride`, and the four task-side analogues.
- Every mutation **also** enqueues an entry in `pending_sync_ops` (extended in Group 7).

6.4. Tests in `app/test/features/customization/catalog_repository_test.dart`.

**Exit:** Local-only widget test: spin up an in-memory DB, run all six mutation paths, watch the stream emit the expected effective catalog at each step.

---

## Group 7 — Flutter: sync queue extension

**Goal:** Customization ops drain like log ops.

7.1. Extend the `pending_sync_ops` payload schema (added in Phase 6) to support new `opType`s listed in `requirements.md` §3.7.
7.2. Coalescing: when enqueueing an op, if a pending op exists with the same `(opType, entityId)` and `applied=false`, replace its payload with the new one and bump `clientUpdatedAt` — avoids queue blow-up during rapid edits.
7.3. `SyncService.drainOutbound()` picks the right endpoint per `opType`; customization ops post to `/v1/customizations/batch` in chunks of 100.
7.4. Extend `FirstSignInMigrationService` to also flush customization ops in its single full-history pass.
7.5. Tests: simulate offline → 5 rapid edits to the same custom task → reconnect → exactly one batch op is sent.

**Exit:** Convergence: two devices with overlapping customization edits resolve to the same effective catalog after one foreground cycle.

---

## Group 8 — Flutter: "Manage checklist" screen + editors

**Goal:** The actual user-facing surface.

8.1. Routes in `app/lib/core/routing/app_router.dart`:
- `/manage` — tabbed screen.
- `/manage/categories/new`, `/manage/categories/:id/edit`.
- `/manage/tasks/new`, `/manage/tasks/:id/edit`.

8.2. `manage_checklist_screen.dart` with two tabs:
- **Categories** — list with drag-handles (reorder triggers a single sortOrder update batch), visibility toggle, edit affordance, "Add category" FAB. Fard categories have a small pinned-lock icon and a disabled toggle with a long-press tooltip explaining why.
- **Tasks** — grouped by effective category, with `+ Add task` per group, visibility toggle inline, edit affordance, soft-amber delete (with archive fallback).

8.3. `CategoryEditorSheet` — bottom sheet form with name (required, validated 2–60 chars), curated icon picker (grid of 8 columns), and an explainer line for fard categories. Save uses `CatalogRepository`.

8.4. `TaskEditorSheet` — name, category dropdown (excludes hidden ones, fard categories highlighted with their pinned icon for clarity), points slider (1–20 integer, snaps; soft-green track and thumb), icon picker. Save validates client-side first, then writes via repository.

8.5. Wire entry points:
- Settings screen → new ListTile *"Manage checklist"*.
- Home screen AppBar overflow menu → *"Manage checklist"* item.

8.6. ARB additions in `app/l10n/app_en.arb` AND `app/l10n/app_ar.arb`: every label, hint, validation message, fard explainer, delete dialog title/body, archive vs delete copy.

**Exit:** Anonymous user can add a category, add two tasks, hide a default, edit a default's points, and the home checklist reflects all changes within one frame.

---

## Group 9 — Home checklist consumes effective catalog

**Goal:** The actual checklist screen reflects the user's tailored list.

9.1. Refactor `app/lib/features/checklist/presentation/checklist_screen.dart` to consume `EffectiveCatalog` via Riverpod instead of the seeded constants.
9.2. Daily-log writes are still keyed by `taskCode` (defaults) or `userTask.id` (custom); the existing `daily_logs` schema gains a nullable `userTaskId` column with a one-row migration step.
9.3. Streak & dashboard providers (Phase 3, Phase 4) consume effective catalog totals so the daily percentage uses each user's own point pool, not the global one.
9.4. Manual test: hide one default task → daily percentage recalculates instantly; add one custom task worth 10 points → max moves to old-max + 10.

**Exit:** Daily % is computed against the user's effective catalog, not the seeded default.

---

## Group 10 — Hardening, parity, & polish

**Goal:** Make Phase 7 mergeable.

10.1. CI: backend Jest e2e covers section §3.1 of `validation.md`; Flutter widget tests cover the editor sheets and the empty-state of the Manage screen.
10.2. Run `tools/check_icon_parity.dart` in CI.
10.3. RTL pass on `Manage checklist`, both editors, and the fard explainer copy.
10.4. Update `app/test/widget_test.dart` if it asserted the seeded checklist count — make it tolerant.
10.5. Update `api/README.md`: env vars `MAX_USER_CATEGORIES`, `MAX_USER_TASKS`; a short note on the override model and the deprecated `GET /v1/tasks`.
10.6. Update `spec/roadmap.md`: tick Phase 7; note any items pushed forward (e.g., task ordering within a category) under Phase 8 prep.
10.7. Manual QA against `validation.md`; record a ≤ 90-second demo of full customization → sync → second device.

**Exit:** Every checkbox in `validation.md` passes; branch ready to merge.

---

## Group 11 — Forward-compatibility scaffolding (cheap, do-now)

**Goal:** Keep Phase 8 (challenges) and any "recurring tasks" follow-up cheap.

11.1. Reserve a nullable `recurrence` JSON column on `UserTask` (documented as unused in Phase 7). Phase 8 will use it for weekly templates.
11.2. Add a `description?` field (≤ 280 chars) on `UserTask` — unused this phase but trivial to add now; lets Phase 8 challenges attach an "intention" string.
11.3. Add a `kind: "TASK" | "CHALLENGE"` enum on `UserTask` with default `"TASK"` — Phase 8 reuses the row shape.

**Exit:** Code review confirms zero migrations required for the deferred items.
