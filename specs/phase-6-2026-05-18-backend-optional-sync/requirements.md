# Requirements — Phase 6: Backend & Optional Sync

**Phase:** 6 of the roadmap
**Branch:** `phase-6-2026-05-18-backend-optional-sync`
**Created:** 2026-05-18
**Status:** Spec — pre-implementation
**Estimated duration:** 5 days (per roadmap)

---

## 1. Context

Through Phase 5 (MVP), the app is fully **local-first**: a single Flutter client persists tasks, daily logs, and streaks in SQLite via `drift`. The NestJS API skeleton from Phase 0 only exposes `GET /v1/health`.

Phase 6 closes the loop promised by `spec/tech-stack.md`:

> *Optional sign-in: User may attach an account at any time; local data is migrated/merged to the server under their `user_id`. Sign-out preserves local data but disables sync.*

This phase is the **first phase that adds backend behavior the user can feel**. It must not regress the offline-first guarantee from `spec/mission.md` principle #4 — *"The user owns their data. Local-first behavior; cloud sync is optional and explicit."*

## 2. Goal (in one sentence)

A user can create an email/password account, confirm their email via an SMTP-delivered link, sign in on the Flutter client, and then transparently sync their existing local checklist data to the server — and back to any other device — using a last-write-wins offline-tolerant sync queue.

## 3. In Scope

### 3.1 Backend (NestJS + Prisma + MySQL)

- `/v1/auth` module
  - `POST /v1/auth/register` — email + password + `fullName` → creates `User`, sends confirmation email, returns 201 (no tokens yet — confirmation required).
  - `POST /v1/auth/login` — email + password → returns `accessToken` + `refreshToken` **only if** `emailConfirmedAt IS NOT NULL`.
  - `POST /v1/auth/refresh` — rotates refresh token.
  - `POST /v1/auth/logout` — revokes refresh token.
  - `GET  /v1/auth/confirm?token=...` — confirms email, sets `emailConfirmedAt`, redirects to a static "email confirmed" HTML page.
  - `POST /v1/auth/resend-confirmation` — rate-limited (1/min, 5/day per email).
- `/v1/users/me`
  - `GET` → profile.
  - `PATCH` → update `fullName` (required, ≥ 2 chars), `photoUrl` (optional), and other optional fields (`timezone`, `locale`, `bio`).
- `/v1/tasks`
  - `GET` → catalog (default + user-custom). Read-only this phase; custom tasks are Phase 7.
- `/v1/logs`
  - `GET /v1/logs?from=YYYY-MM-DD&to=YYYY-MM-DD` → completions for the signed-in user.
  - `PUT /v1/logs/batch` → upsert array of `{ date, taskId, completed, clientUpdatedAt }`; server applies last-write-wins on `(userId, date, taskId)` using `clientUpdatedAt` vs stored `updatedAt`.
- Email gate guard: every endpoint except `/v1/auth/*` and `/v1/health` requires `emailConfirmedAt != null` on the JWT subject.
- OpenAPI 3 spec auto-generated and served at `/v1/docs`.

### 3.2 SMTP Integration

