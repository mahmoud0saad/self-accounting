# Validation — Phase 6: Backend & Optional Sync

How we know Phase 6 is **done, working, and safe to merge** into `master`. Every section below must be checkable; ambiguity means it's not validation.

> Branch: `phase-6-2026-05-18-backend-optional-sync`
> Pair with: `requirements.md`, `plane.md`

---

## 1. Roadmap exit criterion (must pass)

From `spec/roadmap.md` Phase 6:

> *A signed-in user can log on phone, open the web build, and see identical state.*

**How we test it:**

- [ ] Run Flutter on Android emulator. Sign up as `qa+phase6@example.com`. Confirm email. Tap 6 checklist items today + 4 yesterday.
- [ ] Run Flutter web build. Sign in as the same user. Within 5 seconds of landing on the home screen, the same 10 completions are visible on the same dates.
- [ ] Toggle one item on web. Within 5 seconds of foregrounding the Android app, the toggle is reflected there.

---

## 2. Decision-specific acceptance

### 2.1 Auth = email/password only (decision §4.1)

- [ ] `grep -r "google" api/src` returns **zero** active code (only comments / `provider` column note).
- [ ] No `google_sign_in` or equivalent package in `app/pubspec.yaml`.
- [ ] `User.provider` column exists in MySQL and defaults to `'local'` for every row.

### 2.2 Email confirmation = hard gate (decision §4.2)

- [ ] `POST /v1/auth/login` with an unconfirmed user returns HTTP **403** and JSON body `{ code: "EMAIL_NOT_CONFIRMED", email, resendUrl }` — **never** an access token.
- [ ] Curl with a valid `accessToken` issued before `emailConfirmedAt` was set (manually backdated) → `GET /v1/logs` returns 403.
- [ ] On Flutter, signing in as an unconfirmed user **never** lands on the home screen; the `/auth/confirm` screen is always shown until confirmed.
- [ ] `POST /v1/auth/resend-confirmation` returns 429 after the 2nd request within the same minute.

### 2.3 First-sign-in auto-merge LWW (decision §4.3)

- [ ] Seed local SQLite with 30 days of completions on a fresh Flutter install. Sign in.
- [ ] Within 30 seconds, `GET /v1/logs?from=…` from a separate curl call shows all 30 days.
- [ ] **No** dialog or choice prompt is shown to the user during this migration.
- [ ] A single calm SnackBar appears with the localized form of *"Synced N days of history."*.
- [ ] Repeat sign-in on the same device → no second SnackBar, no duplicate writes (`pending_sync_ops` count stays 0).
- [ ] Conflict simulation: pre-seed the server with one row where `updatedAt` is **newer** than the local row for the same `(date, taskId)` → after migration, the server row survives unchanged.

---

## 3. Backend API contract

### 3.1 Endpoint smoke matrix

For each endpoint below, an automated Jest e2e test covers:

| Endpoint | Anon | Authed unconfirmed | Authed confirmed |
|---|---|---|---|
| `GET /v1/health` | 200 | 200 | 200 |
| `POST /v1/auth/register` | 201 | n/a | n/a |
| `POST /v1/auth/login` | 401 / 403 / 200 | 403 EMAIL_NOT_CONFIRMED | 200 + tokens |
| `POST /v1/auth/refresh` | 401 | 401 (no tokens issued yet) | 200 |
| `POST /v1/auth/logout` | 401 | 200 | 200 |
| `GET /v1/auth/confirm` | 200 HTML on valid token / 410 on consumed / 410 on expired | — | — |
| `POST /v1/auth/resend-confirmation` | 200 (rate-limited) | 200 | 204 (no-op) |
| `GET /v1/users/me` | 401 | 200 (returns user with `emailConfirmedAt: null`) | 200 |
| `PATCH /v1/users/me` | 401 | 403 | 200 |
| `GET /v1/tasks` | 401 | 403 | 200 |
| `GET /v1/logs` | 401 | 403 | 200 |
| `PUT /v1/logs/batch` | 401 | 403 | 200 with per-row outcomes |

- [ ] Every cell above corresponds to a passing test in `api/test/`.

### 3.2 LWW correctness

- [ ] Property test (or table test, ≥ 20 cases) for `PUT /v1/logs/batch`:
  - Given existing `(userId, date, taskId)` with `updatedAt = T`.
  - For client payload with `clientUpdatedAt = T' `, the row is updated iff `T' >= T`.
  - Response includes `serverUpdatedAt` reflecting the final value.

### 3.3 OpenAPI

- [ ] `GET /v1/docs` serves Swagger UI.
- [ ] The generated OpenAPI 3 JSON validates against the OpenAPI 3.0 schema (CI step).

---

## 4. SMTP / email

