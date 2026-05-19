# Plan — Phase 6: Backend & Optional Sync

A series of **numbered task groups**, ordered so each group leaves the repo in a working, demoable state. Tick boxes as you complete them. Each group should be one PR (or one well-titled commit on this branch).

> Branch: `phase-6-2026-05-18-backend-optional-sync`
> Companion docs: `requirements.md`, `validation.md`

---

## Group 1 — Prisma schema & database migration

**Goal:** Get the persistence shape right before any business code.

1.1. Add Prisma models to `api/prisma/schema.prisma`:
- `User` { id, email (unique, citext), passwordHash, fullName, photoUrl?, timezone?, locale?, bio?, provider (default `"local"`), emailConfirmedAt?, createdAt, updatedAt }
- `EmailConfirmationToken` { id, userId, token (unique), expiresAt, consumedAt?, createdAt }
- `RefreshToken` { id, userId, tokenHash (unique), expiresAt, revokedAt?, createdAt }
- `Task` { id, code (unique), category, defaultPoints, isDefault, createdAt }
- `DailyLog` { id, userId, date (DATE), taskId, completed, updatedAt; unique index `(userId, date, taskId)` }

1.2. Generate and apply migration `phase6_init`.
1.3. Seed default tasks (mirror Phase 1 hard-coded catalog) via a Prisma seed script.
1.4. Add `DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ACCESS_TTL=15m`, `JWT_REFRESH_TTL=30d` to `.env.example`.

**Exit:** `prisma migrate dev` succeeds; `prisma db seed` inserts default tasks.

---

## Group 2 — Auth module (register + login + refresh + logout)

**Goal:** Email/password auth wired end-to-end, **without** the email-confirmation gate yet (added in Group 4).

2.1. `AuthModule` with `AuthService`, `AuthController`, `JwtStrategy`, `RefreshStrategy`.
2.2. Endpoints:
- `POST /v1/auth/register` — DTO validated by `class-validator`; bcrypt password hash (cost 12); returns 201 with no tokens.
- `POST /v1/auth/login` — returns `{ accessToken, refreshToken, user }`.
- `POST /v1/auth/refresh` — rotates refresh token; revokes the consumed one.
- `POST /v1/auth/logout` — revokes the presented refresh token.
2.3. `JwtAuthGuard` applied globally with `@Public()` opt-out for `/v1/health` and `/v1/auth/*`.
2.4. Unit tests for `AuthService` happy paths and 4 failure modes (wrong password, unknown email, expired refresh, revoked refresh).

**Exit:** Postman / `httpie` flow: register → login → call protected echo route → refresh → logout works.

---

## Group 3 — SMTP integration & email confirmation issuance

**Goal:** Real emails go out; confirmation tokens get created and consumed.

