Daily Self-Accountability App (Muhasabah) 📝

## Monorepo layout

- `/app`: Flutter client (Android, iOS, Web)
- `/api`: NestJS API (TypeScript + Prisma)
- `/spec`: project constitution docs (mission, tech stack, roadmap)
- `/specs`: per-feature specs (Phase 0 source of truth: `specs/2026-05-11-foundations/`)

## Prerequisites

- Flutter: stable (Dart 3.x)
- Node.js: LTS + npm
- Docker Desktop (for MySQL in dev)

## Bootstrap (Phase 0)

Exact sequence (see `specs/2026-05-11-foundations/plan.md` §3.2):

### 1. Local DB (MySQL 8)

From repo root:

```bash
docker compose up -d
```

On first MySQL volume creation, provisioning can take about **30–60 seconds**. Confirm the `db` service is healthy:

```bash
docker compose ps
```

### 2. API environment

```bash
cp api/.env.example api/.env
```

### 3. API install, migrate, run

```bash
npm --prefix api ci
npm --prefix api run prisma:migrate:dev -- --name init
npm --prefix api run start:dev
```

### 4. Health check

```bash
curl -i http://localhost:3000/v1/health
```

Expect `HTTP/1.1 200` and JSON including `"status":"ok"`, `"db":"up"` when MySQL is running.

### App (Flutter)

```bash
cd app
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter run -d chrome
```

## Status

Phase 0 ✅ — runnable skeleton

---

## Specs

Phase 0 source of truth lives in `specs/2026-05-11-foundations/`:

- `requirements.md`
- `plan.md`
- `validation.md`