- [ ] Manual: registering with a fresh email lands a confirmation message in the inbox of **anti.mahmoud.saad.6@gmail.com**-routed test address within 60 seconds.
- [ ] Email subject and body are localized to the user's `Accept-Language` (English fallback when no header).
- [ ] Confirmation link points at `${APP_PUBLIC_URL}/v1/auth/confirm?token=…` and works on first click; second click returns the *"already confirmed"* success page.
- [ ] No SMTP secrets are committed; `api/.env.example` documents every required variable.
- [ ] Tone audit: no exclamation marks in subject lines; no urgency language; no shaming.

---

## 5. Flutter UX

### 5.1 Auth state visibility on home (roadmap line)

- [ ] **Unauthenticated**: AppBar shows a `Sign in` button. Tap → `/auth/sign-in`.
- [ ] **Authenticated**: AppBar shows the avatar + truncated `fullName`. Tap → `/profile`.
- [ ] Both states verified on a phone-width and tablet-width device.

### 5.2 Sign-out in settings

- [ ] Settings screen shows a `Sign out` row only when authenticated.
- [ ] Visual: amber (`#C98E1A` or equivalent calm tone), **not** red.
- [ ] Confirmation dialog uses the localized form of *"Sign out? Your data on this device will be kept."*.
- [ ] After sign-out: home screen shows `Sign in` again; local SQLite still has the user's last day of completions; opening the app while offline still works.

### 5.3 Profile fields

- [ ] `fullName` is **required** at sign-up (≥ 2 chars) and **required** to remain non-empty in profile edit.
- [ ] `photoUrl` accepts an empty value (cleared) and a valid HTTPS URL.
- [ ] Optional fields (`timezone`, `locale`, `bio`) can be left blank without blocking save.

### 5.4 Offline degradation

- [ ] Toggle airplane mode → all checklist interactions still work; ops accumulate in `pending_sync_ops`.
- [ ] Restore connectivity → queue drains within 15 seconds; UI does not jank.
- [ ] Attempt sign-in while offline → calm message, no spinner-of-death, retry possible.

### 5.5 Localization

- [ ] Every new visible string exists in `app/l10n/app_en.arb` AND `app/l10n/app_ar.arb`.
- [ ] Manual RTL pass: switch device language to Arabic, walk through sign-up → confirm → sign-in → home → profile → sign-out. Layouts mirror correctly; no clipped text.

### 5.6 Tone

- [ ] No error message uses words from this blocklist: *invalid, illegal, denied, forbidden, failure, error code* (unless inside a technical debug log).
- [ ] Sign-in failure copy is: *"That email and password don't match. Try again."*.

---

## 6. Tests (must be green in CI)

- [ ] Backend: `npm run test` (unit) — 0 failing.
- [ ] Backend: `npm run test:e2e` — 0 failing; covers section 3.1 matrix.
- [ ] Backend: `npm run lint` — 0 errors.
- [ ] Backend: `prisma migrate diff --from-migrations --to-schema-datamodel` — empty (no drift).
- [ ] Flutter: `flutter analyze` — 0 errors.
- [ ] Flutter: `flutter test` — existing `app/test/data/drift_checklist_repository_test.dart` still passes, plus new tests for `SyncService`, `AuthRepository`, and `FirstSignInMigrationService`.
- [ ] GitHub Actions CI on this branch is green.

---

## 7. Security gates

- [ ] Passwords hashed with bcrypt, cost ≥ 12.
- [ ] Access tokens TTL ≤ 15 minutes; refresh tokens TTL ≤ 30 days.
- [ ] Refresh tokens stored hashed (sha-256) server-side.
- [ ] Confirmation tokens are single-use; consumed tokens return 410 Gone.
- [ ] No PII (email, fullName) in any server log line — verified by `rg` over log statements.
- [ ] CORS allowlist on the API is **explicit**, not `*`, when not in dev mode.
- [ ] Rate limits in place: `register` (5/hour/IP), `login` (10/15min/IP), `resend-confirmation` (1/min, 5/day/email).

---

## 8. Documentation

- [ ] `README.md` updated: how to run with a backend; how to opt in to sync.
- [ ] `api/README.md` updated: env vars, Gmail App Password setup, local Docker MySQL.
- [ ] `spec/roadmap.md`: Phase 6 marked complete; deferred items (Google OAuth, photo upload) explicitly listed as **Phase 6.5**.
- [ ] `spec/tech-stack.md`: no edits required (already specifies the chosen stack), but verify nothing contradicts what was built.

---

## 9. Mergeability gate (final checklist)

Phase 6 is merged into `master` only when **all** of these are true:

- [ ] Every checkbox in §1, §2, §3, §5.1, §5.2, §5.4, §5.5, §6, §7 is ticked.
- [ ] Manual demo recorded (≥ 60s screen capture) showing sign-up → confirm → multi-device sync.
- [ ] Two-device convergence verified once on real hardware (not only emulators).
- [ ] No secrets, no `.env` files, no real email passwords in the diff.
- [ ] A short *"What's deferred to Phase 6.5"* paragraph is added to the merge commit body (Google OAuth, photo upload, refresh-reuse detection).
