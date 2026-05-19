# Requirements — Phase 7: Task Customization

**Phase:** 7 of the roadmap
**Branch:** `phase-7-2026-05-19-task-customization`
**Created:** 2026-05-19
**Status:** Spec — pre-implementation
**Estimated duration:** 4 days (per roadmap)

---

## 1. Context

After Phase 6 every signed-in user has a synced server identity, the catalog endpoint `GET /v1/tasks` exists but only returns the **global default task catalog** seeded by `api/prisma/seed.ts`. The Flutter checklist is the same fixed list for every user — `Fajr` → `Misc Adhkar`, hard-coded points, hard-coded icons. The roadmap promises Phase 7 will let users **fully tailor their checklist to their own routine**.

Phase 7 unlocks customization while preserving two cross-cutting promises:

- **Mission principle #4 — Local-first.** Customization must work for an anonymous user with no internet; sign-in only adds cross-device replication.
- **Mission principle #5 — Honest measurement.** Points reflect Islamic priority (fard > sunnah > nafl). A user re-weighting their own routine is fine; the **app's default catalog must remain immutable and globally consistent** so seeded points keep their honest meaning.

This phase is the first time the user can mutate the *shape* of their daily checklist — not just toggle completions. It touches: Prisma schema, NestJS endpoints, sync engine, drift schema, repositories, Riverpod providers, two new screens, and Arabic/English localization.

## 2. Goal (in one sentence)

A user — anonymous or signed-in — can add their own categories and tasks, hide or re-weight any default task, pick from a curated icon set, and (when signed in) see those customizations sync across devices using the same offline-tolerant queue Phase 6 introduced.

## 3. In Scope

### 3.1 Customization model — three layers

The catalog the UI consumes is a **merge of three layers**, in order:

1. **Defaults** (global, seeded, read-only)
   - `Category` and `Task` rows owned by no user; one shared copy across the install base.
2. **User overrides on defaults** (per-user, optional)
   - `UserCategoryOverride`: `hidden`, `customName?`, `customIcon?`, `sortOrder?`.
   - `UserTaskOverride`: `hidden`, `customName?`, `customPoints?`, `customIcon?`, `customCategoryRef?`, `sortOrder?`.
   - `customCategoryRef` is a stringly-typed reference of the form `category:<code>` (default) or `userCategory:<id>` (user-owned), so a default task can be re-categorized into either layer without a second nullable column. The same shape is used by `UserTask.categoryRef`.
   - **Absence of an override row ⇒ the default is shown as-is.** Edits create or update the override.
3. **User-owned items** (per-user, created from scratch)
   - `UserCategory` and `UserTask` rows that didn't exist in the defaults.

The Flutter client computes the effective catalog locally; the server validates the same shape on write.

### 3.2 Categories — Full CRUD with fard safeguards

