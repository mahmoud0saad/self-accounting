# Phase 0 — Foundations · Requirements

> **Roadmap reference:** [`spec/roadmap.md`](../../spec/roadmap.md) — Phase 0 (Foundations, 3 days).
> **Guiding docs:** [`spec/mission.md`](../../spec/mission.md), [`spec/tech-stack.md`](../../spec/tech-stack.md).

## 1. Goal
Stand up an empty-but-runnable Flutter client and an empty NestJS API, organised in a monorepo, with linting and a minimal CI pipeline. Nothing functional yet — the deliverable is a **skeleton that all later phases bolt onto**.

## 2. Phase Exit Criteria (from roadmap)
- The Flutter app launches to an **empty themed home screen** on Android, iOS, and Web.
- The API responds successfully to `GET /v1/health`.

## 3. In Scope

### 3.1 Monorepo structure
- Top-level layout:
  - `/app` — Flutter project (Android + iOS + Web targets enabled).
  - `/api` — NestJS project (TypeScript + Prisma).
  - `/spec` — existing constitution docs (mission, tech-stack, roadmap).
  - `/specs` — per-feature working folders (this folder lives here).
  - `/.github/workflows` — CI definitions.
  - Root `README.md` updated with monorepo orientation + bootstrap commands.
- Root-level `.gitignore`, `.editorconfig`.

### 3.2 Flutter client (`/app`)
- Fresh `flutter create` with Android, iOS, Web platforms enabled.
- Dart 3.x, Flutter stable channel.
- Material 3 enabled with a soft-green seed color (per mission "calm by design").
- Default typography scale; no custom font assets in this phase.
- Set up the Flutter app's code skeleton using a **Clean Architecture** folder structure in `/app`:
  - Under `lib/features/home/`, create the `data/`, `domain/`, and `presentation/` folders, even if initially empty.
  - Place the initial `HomeScreen` widget in `lib/features/home/presentation/`.
  - The `main.dart` file sets up and launches the app, initializing `go_router` with a single route to `HomeScreen`, referencing the presentation layer.
- Add and configure the `go_router` dependency, wiring routing in a way that new feature routes can be easily added under their own feature folders in the future.
- Enable `flutter_lints`.
- No business or data logic is required yet, but the complete skeleton for Clean Architecture is in place, so later features can be properly layered.

### 3.3 NestJS API (`/api`)
- Fresh `nest new` with TypeScript.
- Versioned routing under `/v1` (global prefix).
- `HealthController` exposing `GET /v1/health` → `200 OK` with JSON `{ "status": "ok", "uptime": <seconds>, "db": "up" | "down" }`.
- Prisma installed; `schema.prisma` initialised with a minimal placeholder model (e.g. `HealthCheck`) so migrations run cleanly. Real domain models land in Phase 2 / Phase 6.
- `.env.example` documenting `DATABASE_URL` for local MySQL.
- ESLint + Prettier configured (NestJS defaults are fine).

### 3.4 Local development (Docker Compose)
- Root `docker-compose.yml` provisioning **MySQL 8** with a named volume and a default dev database.
- One-command local boot: `docker compose up -d` then `npm --prefix api run prisma:migrate:dev` brings the schema up.
- `/v1/health` performs a lightweight Prisma `$queryRaw 'SELECT 1'` to surface DB connectivity in the `db` field.

### 3.5 CI (GitHub Actions, minimal)
- **One workflow** triggered on `push` and `pull_request` to `master` and `feature/**` branches.
- Two parallel jobs, both **lint + format check only**:
  - `app-lint`: sets up Flutter stable, runs `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`.
  - `api-lint`: sets up Node LTS, runs `npm ci`, `npm run lint`, `npm run format:check`.
- No build matrix, no tests, no Docker image build in this phase (deferred per decision below).

## 4. Out of Scope (explicitly deferred)
- Any task data, checklist UI, or persistence (→ Phase 1 / 2).
- Auth, JWT, user accounts (→ Phase 6).
- Riverpod state, repositories, `drift` SQLite (→ Phase 2).
- Notifications (→ Phase 5).
- Charts and dashboards (→ Phase 4).
- Full CI matrix (Android/iOS/Web builds, Docker image, tests) (→ later phases).
- Dark mode, Arabic copy, RTL audit (→ post-MVP polish).
- Sentry, error tracking (→ post-MVP).

## 5. Decisions Recorded This Phase
| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Branch / PR shape | Flutter **and** NestJS scaffolded together in **one** feature branch / PR | Skeleton is small; reviewing both halves side-by-side avoids drift |
| D2 | MySQL provisioning | `docker-compose.yml` with MySQL 8 + Prisma migration that creates the schema | One-command local boot keeps onboarding ≤ 5 minutes |
| D3 | CI ambition | Lint + format check only on both `/app` and `/api` | Phase 0 is structural; cheap CI keeps PR feedback fast, build matrix added when there's real code to build |
| D4 | Theme depth | Material 3 seed color (soft green) + default typography only | Honors mission "calm by design" without over-investing before real screens exist |
| D5 | API versioning | Global `/v1` prefix from day one | Matches tech-stack contract; no churn later |
| D6 | Health endpoint shape | Returns `status`, `uptime`, `db` fields | `db` field exercises the Prisma wiring so a misconfigured `.env` fails loudly on day one |

## 6. Context & Assumptions
- Developer has Docker Desktop, Flutter stable, and Node.js LTS installed locally.
- No production deploy in Phase 0 — `docker-compose.yml` is **dev-only**.
- The branch follows the convention `feature/phase-<n>-<slug>` (this branch: `feature/phase-0-foundations`).
- This spec folder (`specs/2026-05-11-foundations/`) is the source of truth for this feature; it will be referenced from the PR description.

## 7. Risks / Open Questions
- **R1:** iOS build on Flutter requires macOS for full verification. CI is lint-only this phase, so this is acceptable — full iOS build moves to a later phase.
- **R2:** MySQL 8 on Windows hosts can be slow on first boot; docs in root README will note the expected ~30–60s first-time provisioning.
- **R3:** Prisma's MySQL provider requires a `SHADOW_DATABASE_URL` for some workflows; we will configure it in `.env.example` if `prisma migrate dev` complains during validation.
