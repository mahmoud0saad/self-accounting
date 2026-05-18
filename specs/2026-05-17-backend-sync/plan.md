# Plan — Phase 6: Backend & Optional Sync

> 5-day budget · 4 feature-oriented task groups · ordered by dependency

---

## Group 1 — Auth End-to-End (~1.5 days)

Everything needed so a user can register, log in, and make authenticated
requests from the Flutter app.

### Backend

1.1. Add `users` table to Prisma schema (`id`, `email`, `password`, `created_at`, `updated_at`). Run migration against MySQL.

1.2. Create NestJS `AuthModule` with:
  - `POST /v1/auth/register` — validate email + password, bcrypt hash, create user, return token pair.
  - `POST /v1/auth/login` — verify credentials, return access + refresh JWT.
  - `POST /v1/auth/refresh` — accept refresh token, return new token pair.

1.3. Implement JWT strategy (Passport or manual guard) with access token (short-lived, ~15 min) and refresh token (long-lived, ~7 days).

1.4. Add `JwtAuthGuard` that protects all `/v1/*` routes except auth endpoints and `GET /v1/health`.

### Flutter

1.5. Create `AuthRepository` — register, login, refresh, logout methods using Dio.

1.6. Create Dio interceptor that:
  - Attaches `Authorization: Bearer <access_token>` to every request.
  - On 401, attempts silent refresh; on failure, signs user out locally.

1.7. Store tokens in `flutter_secure_storage` (access + refresh).

1.8. Build sign-in and sign-up screens (email + password fields, loading state, error display). Wire to `go_router` with a redirect guard.

1.9. Add Riverpod `authStateProvider` (signed-out / signing-in / signed-in) consumed by the UI shell.

---

## Group 2 — Tasks CRUD End-to-End (~1 day)

Expose the task catalog over the API and wire the Flutter client to prefer
server data when authenticated.

### Backend

2.1. Add `tasks` table to Prisma schema if not already present server-side (`id`, `name`, `category`, `points`, `is_default`, `user_id` nullable, `created_at`, `updated_at`).

2.2. Seed default task catalog via Prisma seed script (same data currently hard-coded in Flutter).

2.3. Create `TasksModule`:
  - `GET /v1/tasks` — return default tasks + user's custom tasks (auth required).
  - `POST /v1/tasks` — create a custom task (auth required, future-proofing for Phase 7).

### Flutter

2.4. Create `RemoteTaskRepository` implementing the same interface as the local Drift-based repository.

2.5. Update the tasks Riverpod provider to:
  - Use local-only when signed out.
  - Fetch from server and cache locally when signed in.
  - Fall back to local cache on network failure.

---

## Group 3 — Logs CRUD End-to-End (~1 day)

Sync daily completion logs between client and server.

### Backend

3.1. Add `daily_logs` table to Prisma schema (`id`, `user_id`, `date`, `task_id`, `completed`, `updated_at`). Unique constraint on `(user_id, date, task_id)`.

3.2. Create `LogsModule`:
  - `PUT /v1/logs` — upsert a completion record. Accepts `{ date, task_id, completed, updated_at }`.
  - `GET /v1/logs?from=YYYY-MM-DD&to=YYYY-MM-DD` — return logs in date range (auth required).

3.3. Ensure upsert respects `updated_at` for LWW: only overwrite if incoming `updated_at` > stored `updated_at`.

### Flutter

3.4. Create `RemoteLogRepository` — push completions, pull logs by date range.

3.5. Update the daily-log Riverpod provider to push changes to the server when authenticated and online.

3.6. Add `updated_at` column to the local Drift `daily_logs` table (migration).

---

## Group 4 — Sync Queue & Conflict Resolution (~1.5 days)

Offline-safe mutation queue and the first-sign-in data merge flow.

### Sync Queue (Flutter)

4.1. Add `sync_queue` table to Drift schema (`id`, `entity`, `entity_id`, `action`, `payload` JSON, `created_at`, `synced`).

4.2. Implement `SyncService`:
  - On any local write (task or log mutation), enqueue an entry if user is authenticated.
  - On connectivity restore (listen via `connectivity_plus`), replay un-synced entries in FIFO order.
  - Mark entries as synced on 2xx response; retry with exponential backoff on failure.

4.3. Wire `SyncService` into the app lifecycle (start on sign-in, pause on sign-out).

### First Sign-In Merge

4.4. Implement `MergeService`:
  - On first sign-in, read all local `daily_logs` and push to `PUT /v1/logs` in batches.
  - Server applies LWW — since this is the first sign-in, all local data wins.
  - Pull server task catalog and reconcile with local.

### Conflict Resolution

4.5. Server-side: the `PUT /v1/logs` upsert already respects `updated_at` (task 3.3). No additional server work.

4.6. Client-side: on pull, compare `updated_at` and keep the newer record locally.

### Deployment

4.7. Write `Dockerfile` + `docker-compose.yml` (NestJS app + MySQL service) for local dev and VPS deployment.

4.8. Add environment variable documentation (`.env.example`) for `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `PORT`.

---

## Dependency Graph

```
Group 1 (Auth) ──► Group 2 (Tasks CRUD) ──► Group 4 (Sync + Merge)
                ──► Group 3 (Logs CRUD)  ──►
```

Groups 2 and 3 are independent of each other but both depend on Group 1.
Group 4 depends on all prior groups.