3.1. `MailModule` wrapping `nodemailer` SMTP transport. Reads `SMTP_*` env vars; throws on boot if any required var is missing.
3.2. Two MJML-or-plain-HTML templates in `api/src/mail/templates/`:
- `confirm-email.hbs`
- `welcome.hbs`
Both must be calm and short (mission principle #1).
3.3. On `POST /v1/auth/register`: create `EmailConfirmationToken` (24h TTL, 32-byte random URL-safe), send confirmation email with link `${APP_PUBLIC_URL}/v1/auth/confirm?token=...`.
3.4. `GET /v1/auth/confirm?token=...` — validates, sets `user.emailConfirmedAt = now()`, consumes token, sends `welcome` email, responds with a minimal HTML success page.
3.5. `POST /v1/auth/resend-confirmation` — rate-limited (Nest `Throttler`: 1/min and 5/day per email).
3.6. Configure for **anti.mahmoud.saad.6@gmail.com** as the Phase 6 sender. Document App Password setup in `api/README.md`.

**Exit:** A real email arrives at a test inbox within ~30s of registration; clicking the link flips `emailConfirmedAt`.

---

## Group 4 — Hard-gate guard on protected endpoints

**Goal:** Implement decision §4.2 — no protected access until email is confirmed.

4.1. `EmailConfirmedGuard` reading `req.user.emailConfirmedAt` from the JWT payload (refresh embeds it; access token includes it on issue).
4.2. Globally registered after `JwtAuthGuard`; opt-out only on `/v1/auth/*`, `/v1/health`, `/v1/users/me` GET (so the client can show "please confirm" with the user's email).
4.3. `POST /v1/auth/login` returns 403 `{ code: "EMAIL_NOT_CONFIRMED", email, resendUrl }` instead of tokens when `emailConfirmedAt IS NULL`.
4.4. E2E test: full register → login → 403 → confirm → login → 200 flow.

**Exit:** Curl proves no protected route succeeds for an unconfirmed user.

---

## Group 5 — Users & profile endpoints

**Goal:** The client can read/update profile data.

5.1. `UsersModule` with `GET /v1/users/me` (allowed pre-confirmation) and `PATCH /v1/users/me` (requires confirmation).
5.2. Validation: `fullName` required 2–80 chars; `photoUrl` HTTPS only; `locale` ∈ {`en`, `ar`}; `timezone` IANA-validated against `Intl.DateTimeFormat().resolvedOptions()` allowlist or `luxon`.
5.3. Best-effort HEAD check on `photoUrl` content-type; non-blocking warning if non-image.

**Exit:** `PATCH /v1/users/me` updates fields; `GET` reflects them.

---

## Group 6 — Tasks & logs endpoints

**Goal:** Real sync surface area.

6.1. `GET /v1/tasks` returns catalog (default + future user-custom; Phase 6 returns defaults only).
6.2. `GET /v1/logs?from=YYYY-MM-DD&to=YYYY-MM-DD` returns the signed-in user's `DailyLog` rows in `[from, to]`.
6.3. `PUT /v1/logs/batch` accepts up to 500 rows: `{ date, taskId, completed, clientUpdatedAt }`. For each row, upsert with the LWW rule: write **only if** `clientUpdatedAt >= existing.updatedAt`. Return per-row outcome `{ applied: bool, serverUpdatedAt }`.
6.4. OpenAPI annotations on all DTOs; `/v1/docs` serves Swagger UI.

**Exit:** Synthetic test: two clients race; older `clientUpdatedAt` is rejected; newer wins.

---

## Group 7 — Flutter auth feature scaffolding

**Goal:** Client knows how to talk to the API.

7.1. New folders: `app/lib/features/auth/{data,domain,presentation}` and `app/lib/features/profile/{data,domain,presentation}`.
7.2. `AuthApi` (dio client), `AuthRepository`, `AuthState` (Riverpod `AsyncNotifier`).
7.3. Token storage in `flutter_secure_storage`; auto-load on app boot; refresh interceptor.
7.4. Screens (Material 3, soft-green palette):
- `SignInScreen`
- `SignUpScreen`
- `ConfirmEmailScreen` (with `Resend` button, rate-limited UX, and `I've confirmed — check again` button)
7.5. `go_router` routes: `/auth/sign-in`, `/auth/sign-up`, `/auth/confirm`. `/auth/confirm` is the **gate** — any authenticated state with `emailConfirmedAt == null` redirects here.
7.6. ARB additions in `app_en.arb` AND `app_ar.arb` for every new string.

**Exit:** A user can sign up on the Flutter app, see the confirm screen, click the email link, return to the app, tap "Check again", and land on the home screen.

---

## Group 8 — Conditional home/settings UI for auth state

**Goal:** Implement the roadmap line *"show btn login if not on home screen and show name if is already login and make btn sign out in setting."*

8.1. `app/lib/features/checklist/presentation` — AppBar trailing widget:
- Unauthenticated → `Sign in` text button → `/auth/sign-in`.
- Authenticated → avatar (initials fallback) + truncated `fullName`, tap → `/profile`.
8.2. `app/lib/features/settings/presentation/settings_screen.dart` — add `Sign out` ListTile (soft amber, not red), visible only when authenticated. Confirmation dialog: *"Sign out? Your data on this device will be kept."*
8.3. Profile screen with editable `fullName`, `photoUrl`, `timezone`, `locale`, `bio`.
8.4. Hook `notification_onboarding_screen.dart` (untracked file from Phase 5) — verify it still works for both signed-in and signed-out users.

**Exit:** Manual walkthrough matches the roadmap line; sign-out preserves local data.

---

## Group 9 — Sync engine (outbound queue + pull-on-foreground)

**Goal:** Local mutations replay; remote deltas land.

9.1. New `drift` table `pending_sync_ops` { id, opType, payloadJson, clientUpdatedAt, attempts, lastError? }.
9.2. Refactor `drift_history_repository.dart` and the daily-log writes to also enqueue an op on every mutation.
9.3. `SyncService` (Riverpod-scoped) with:
- `drainOutbound()` — batches 100 ops → `PUT /v1/logs/batch`; on success, deletes ops; on partial failure (per-row LWW reject), logs and drops the op.
- `pullDeltas()` — `GET /v1/logs?from=<lastCursor>`; merges into SQLite using LWW; updates cursor.
9.4. Trigger points: app foreground, connectivity restored, after auth refresh succeeds, manual "Sync now" in settings.
9.5. Gate: do nothing unless `authenticated && emailConfirmedAt != null && online`.

**Exit:** Two devices on the same account converge within one foreground cycle.

---

## Group 10 — First-sign-in auto-merge

**Goal:** Implement decision §4.3.

10.1. On first successful authenticated `GET /v1/users/me` after a sign-in, run `FirstSignInMigrationService` once (idempotent via a key in `flutter_secure_storage`: `first_sync_done:<userId>`).
10.2. Steps: pull full history once (`from=2000-01-01`) → enqueue every local row as an op with its original `updatedAt` as `clientUpdatedAt` → drain.
10.3. On success, show a single calm SnackBar: *"Synced N days of history."* (localized).

**Exit:** A user with 30 days of local data signs in on a clean device, signs in on the original device, and both show identical history.

---

## Group 11 — Hardening & polish

**Goal:** Make Phase 6 mergeable.

11.1. Update `app/l10n/app_en.arb` and `app/l10n/app_ar.arb` — RTL screenshot pass on every new screen.
11.2. Add CI job: backend Jest tests + Prisma migrate check; Flutter widget tests for new screens.
11.3. Update `README.md` quickstart: how to run the backend locally with Gmail SMTP App Password (link to Google App Passwords help).
11.4. Add `api/README.md` section: how to point at a fresh local MySQL via Docker Compose.
11.5. Manual QA against `validation.md`.
11.6. Update `spec/roadmap.md`: tick Phase 6, note deferred items (Google OAuth, photo upload) as **Phase 6.5**.

**Exit:** Every checkbox in `validation.md` passes. Branch ready to merge.

---

## Group 12 — Forward-compatibility scaffolding (cheap, do-now)

**Goal:** Keep Phase 7 (custom tasks) and the Google-OAuth follow-up cheap.

12.1. `Task` model already nullable on `userId` (not added here — handled in Phase 7), but reserve the column convention now in code comments.
12.2. `User.provider` defaults to `"local"`. No code path uses it yet — documented.
12.3. Refresh-token table includes `family` column (UUID) to enable reuse-detection later.

**Exit:** Code review confirms zero migrations required for the deferred items.
