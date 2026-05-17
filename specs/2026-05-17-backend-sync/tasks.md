# Tasks: Phase 6 — Backend & Optional Sync

**Input**: `specs/2026-05-17-backend-sync/{requirements.md, plan.md, validation.md}`
**Branch**: `phase-6/backend-sync`

## Phase 1: Group 1 — Auth End-to-End (US1)

**Goal**: Register, login, refresh JWT; Flutter sign-in/up with secure token storage.

**Independent Test**: Manual checklist § Auth Flows in `validation.md`.

- [x] T001 [US1] Add `User` model to `api/prisma/schema.prisma` and create migration
- [x] T002 [US1] Install auth deps and implement `api/src/auth/` (register, login, refresh, JWT strategy, guard) in `api/src/app.module.ts`
- [x] T003 [US1] Add JWT env vars to `api/.env.example` and validate secrets at bootstrap in `api/src/main.ts`
- [x] T004 [P] [US1] Add `dio` and `flutter_secure_storage` to `app/pubspec.yaml`
- [x] T005 [US1] Implement `app/lib/core/api/` (Dio client, auth interceptor, config) and `app/lib/features/auth/data/` (token storage, auth repository)
- [x] T006 [US1] Add `authStateProvider` and sign-in/sign-up screens under `app/lib/features/auth/presentation/`
- [x] T007 [US1] Wire auth routes and redirect guard in `app/lib/core/routing/app_router.dart`; account section in settings

## Phase 2: Group 2 — Tasks CRUD (US2)

**Goal**: `GET/POST /v1/tasks`; Flutter uses server catalog when signed in.

**Independent Test**: Manual checklist § Tasks API in `validation.md`.

- [x] T008 [US2] Add `Task` model + seed script in `api/prisma/` and `TasksModule` in `api/src/tasks/`
- [x] T009 [US2] Implement `RemoteTaskRepository` in `app/lib/features/checklist/data/remote_task_repository.dart`
- [x] T010 [US2] Update `task_catalog_provider` / `task_repository_provider` for signed-in server fetch with local fallback

## Phase 3: Group 3 — Logs CRUD (US3)

**Goal**: `PUT/GET /v1/logs` with LWW; Flutter pushes completions when authenticated.

**Independent Test**: Manual checklist § Logs API in `validation.md`.

- [x] T011 [US3] Add `DailyLog` model and `LogsModule` with LWW upsert in `api/src/logs/`
- [x] T012 [US3] Implement `RemoteLogRepository` in `app/lib/features/checklist/data/remote_log_repository.dart`
- [x] T013 [US3] Update checklist provider to push log changes when signed in and online

## Phase 4: Group 4 — Sync Queue & Deployment (US4)

**Goal**: Offline queue, merge on first sign-in, Docker compose.

**Independent Test**: Manual checklist § Sync + Deployment in `validation.md`.

- [x] T014 [US4] Add `sync_queue` Drift table and migration in `app/lib/core/db/`
- [x] T015 [US4] Implement `SyncService` and `MergeService` in `app/lib/features/sync/`
- [x] T016 [US4] Wire sync lifecycle on sign-in/sign-out in `app/lib/main.dart`
- [x] T017 [P] [US4] Add `api/Dockerfile`, root `docker-compose.yml`, extend `api/.env.example`

## Dependencies

```
US1 (Auth) → US2 (Tasks) ─┐
           → US3 (Logs)  ─┼→ US4 (Sync + Docker)
```

## Implementation Strategy

1. Complete US1 end-to-end and validate auth flows.
2. US2 and US3 in parallel after US1.
3. US4 last (depends on all APIs).