- Provider-agnostic SMTP via `nodemailer`. Initial config targets Gmail SMTP for the project mailbox **anti.mahmoud.saad.6@gmail.com** (sender) using an App Password stored in `SMTP_PASSWORD`.
- Env vars: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM_NAME`, `APP_PUBLIC_URL`.
- Two transactional templates:
  1. `confirm-email` — sent on register / resend.
  2. `welcome` — sent once `emailConfirmedAt` is set.
- All emails must be calm, Niyyah-first in tone (per mission principle #1). No marketing copy.

### 3.3 Flutter Client

- New `auth` feature directory: `app/lib/features/auth/{data,domain,presentation}`.
- New `sync` feature directory: `app/lib/features/sync/{data,domain,presentation}`.
- **Home screen** (`features/checklist/presentation`): conditionally render a **"Sign in"** button in the AppBar trailing area when not authenticated; render the user's **`fullName`** (truncated, with avatar circle) when authenticated. Tapping either opens the auth/profile screen.
- **Settings screen**: add a **"Sign out"** row (destructive list-tile, soft amber — not red — per mission principle #2) visible only when authenticated.
- Auth flow screens:
  - Sign-up (email, password, confirm password, full name).
  - Sign-in (email, password).
  - "Confirm your email" interstitial after sign-up and after every sign-in attempt where `emailConfirmedAt` is null — shows a resend button and a "Check again" button.
- Token storage in `flutter_secure_storage`; `dio` interceptor handles 401 → refresh → retry.
- **Sync engine**:
  - Outbound queue table in SQLite (`pending_sync_ops`) recording every local mutation with a monotonically increasing `clientUpdatedAt` (UTC ISO-8601, sourced from a single clock helper).
  - On connectivity + authenticated + email-confirmed, drain queue via `PUT /v1/logs/batch` in chunks of 100.
  - On every authenticated app foreground, pull deltas via `GET /v1/logs?from=` (last successful pull cursor) and apply LWW locally.
- **First-sign-in migration** (decision §4.3): silently auto-merge using LWW; no user prompt. Existing local rows get `clientUpdatedAt = max(local.updatedAt, now-1ms)` so server values from a prior device aren't unfairly overwritten.

### 3.4 Profile Data

- `fullName` — required, 2–80 chars.
- `photoUrl` — optional. Phase 6 stores URL only; upload pipeline is **out of scope** (deferred — see §6). The PATCH endpoint accepts any HTTPS URL and validates `Content-Type` on a HEAD request (best-effort).
- Optional fields: `timezone` (IANA), `locale` (`en` | `ar`), `bio` (≤ 280 chars).

## 4. Decisions (from clarification questions, 2026-05-18)

### 4.1 Authentication providers — **Email/password only**
Google OAuth (originally listed in the roadmap) is **deferred** to a follow-up mini-phase. Rationale: tightens Phase 6 scope, removes OAuth provider config from the critical path, and the SMTP confirmation flow already establishes the email-trust primitive we need for v1.

Implications:
- No `/v1/auth/google` endpoint this phase.
- No Google sign-in SDK dependency in Flutter this phase.
- Database schema **still** includes a nullable `provider` column on `User` (default `'local'`) so OAuth can be added later without a migration of existing rows.

### 4.2 Email confirmation strictness — **Hard gate**
An account exists immediately after registration, but **no protected endpoint** (anything outside `/v1/auth/*` and `/v1/health`) succeeds until the user clicks the confirmation link.

Implications:
- `POST /v1/auth/login` returns `403 EMAIL_NOT_CONFIRMED` with `{ resendUrl }` if `emailConfirmedAt IS NULL`.
- Flutter sign-in screen handles this 403 by routing to the "Confirm your email" interstitial instead of the home screen.
- The sync engine is gated: even with a valid `accessToken`, the queue does not drain until `me.emailConfirmedAt != null`. The user can still use the app fully offline.

### 4.3 Local-to-server migration on first sign-in — **Auto-merge, last-write-wins**
Silent, per `(user_id, date, task_id)`. No prompt.

Implications:
- The first authenticated `GET /v1/logs` pull is followed by a single full-history flush of local logs via `PUT /v1/logs/batch`.
- Local rows authored before sign-in are stamped with their original `updatedAt`; server-side LWW resolves any overlap.
- The user sees a one-time toast: *"Synced N days of history."* (calm, no progress modal).

## 5. Non-Goals (this phase)

- Google OAuth, Apple Sign-In (§4.1).
- Photo upload pipeline (multipart, image resize, CDN) — only URL storage.
- Real-time push or WebSockets — pull-on-foreground is enough.
- Custom-task CRUD (Phase 7).
- Family/social/multi-user accounts (out of scope per mission v1).
- Server-side streak calculation — streaks remain a derived client-side concern in Phase 6; cached `streaks` table is Phase 7+.

## 6. Out-of-Scope but Documented for Later

- **Photo upload**: Phase 6.5 candidate. Pre-signed S3 PUT or NestJS multipart endpoint.
- **Google OAuth**: Phase 6.5 candidate. Schema is forward-compatible.
- **Refresh-token rotation reuse detection**: this phase rotates but does not yet detect family reuse; tracked as a hardening item.

## 7. Constraints & Cross-Cutting Concerns

- **Privacy** (mission principle #6): no third-party analytics SDKs; SMTP traffic stays between the API and Gmail SMTP.
- **Tone** (mission principle #1): error copy must never shame the user. Failed login: *"That email and password don't match. Try again."* — not *"Invalid credentials."*
- **Offline-first** (mission principle #4): every flow Phase 6 adds must degrade gracefully when offline. Sign-in attempted offline → friendly *"You're offline. We'll keep your day saved here until you're back."*
- **i18n**: every new string lands in `app/l10n/app_en.arb` AND `app/l10n/app_ar.arb`. No hardcoded copy.
- **Soft palette**: sign-out and destructive flows use soft amber, not red (mission principle #2).
- **Versioned API**: all new routes under `/v1`.

## 8. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Gmail SMTP rate limits / spam classification for confirmation emails | Medium | Use App Password; warm sender; add SPF/DKIM later; provide manual "resend" with rate limit. |
| LWW silently overwrites multi-device edits made within the same minute | Low | Use millisecond-precision `clientUpdatedAt`; document behavior. |
| Hard email gate frustrates users with typo'd emails | Medium | Resend + "Change email" path in the interstitial; rate-limited. |
| Local→server merge dumps a huge batch and times out | Low | Chunk batch upserts (100 rows) with idempotent keys `(date, taskId)`. |

## 9. Dependencies

- Phase 0 NestJS skeleton (`GET /v1/health`) is in place. ✅
- Phase 2 `drift` schema (`tasks`, `daily_logs`) is in place. ✅
- Phase 5 ships before this phase. ⚠️ Verify on branch creation.

## 10. References

- `spec/roadmap.md` — Phase 6 entry.
- `spec/mission.md` — principles #1, #2, #4, #6.
- `spec/tech-stack.md` — Auth Strategy, Data Model, Backend section.
