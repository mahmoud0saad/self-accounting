# Tech Stack — Daily Self-Accountability App (Muhasabah)

## Overview
A cross-platform Flutter client (Android, iOS, Web) backed by a MySQL-powered REST API. Authentication is **optional** — the app is local-first and works fully offline; signing in unlocks cross-device sync.

---

## Client (Frontend)

| Concern | Choice | Rationale |
|---|---|---|
| Framework | **Flutter** (stable channel) | Single codebase for Android + iOS + Web, matches README guidance. |
| Language | Dart 3.x | Sound null safety, records, pattern matching. |
| Min targets | Android 8.0 (API 26), iOS 13, evergreen browsers | Reasonable reach without supporting legacy. |
| State management | **Riverpod** (v2+) | Compile-safe, testable, scales from MVP to feature-rich app. |
| Routing | `go_router` | Declarative, deep-linking ready, web-friendly. |
| Local storage | **SQLite** via `drift` | Offline-first persistence of tasks, daily logs, points. |
| Secure storage | `flutter_secure_storage` | Tokens, refresh tokens (when signed in). |
| HTTP | `dio` + interceptors | Auth refresh, retry, logging. |
| Notifications | `flutter_local_notifications` | Local reminders for Adhkar / prayer windows. |
| Charts | `fl_chart` | Weekly / monthly progress visualizations. |
| Theming | Material 3 + custom soft-green palette | Calm, eye-friendly per mission. |
| i18n | `flutter_localizations` + ARB files | Arabic (RTL) + English from day one. |

### Architecture
- **Feature-first folder structure** (`lib/features/<feature>/{data,domain,presentation}`).
- **Clean-architecture lite**: repositories abstract local DB + remote API; UI consumes use-cases via Riverpod providers.
- **Offline-first writes**: all mutations write to SQLite immediately; a sync queue replays them to the API when authenticated and online.

---

## Backend (API)

| Concern | Choice | Rationale |
|---|---|---|
| Language / runtime | **Node.js (LTS) + TypeScript** | Fast iteration, strong typing, large ecosystem. |
| Framework | **NestJS** | Opinionated, modular, built-in validation/DTOs/DI, fits long-term growth. |
| Database | **MySQL 8.x** | Confirmed by README; relational fit for tasks ↔ logs ↔ users. |
| ORM | **Prisma** | Type-safe queries, painless migrations. |
| Auth | **JWT (access + refresh)** with optional email/password & Google OAuth | Optional account — anonymous use must remain a first-class path. |
| Validation | `class-validator` / Zod at boundaries | Defensive at the API edge. |
| Background jobs | BullMQ + Redis (Phase ≥ 5) | Streak recalculations, notification scheduling, weekly digest. |
| API style | **REST** (JSON), versioned under `/v1` | Simple, cache-friendly, well-supported by Flutter tooling. |
| Docs | OpenAPI 3 (auto-generated) | Source of truth for client codegen. |

### Data Model (v1 sketch)
- `users` — optional; created on first sign-in.
- `tasks` — catalog of default + user-custom tasks, each with a point value and category (Fajr, Dhuhr, Adhkar, etc.).
- `daily_logs` — one row per `(user_id, date, task_id)` indicating completion.
- `streaks` — derived/cached per user.
- `challenges` — optional weekly goals (Phase ≥ 6).

---

## Auth Strategy
- **Anonymous mode (default):** App generates a local `device_id`; all data lives in SQLite.
- **Optional sign-in:** User may attach an account at any time; local data is migrated/merged to the server under their `user_id`.
- **Sign-out** preserves local data but disables sync.

---

## DevOps & Tooling

| Concern | Choice |
|---|---|
| Source control | Git + GitHub |
| CI | GitHub Actions (Flutter build matrix + backend test + Docker image) |
| Backend deploy | Docker container → cloud VM or managed container service (decision deferred to Phase 5) |
| DB hosting | Managed MySQL (e.g., PlanetScale-compatible, AWS RDS, or DigitalOcean managed MySQL) |
| Error tracking | Sentry (client + server) |
| Linting | `flutter_lints`, ESLint + Prettier (backend) |
| Testing | `flutter_test` + `integration_test`; Jest for backend |

---

## Non-Goals (Tech)
- No GraphQL in v1 (REST keeps the client simple).
- No native modules (pure Flutter widgets where possible).
- No real-time/WebSocket features in v1.
- No third-party analytics SDKs on the client (privacy principle).