- The user can create, rename, reorder, hide, and delete **their own** `UserCategory` rows.
- The user can rename/reorder/hide **default** categories via `UserCategoryOverride`, **except** the five fard-prayer categories: `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`.
  - Fard-prayer categories are pinned: cannot be hidden, cannot be renamed to an empty/whitespace name, cannot have their `code` changed. Reordering them **relative to each other** is allowed; they may move within the list but cannot be removed from it.
  - Rationale: prayer-time notifications scheduled in Phase 5 are keyed by category `code`, and the spiritual ordering Fajr → Isha is an honesty-of-measurement anchor (mission principle #5).
- "Soft" default categories (`qiyam`, `quran_fasting`, `misc`) may be hidden via override but **not deleted** — deletion is reserved for user-owned categories.
- Deleting a user-owned category requires the user to either reassign or also delete its custom tasks; the UI offers both paths.

### 3.3 Tasks — Full CRUD inside any non-hidden category

- Create: name (2–60 chars), category (default OR user-owned), points (1–20 integer), icon (curated set, §3.5).
- Edit (default task): writes a `UserTaskOverride` row; the default never mutates.
- Edit (user-owned task): writes the `UserTask` row directly.
- Hide: a default task gets `hidden=true` on its override; a user-owned task gets `archivedAt` set (soft-delete; preserved for historical logs).
- Hard delete of a user-owned task is allowed only if it has **zero `DailyLog`s** referencing it; otherwise the UI offers archive instead.
- Fard prayer tasks (`fajr_fard`, `dhuhr_fard`, `asr_fard`, `maghrib_fard`, `isha_fard`) **can** be hidden, but the confirm dialog shows a calm, niyyah-first note: *"This is an obligatory prayer. Hiding removes it from your daily count, not from your day."* — no blocking, no shame (mission principle #1).

### 3.4 Validation (server + client mirror)

- `points`: integer, **1 ≤ p ≤ 20**. Zero and negative rejected. 20 is chosen because it equals the highest default (`fajr_in_jamaah` in the Phase 1 catalog) — keeps user weights inside the honest range.
- `name`: trimmed, 2–60 chars; no leading/trailing whitespace; Unicode allowed (Arabic, English, mixed).
- `icon`: must be a member of the curated allowlist (§3.5). Anything else → 422.
- `categoryRef` (and `customCategoryRef`): must parse as `category:<code>` or `userCategory:<id>`; the referenced category must exist, belong to the user (for `userCategory:*`), and not be hidden by an override at write time.
- Per-user soft caps to keep totals sane:
  - Max **30** *active* user-owned tasks per user (`archivedAt IS NULL`). Archived tasks do **not** count against this cap, so a user who archives an old task can always create a new one.
  - Max **10** *active* user-owned categories per user (`archivedAt IS NULL`). Same rule.
  - These are config constants (`MAX_USER_TASKS`, `MAX_USER_CATEGORIES`), not hard schema limits.

### 3.5 Icon set — Curated Material Symbols

A frozen allowlist of ~40 Material Symbols icon codes lives at:

- Server: `api/src/tasks/icons.constants.ts` (exported, used by validators).
- Client: `app/lib/core/icons/curated_icons.dart` (mirrors the server list).

CI must verify the two lists are identical (a tiny check script).

Selection guidance (calm, worship-relevant): `mosque`, `book_5`, `sunny`, `nights_stay`, `volunteer_activism`, `self_improvement`, `favorite`, `auto_awesome`, `local_florist`, `water_drop`, `wb_twilight`, `dark_mode`, `light_mode`, `schedule`, `alarm`, `notifications`, `menu_book`, `bookmark`, `star`, `check_circle`, `radio_button_unchecked`, `flag`, `bolt`, `eco`, `spa`, `psychology`, `lightbulb`, `coffee`, `restaurant`, `bedtime`, `wb_sunny`, `partly_cloudy_day`, `family_restroom`, `groups`, `phone`, `chat`, `directions_walk`, `directions_run`, `fitness_center`, `library_books`.

Final list is decided in Group 2 of the plan; the constants file is the source of truth.

### 3.6 Backend (NestJS + Prisma + MySQL)

New / extended endpoints — all require `emailConfirmedAt != null` (inherits Phase 6 guard):

- `GET /v1/catalog` — returns `{ categories: [...], tasks: [...], userCategories: [...], userTasks: [...], userCategoryOverrides: [...], userTaskOverrides: [...] }` so the client can compute the effective catalog deterministically.
- `POST /v1/user-categories` — create.
- `PATCH /v1/user-categories/:id` — edit.
- `DELETE /v1/user-categories/:id` — delete; 409 if user-owned tasks reference it and `force=false`.
- `PUT /v1/user-category-overrides/:categoryCode` — upsert override on a default category (rejects fard-prayer codes for `hidden=true`).
- `POST /v1/user-tasks` — create.
- `PATCH /v1/user-tasks/:id` — edit.
- `DELETE /v1/user-tasks/:id` — hard-delete (409 if logs exist) or set `archivedAt` via `?archive=true`.
- `PUT /v1/user-task-overrides/:taskCode` — upsert override on a default task.
- `PUT /v1/customizations/batch` — single transactional endpoint used by the sync queue; accepts any mix of the above ops with `clientUpdatedAt`, returns per-op outcome. LWW applies on `(userId, entityKind, entityId)`.

OpenAPI annotations on every DTO; `/v1/docs` regenerated.

### 3.7 Flutter Client

- **Drift schema migration** adds local mirrors: `user_categories`, `user_tasks`, `user_category_overrides`, `user_task_overrides`. Migration is non-destructive — existing `daily_logs` and seeded `tasks` survive.
- **Repository layer** (`app/lib/features/checklist/data/`) gains a `CatalogRepository` that produces the effective catalog as a stream by joining the four tables with the seeded defaults.
- **New "Manage checklist" screen** (`app/lib/features/customization/presentation/manage_checklist_screen.dart`) — reachable from Settings *and* via an overflow menu on the home screen AppBar. Tabbed: `Categories` | `Tasks`.
- **Category editor sheet** — name (required), icon (curated picker), sort order (drag handle on the list, not in the sheet), visibility toggle (disabled for fard-prayer categories with a calm explainer line).
- **Task editor sheet** — name, category dropdown (lists non-hidden categories), points slider (1–20, snaps to integers; color stays soft-green throughout), icon picker, visibility toggle.
- **Sync** extends the Phase 6 `pending_sync_ops` table with new `opType` values: `upsert_user_category`, `delete_user_category`, `upsert_user_category_override`, `upsert_user_task`, `delete_user_task`, `upsert_user_task_override`. The drain path posts to `PUT /v1/customizations/batch`.
- **i18n**: every new visible string lands in `app/l10n/app_en.arb` AND `app/l10n/app_ar.arb`.

### 3.8 Anonymous-user parity

All customization works without sign-in. The pending-sync queue still records ops; when the user signs in later, the Phase 6 first-sign-in auto-merge (`FirstSignInMigrationService`) is extended to flush customization ops alongside log ops, in the same chunked batch.

## 4. Decisions (from clarification questions, 2026-05-19)

### 4.1 Customization scope — **Full CRUD on categories AND tasks (with fard-prayer safeguards)**
The roadmap line "control for tasks and category" is interpreted as full per-user CRUD on both, gated only by the five fard-prayer categories which remain pinned. Rationale: the mission's "fully tailor their checklist to their own routine" exit criterion requires more than tasks-only; locking just the fards keeps the spiritual ordering honest without paternalism.

Implications:
- Schema introduces `UserCategory` and `UserCategoryOverride` (not just task-side tables).
- Fard-prayer category codes form a small allowlist enforced at both API and client.
- Reordering UX must support all categories, not just user-created ones.

### 4.2 Hide/disable default tasks — **Separate `user_task_overrides` table**
Defaults stay global and read-only; per-user mutations are stored as override rows keyed by `(userId, taskCode)` (and analogously for categories).

Implications:
- Future updates to the default catalog (e.g., a corrected point value) automatically reach users who haven't overridden that field.
- Sync payloads are smaller — overrides are sparse.
- The client merge is a deterministic 3-layer join, easy to unit-test.
- Server validation rejects override writes against unknown default codes — keeps clients from forking the catalog.

### 4.3 Validation caps + icon handling — **Tight caps (1–20) + curated Material Symbols picker**
Points are integers in `[1, 20]`. The "icon" field is a string code from a frozen ~40-item Material Symbols allowlist; no free text, no emoji, no uploads.

Implications:
- The picker is finite and screenshot-stable; no internationalization concerns on icon names beyond `aria-label` localization.
- Server validators import the same constant the client uses — drift would be caught by the CI parity check.
- Future "premium" icon packs are a Phase 8+ concern.

## 5. Non-Goals (this phase)

- Custom **point values outside 1–20** — no fractional or >20 weights; "balanced system" wins over "expressive system".
- **Free-form icon uploads** or third-party icon packs.
- **Sharing custom tasks/categories** between users (no social, per mission v1).
- **Renaming fard-prayer category codes** — codes are permanent; display names of `fajr`–`isha` are also pinned (no `customName` override allowed for those five).
- **Reordering individual tasks within a category** — only categories are reorderable in v1; task order inside a category remains by `code` ASC. (Tracked for Phase 8 if users ask.)
- **Server-side cap on logs referencing a deleted user task** — we offer archive; we don't try to "undo history".
- **Bulk import/export** (CSV/JSON) of custom catalog — backlog.

## 6. Out-of-Scope but Documented for Later

- **Task ordering within a category**: defer to Phase 8 once we see how users actually arrange categories.
- **Recurring weekly-only tasks** (e.g., "Friday Surah Al-Kahf"): the `recurrence` column is reserved on `UserTask` but unused in Phase 7. Phase 8 challenges revisit recurrence.
- **Soft "templates"** (a "starter pack" a user can apply): backlog; the seeded defaults already serve this role for v1.

## 7. Constraints & Cross-Cutting Concerns

- **Offline-first** (mission #4): all CRUD writes to SQLite immediately and enqueues a sync op; no operation requires a network round-trip.
- **Tone** (mission #1): the visibility toggle on a fard prayer task shows *"This is an obligatory prayer. Hiding removes it from your daily count, not from your day."* — never a red error, never a forced cancel.
- **Calm palette** (mission #2): the destructive "Delete category" path uses soft amber, not red, and the confirm dialog leads with the consequence ("Your custom tasks under this category will move to Misc.") not the verb.
- **Privacy** (mission #6): no analytics on which tasks a user hides; the customization payload is treated as personal data and excluded from any future error-reporting redaction allowlist.
- **i18n**: every label, hint, validation message in both ARB files; Arabic RTL pass on the new screens.
- **Versioned API**: all routes under `/v1`.
- **Backward compatibility**: a client built against Phase 6 must keep working — `GET /v1/tasks` continues to return defaults only (now formally deprecated in the OpenAPI doc; `GET /v1/catalog` is the canonical replacement).

## 8. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| User accidentally hides a fard prayer category and panics | Low (UI prevents it) | Fard categories show a pinned-lock icon next to the visibility toggle; toggle is disabled with a tooltip explaining why. |
| Three-layer merge has subtle bugs (override on top of deleted user-owned category, etc.) | Medium | Pure function `effectiveCatalog(defaults, userItems, overrides)` in `app/lib/features/customization/domain/` with a property-test suite (≥ 30 cases) before any UI is wired. |
| Sync queue grows large during rapid edits (e.g., 20 quick toggles in the editor) | Low | Coalesce ops by `(entityKind, entityId)` at enqueue time — the latest payload wins locally before the queue ever hits the network. |
| Curated icon list drifts between server and client | Medium | CI parity script; PR template checkbox: "Did you update both `icons.constants.ts` and `curated_icons.dart`?" |
| User deletes a user-owned task that has historical logs | Medium | Hard-delete returns 409 from the server if logs exist; UI offers archive transparently — same button, different verb based on state. |

## 9. Dependencies

- Phase 6 must be merged. ✅ (verify on branch creation).
- Phase 6 sync engine (`pending_sync_ops`, `SyncService`, `FirstSignInMigrationService`) is the integration point — extended, not rewritten.
- Phase 6 `User.emailConfirmedAt` gate applies to every new endpoint.
- Phase 5 notification scheduler depends on category `code` values being stable; the fard-prayer-code safeguard in §3.2 is the contract Phase 5 relies on.

## 10. References

- `spec/roadmap.md` — Phase 7 entry.
- `spec/mission.md` — principles #1, #2, #4, #5, #6.
- `spec/tech-stack.md` — Data Model section (tasks as catalog + per-user customization).
- `specs/phase-6-2026-05-18-backend-optional-sync/requirements.md` — sync queue contract this phase extends.
