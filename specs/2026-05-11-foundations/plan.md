# Phase 0 — Foundations · Plan

> Numbered task groups. Each group is self-contained, ordered for least-rework. Tick boxes are intended; PRs may collapse adjacent groups but should not reorder.

---

## 1. Repository scaffold

1.1. Add root-level `.gitignore` covering Flutter, Node, Prisma, IDE, OS files.
1.2. Add root-level `.editorconfig` (LF, UTF-8, 2-space for JS/TS, follow Dart defaults for `.dart`).
1.3. Create empty `/app` and `/api` directories with placeholder `README.md` in each.
1.4. Update root `README.md` with monorepo layout, prerequisites, and bootstrap commands (Docker, Flutter, Node versions).
1.5. Confirm `/spec` and `/specs` are committed and referenced from root README.

## 2. Backend skeleton (`/api`)

2.1. Run `npx @nestjs/cli new api --package-manager npm --strict` (executed from repo root so the project lands in `/api`).
2.2. Configure global URI versioning so all routes mount under `/v1` (in `main.ts`).
2.3. Generate a `health` module + controller + service:
   - `GET /v1/health` returns `{ status: "ok", uptime: number, db: "up" | "down" }`.
2.4. Install Prisma (`npm i -D prisma`, `npm i @prisma/client`), run `npx prisma init --datasource-provider mysql`.
2.5. Add a minimal placeholder model to `schema.prisma` (e.g. `HealthCheck { id Int @id @default(autoincrement()) checkedAt DateTime @default(now()) }`) so `prisma migrate dev` runs cleanly.
2.6. Inject `PrismaService` (thin wrapper around `PrismaClient`) and have `HealthService` run `await prisma.$queryRaw\`SELECT 1\`` to populate the `db` field.
2.7. Add `.env.example` with `DATABASE_URL="mysql://muhasabah:muhasabah@localhost:3306/muhasabah_dev"`.
2.8. Verify ESLint + Prettier defaults from NestJS template; add npm scripts `lint`, `format`, `format:check`.

## 3. Local DB provisioning (Docker Compose)

3.1. Author root `docker-compose.yml`:
   - Service `db`: image `mysql:8`, environment `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`.
   - Named volume `muhasabah_mysql_data` for persistence.
   - Healthcheck using `mysqladmin ping`.
   - Port `3306:3306` on localhost.
3.2. Smoke test the boot path:
   - `docker compose up -d`
   - `npm --prefix api ci`
   - `npm --prefix api run prisma:migrate:dev -- --name init`
   - `npm --prefix api run start:dev`
   - `curl http://localhost:3000/v1/health` → `{ "status": "ok", "db": "up", ... }`.
3.3. Document this exact sequence in root `README.md`.

## 4. Frontend skeleton (`/app`)

4.1. Run `flutter create app --org com.muhasabah --platforms=android,ios,web` from repo root.
4.2. Set min Android API to 21 and iOS deployment target to 13 (per tech-stack).
4.3. Add dependencies: `go_router` (latest stable). No other runtime deps in this phase.
4.4. Define a soft-green seed color (e.g. `Color(0xFF4C9A6E)`) and build the `ThemeData` via `ColorScheme.fromSeed(seedColor: ..., brightness: light)`, Material 3 enabled.
4.5. Replace generated counter sample with a single `HomeScreen`:
   - Scaffold + AppBar titled "Muhasabah".
   - Empty body (a centered subdued `Text("Welcome")` is acceptable).
4.6. Configure `go_router` with one `/` route → `HomeScreen`. Wire into `MaterialApp.router`.
4.7. Confirm `flutter_lints` is enabled in `analysis_options.yaml` (default from `flutter create` is fine).

## 5. Tooling polish

5.1. Add npm script `prisma:migrate:dev` in `/api/package.json` wrapping `prisma migrate dev`.
5.2. Add npm script `format:check` in `/api/package.json` (`prettier --check "src/**/*.ts"`).
5.3. Confirm `dart format --output=none --set-exit-if-changed .` runs clean from `/app`.

## 6. CI pipeline (GitHub Actions, minimal)

6.1. Create `.github/workflows/ci.yml` triggered on `push` and `pull_request` against `master` and `feature/**`.
6.2. Job `app-lint`:
   - `ubuntu-latest`, `subosito/flutter-action@v2` with stable channel.
   - Steps: `flutter pub get` (cwd `app`), `dart format --output=none --set-exit-if-changed .`, `flutter analyze`.
6.3. Job `api-lint`:
   - `ubuntu-latest`, `actions/setup-node@v4` with Node LTS + npm cache.
   - Steps: `npm ci` (cwd `api`), `npm run lint`, `npm run format:check`.
6.4. Both jobs run in parallel; the workflow fails if either fails. No DB service needed (lint only).

## 7. Manual verification on all three platforms (developer machine)

7.1. `flutter run -d chrome` from `/app` — themed home screen renders in browser.
7.2. With API running, hit `GET http://localhost:3000/v1/health` and confirm `db: "up"`.
7.3. Stop API, hit `/v1/health` again, confirm `db: "down"` (or that the endpoint surfaces the error rather than 500-ing).

## 8. Wrap-up & handoff

8.1. Re-read `validation.md`; tick every acceptance check.
8.2. Update root `README.md` with a "Status" line: `Phase 0 ✅ — runnable skeleton`.
8.3. Open PR `feature/phase-0-foundations → master`; paste a link to this `specs/2026-05-11-foundations/` folder in the description.
8.4. Squash-merge once CI is green and validation checks pass.
