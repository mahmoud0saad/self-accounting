# Validation — Phase 7: Task Customization

How we know Phase 7 is **done, working, and safe to merge** into `master`. Every section below must be checkable; ambiguity means it's not validation.

> Branch: `phase-7-2026-05-19-task-customization`
> Pair with: `requirements.md`, `plane.md`

---

## 1. Roadmap exit criterion (must pass)

From `spec/roadmap.md` Phase 7:

> *Users can fully tailor their checklist to their own routine.*

**How we test it:**

- [ ] On a fresh Android install (anonymous user), the user can:
  1. Open `Manage checklist`.
  2. Create a new category `Quran study` with the `menu_book` icon.
  3. Add a custom task `Memorize 5 ayat` (10 pts, icon `book_5`) under it.
  4. Hide the default task `Tahajjud (3+ rakaat)`.
  5. Edit the default task `Sadaqah` to be worth 8 points instead of its seeded value.
- [ ] Return to home — the checklist now shows `Quran study` as a new section with one task; `Tahajjud (3+ rakaat)` is no longer visible; `Sadaqah` displays as `8 pts`.
- [ ] Sign in with `qa+phase7@example.com` (already confirmed). Within 30 seconds of foregrounding on a second device signed in as the same user, the second device shows the identical effective catalog.

---

## 2. Decision-specific acceptance

### 2.1 Full CRUD on categories + tasks with fard safeguards (decision §4.1)

