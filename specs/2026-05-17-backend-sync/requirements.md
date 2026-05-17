# Requirements — Phase 6: Backend & Optional Sync

## Goal

Power-users can sync their daily checklist data across devices via an optional
sign-in flow. The app remains fully functional offline; cloud sync is an
opt-in upgrade.

---

## Scope

### In Scope

| Area | Details |
|------|---------|
| Auth (API) | Email/password registration & login, JWT access + refresh token pair, token refresh endpoint. |
| Auth (Flutter) | Optional sign-in / sign-up screens, token storage via `flutter_secure_storage`, Dio interceptor for Authorization header & silent refresh. |
| Tasks API | `GET /v1/tasks` (list catalog), `POST /v1/tasks` (create custom — future-proofing for Phase 7). |
| Logs API | `PUT /v1/logs` (upsert completion), `GET /v1/logs?from=&to=` (query by date range). |
| Data merge | On first sign-in, push all local SQLite data to the server under the new `user_id`. |
| Sync queue | Offline writes are queued locally and replayed to the server when connectivity is restored. |
| Conflict resolution | Last-write-wins keyed on `(user_id, date, task_id)` using an `updated_at` timestamp. |
| Deployment | Dockerised NestJS app deployable to a VPS (e.g. DigitalOcean droplet). |

### Out of Scope (deferred)

- Google OAuth (deferred to a later phase).
- Real-time / WebSocket push sync.
- Automated test suite as a merge gate (manual checklist only for this phase).
- BullMQ / Redis background jobs (backlog).
- Task customisation CRUD UI (Phase 7).

---

## Key Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **Email/password only** — no Google OAuth this phase. | Reduces scope; OAuth adds mobile deep-link complexity. Ship core sync first. |
| D2 | **Last-write-wins (LWW)** conflict resolution. | Simplest correct strategy for single-user multi-device. Keyed on `(user_id, date, task_id)` with `updated_at` as tiebreaker. |
| D3 | **Docker on VPS** deployment target. | Low cost, full control, matches team familiarity. Managed PaaS can be evaluated later. |
| D4 | **Anonymous mode remains default.** | Aligns with mission principle "the user owns their data" and "local-first". Sign-in is never required. |
| D5 | **Merge-on-sign-in, not replace.** | First sign-in pushes local data to the server. No data is lost. Subsequent sign-ins on new devices pull server state. |
| D6 | **JWT stored in `flutter_secure_storage`.** | Platform keychain/keystore — no plaintext tokens. Refresh token enables silent re-auth. |

---

## Context & References

### Mission Alignment

This phase upholds the following principles from [mission.md](../mission.md):

- **"The user owns their data."** — Local-first; sync is explicit and optional.
- **"Privacy."** — No third-party analytics; auth data stays between client and our API.
- **"Frictionless logging."** — Sync happens silently in the background; no user action needed after initial sign-in.

### Tech Stack Alignment

From [tech-stack.md](../tech-stack.md):

| Concern | Stack choice used |
|---------|-------------------|
| API framework | NestJS + TypeScript |
| ORM | Prisma + MySQL 8.x |
| Auth | JWT (access + refresh), `class-validator` at boundaries |
| Client HTTP | Dio + interceptors |
| Local DB | Drift (SQLite) — sync queue lives here |
| Secure storage | `flutter_secure_storage` |
| API versioning | REST under `/v1` |

### Data Model Additions

```
users
  id          UUID   PK
  email       String UNIQUE
  password    String (bcrypt hash)
  created_at  DateTime
  updated_at  DateTime

sync_queue (client-side, Drift)
  id          Integer PK autoincrement
  entity      String  ('log' | 'task')
  entity_id   String
  action      String  ('upsert' | 'delete')
  payload     String  (JSON)
  created_at  DateTime
  synced      Boolean default false
```

The existing `tasks` and `daily_logs` tables gain an optional `server_id`
column and `updated_at` timestamp to support LWW merge.