- [ ] In `Manage checklist → Categories`, the five fard-prayer categories (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`) each show a pinned-lock icon and a **disabled** visibility toggle.
- [ ] Long-press on the disabled toggle reveals the localized form of *"This is an obligatory prayer category and stays on your daily list."*.
- [ ] `PUT /v1/user-category-overrides/fajr` with `{ hidden: true }` returns **422** `{ code: "FARD_CATEGORY_LOCKED" }` — verified by an automated test in `api/test/`.
- [ ] `PUT /v1/user-category-overrides/fajr` with `{ customName: "Subh" }` returns **422** `{ code: "FARD_CATEGORY_LOCKED" }`.
- [ ] Reordering fard categories among themselves is allowed (verified by manual drag-handle test).
- [ ] User-owned categories support: create, rename, reorder, hide, delete with `?force=true`.

### 2.2 `user_task_overrides` table model (decision §4.2)

- [ ] Editing the points of a default task **does not** mutate any row in the `Task` table (verified by snapshotting `Task` rows before and after — `updatedAt` and `defaultPoints` unchanged).
- [ ] Hiding a default task creates exactly one row in `UserTaskOverride`; un-hiding deletes the override row (verified by row count).
- [ ] After an override is removed, the client UI reverts to the seeded default automatically.
- [ ] A `GET /v1/catalog` response with **zero** overrides has empty `userTaskOverrides` and `userCategoryOverrides` arrays — not stubs of every default.

### 2.3 Tight caps (1–20) + curated icon picker (decision §4.3)

- [ ] `POST /v1/user-tasks` with `points: 0` → **422** `{ code: "POINTS_OUT_OF_RANGE" }`.
- [ ] `POST /v1/user-tasks` with `points: 21` → **422** `{ code: "POINTS_OUT_OF_RANGE" }`.
- [ ] `POST /v1/user-tasks` with `points: -1` → **422** `{ code: "POINTS_OUT_OF_RANGE" }`.
- [ ] `POST /v1/user-tasks` with `icon: "rocket_launch"` (not in the curated list) → **422** `{ code: "ICON_NOT_ALLOWED" }`.
- [ ] Flutter slider for points cannot select 0 or 21; the minimum stop is 1 and the maximum stop is 20 (verified by widget test).
- [ ] The icon picker grid is exactly the curated set; no free-text field anywhere.
- [ ] CI parity check (`tools/check_icon_parity.dart` or equivalent) exits **zero**; introducing a deliberate divergence in a feature branch makes CI red.

---

## 3. Backend API contract

### 3.1 Endpoint smoke matrix

For each endpoint below, an automated e2e test covers:

| Endpoint | Anon | Authed unconfirmed | Authed confirmed |
|---|---|---|---|
| `GET /v1/catalog` | 401 | 403 | 200 |
| `POST /v1/user-categories` | 401 | 403 | 201 |
| `PATCH /v1/user-categories/:id` | 401 | 403 | 200 / 404 |
| `DELETE /v1/user-categories/:id` | 401 | 403 | 204 / 409 (no force) |
| `PUT /v1/user-category-overrides/:categoryCode` | 401 | 403 | 200 / 422 (fard) |
| `POST /v1/user-tasks` | 401 | 403 | 201 / 422 |
| `PATCH /v1/user-tasks/:id` | 401 | 403 | 200 / 404 |
| `DELETE /v1/user-tasks/:id` | 401 | 403 | 204 / 409 (logs exist) |
| `PUT /v1/user-task-overrides/:taskCode` | 401 | 403 | 200 |
| `PUT /v1/customizations/batch` | 401 | 403 | 200 with per-op outcomes |

- [ ] Every cell above corresponds to a passing test in `api/test/`.

### 3.2 LWW correctness for `PUT /v1/customizations/batch`

- [ ] Property test (or table test, ≥ 20 cases): for each op kind, a payload with `clientUpdatedAt < existing.updatedAt` returns `{ applied: false, error: "STALE" }` and leaves the row unchanged.
- [ ] Batch idempotency: replaying the same batch twice produces the same final database state (verified by snapshot comparison).
- [ ] Order independence within a batch: shuffling the order of ops in a batch produces the same final state (verified for ≥ 10 random shuffles).

### 3.3 Caps & limits

- [ ] Creating the 11th `UserCategory` returns **422** `{ code: "LIMIT_EXCEEDED" }`.
- [ ] Creating the 31st `UserTask` returns **422** `{ code: "LIMIT_EXCEEDED" }`.
- [ ] Archiving (not deleting) a `UserTask` does NOT count toward the active-task limit.

### 3.4 OpenAPI

- [ ] `GET /v1/docs` shows all new endpoints under a `Customization` tag.
- [ ] `GET /v1/tasks` is marked deprecated in the JSON schema (`"deprecated": true`).

---

## 4. Flutter UX

### 4.1 Manage screen reachability

- [ ] Settings screen has a `Manage checklist` ListTile, both signed-in and anonymous.
- [ ] Home screen AppBar overflow menu has a `Manage checklist` item; tapping either entry lands on the same screen.

### 4.2 Category management

- [ ] Drag-and-drop reordering of categories emits exactly **one** batched sortOrder update (verified by counting queue entries).
- [ ] The five fard-prayer categories visually present a pinned-lock icon and a disabled toggle.
- [ ] Creating a category named `   ` (whitespace only) is blocked at the form layer with a calm validation message.
- [ ] Deleting a user-owned category with one or more user-owned tasks prompts: *"Move 'X' tasks to **Misc**, or delete them too?"*.

### 4.3 Task management

- [ ] Points slider snaps to integers; the displayed value cannot show `0`, `21`, or a decimal.
- [ ] The icon picker shows exactly the curated set; tapping an icon updates the preview and dismisses on save only.
- [ ] Hiding the fard task `fajr_fard` triggers the niyyah-first dialog *"This is an obligatory prayer. Hiding removes it from your daily count, not from your day."* — the dialog has Cancel and Hide buttons; both are soft-toned, neither is red.
- [ ] Deleting a user-owned task with historical `daily_logs` automatically becomes an "Archive" action with copy *"Keep your history, hide it from today."*.

### 4.4 Home checklist consumes effective catalog

- [ ] After hiding a default task, the home checklist updates within one frame (visible in the next paint).
- [ ] The daily percentage uses the effective catalog's total points, not the seeded total (verified by adding a 10-pt custom task and confirming the new denominator).
- [ ] Dashboard charts (Phase 4) reflect customized totals: per-category breakdown shows the user's custom categories alongside defaults.

### 4.5 Offline parity

- [ ] Toggle airplane mode → all customization actions succeed locally; the `pending_sync_ops` count increases.
- [ ] Restore connectivity (signed-in, confirmed) → the queue drains within 15 seconds; no UI jank.
- [ ] Anonymous user can fully customize the checklist for 7 consecutive days without ever signing in; closing/reopening the app preserves everything.

### 4.6 Sign-in migration of customizations

- [ ] Anonymous user creates 3 custom categories + 8 custom tasks + 5 overrides → signs in (confirmed account) → within 30s, `GET /v1/catalog` on a separate curl call shows all of them.
- [ ] Repeat sign-in on the same device → no duplicate writes; `pending_sync_ops` stays at 0.

### 4.7 Localization

- [ ] Every new visible string exists in `app/l10n/app_en.arb` AND `app/l10n/app_ar.arb`.
- [ ] Arabic RTL pass: switch device to Arabic → walk through `Manage checklist → Categories → Add → Tasks → Edit default points`. Layouts mirror correctly; the icon picker grid stays LTR (icons are visual), but labels and form fields are RTL.

### 4.8 Tone

- [ ] No new error message uses words from this blocklist: *invalid, illegal, denied, forbidden, failure, error code* (verified by grep against the new ARB entries).
- [ ] The fard hide warning uses the exact niyyah-first phrasing in §4.3 (verified by string assertion in widget test).
- [ ] Destructive actions (delete category, delete task) use soft amber, not red.

---

## 5. Three-layer merge correctness

The `effectiveCatalog(...)` function from Plan Group 1 is the brain of this phase. Independent of any UI, the following must hold:

- [ ] Property test (≥ 30 cases) in `app/test/features/customization/effective_catalog_test.dart` passes.
- [ ] Specific cases included:
  - Override on a hidden default category ⇒ the override applies only if the override itself unhides.
  - User-owned category referenced by a user-owned task; deleting the category with `force=true` reassigns tasks to `category:misc` in the effective output.
  - Override on a fard category with `hidden=true` ⇒ throws a domain error (never reaches the network).
  - Default task with override `customCategoryRef = userCategory:<id>` ⇒ task appears under the user's category in the effective output.
  - Empty arrays in / seeded defaults out — the bootstrap case.

---

## 6. Tests (must be green in CI)

- [ ] Backend: `npm run test` — 0 failing; new suites under `api/test/customization/`.
- [ ] Backend: `npm run test:e2e` — covers §3.1 matrix.
- [ ] Backend: `npm run lint` — 0 errors.
- [ ] Backend: `prisma migrate diff --from-migrations --to-schema-datamodel` — empty (no drift).
- [ ] Flutter: `flutter analyze` — 0 errors.
- [ ] Flutter: `flutter test` — all existing tests still pass + new suites for `CatalogRepository`, the editor sheets, and `effective_catalog`.
- [ ] Icon-parity script in CI exits zero.
- [ ] GitHub Actions CI on this branch is green.

---

## 7. Security & data-integrity gates

- [ ] No customization endpoint accepts requests for `userId` other than `req.user.id` — verified by an e2e test that forges a `userId` in the body and confirms the server ignores it.
- [ ] Per-user limits (`MAX_USER_CATEGORIES`, `MAX_USER_TASKS`) are enforced at the API; a flooded client cannot bypass them.
- [ ] Icon allowlist is enforced server-side, not client-side trust; a curl call with `icon: "<script>"` returns 422.
- [ ] `DELETE /v1/user-tasks/:id` with referenced logs returns 409, never silently deletes log rows.
- [ ] No PII in any new server log line (no `fullName`, no email, no custom-task `name`) — verified by `rg` over the new code.

---

## 8. Documentation

- [ ] `README.md` updated: short paragraph on customization and the deprecated `GET /v1/tasks`.
- [ ] `api/README.md` updated: new env vars (`MAX_USER_CATEGORIES`, `MAX_USER_TASKS`); section on the override model.
- [ ] `spec/roadmap.md`: Phase 7 marked complete; any deferred items (task-order within category, recurrence, templates) explicitly listed under Phase 8 prep.
- [ ] `spec/tech-stack.md`: no edits required, but verify the Data Model section still matches what was built; if it doesn't, add a paragraph clarifying the three-layer model.

---

## 9. Mergeability gate (final checklist)

Phase 7 is merged into `master` only when **all** of these are true:

- [ ] Every checkbox in §1, §2, §3, §4.1, §4.2, §4.3, §4.4, §4.5, §4.7, §5, §6, §7 is ticked.
- [ ] Manual demo recorded (≥ 60s screen capture) showing: create category → add task → hide default → edit default points → daily % recalculates → sign in → second device shows identical state.
- [ ] Two-device convergence verified once on real hardware (not only emulators).
- [ ] No secrets, no `.env` files, no real email passwords in the diff.
- [ ] A short *"What's deferred to Phase 8"* paragraph is added to the merge commit body (task-order within a category, recurrence, "templates" / starter packs).
