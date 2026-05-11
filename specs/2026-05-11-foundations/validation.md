# Phase 0 — Foundations · Validation

> This phase merges when **every** check below passes. Most checks are manual at this stage (skeleton phase, no real features to assert). Each check has a verification command or observable.

## 1. Roadmap exit criteria

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V1 | Flutter app launches to an empty themed home screen on **Web** | `cd app && flutter run -d chrome` | Browser opens, no analyzer errors, AppBar title visible, soft-green Material 3 palette obvious |
| V2 | Flutter app launches to an empty themed home screen on **Android** | `cd app && flutter run -d <android-emulator-id>` | App opens on emulator, same home screen as V1 |
| V3 | Flutter app launches to an empty themed home screen on **iOS** | `cd app && flutter run -d <ios-simulator-id>` (macOS only) | App opens on simulator, same home screen as V1. If reviewer is on Windows, mark "deferred — no macOS" in PR and link a clean `flutter build ios --no-codesign` log instead |
| V4 | API responds to `GET /v1/health` | With API running locally: `curl -i http://localhost:3000/v1/health` | HTTP 200 and body `{ "status": "ok", "uptime": <number>, "db": "up" }` |

## 2. Local dev environment (Docker Compose path)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V5 | One-command DB boot | From repo root on a clean machine: `docker compose up -d` | Container `db` reports healthy within 60s (`docker compose ps`) |
| V6 | Prisma migration runs cleanly | `npm --prefix api ci && npm --prefix api run prisma:migrate:dev -- --name init` | Migration applies without errors; `prisma migrate status` reports `Database schema is up to date` |
| V7 | API surfaces real DB state in health | Stop the DB container (`docker compose stop db`), hit `/v1/health` again | Response is still HTTP 200 (or a controlled 503) and `db` field is `"down"` — endpoint does **not** crash with 500 |
| V8 | `.env.example` is sufficient | Fresh clone path: copy `.env.example` → `.env`, run the boot sequence end-to-end | API reaches `db: "up"` without any extra env tweaks |

## 3. Repository hygiene

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V9 | Monorepo layout matches `requirements.md §3.1` | `ls` at repo root | `/app`, `/api`, `/spec`, `/specs`, `/.github`, `docker-compose.yml`, `README.md` all present |
| V10 | Root README explains bootstrap | Read `README.md` | Contains prerequisites (Docker, Flutter, Node versions) and the exact boot sequence from `plan.md §3.2` |
| V11 | `.gitignore` covers Flutter + Node + Prisma + IDE | Inspect file | Excludes `app/build/`, `app/.dart_tool/`, `api/node_modules/`, `api/dist/`, `api/.env`, `.idea/`, `.vscode/` (except shared bits), `.DS_Store` |

## 4. CI gates

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V12 | `app-lint` job green on the PR | GitHub Actions tab on the PR | `flutter analyze` reports `No issues found!` and `dart format` exits 0 |
| V13 | `api-lint` job green on the PR | GitHub Actions tab on the PR | `eslint` exits 0 and `prettier --check` exits 0 |
| V14 | CI fails fast on lint regressions | Locally introduce a formatting violation, push to a throwaway branch | The relevant job fails with a clear diff |

## 5. Code quality bar (manual review)

| # | Criterion | How to verify | Pass when |
|---|---|---|---|
| V15 | No business logic leaked into Phase 0 | Diff review of the PR | No checklist data, no task models, no Riverpod state, no auth code — those belong to later phases |
| V16 | Theme uses Material 3 + `ColorScheme.fromSeed` | Inspect `app/lib/main.dart` (or theme file) | `useMaterial3: true` and a soft-green seed color, not a hard-coded palette |
| V17 | API versioning works | Hit `GET /health` (without `/v1`) | Returns 404 — confirms global `/v1` prefix is enforced |
| V18 | Decisions D1–D6 in `requirements.md` are reflected | Diff review | Each decision is observable in code or config |

## 6. Definition of Done (merge gate)

The PR is mergeable when:

- [ ] V1, V2, V4 pass on the reviewer's machine.
- [ ] V3 passes **or** is explicitly marked deferred in the PR description with a clean iOS build log link.
- [ ] V5 – V8 (Docker Compose + Prisma + health) pass end-to-end.
- [ ] V9 – V11 (repo hygiene) confirmed by reviewer.
- [ ] V12 – V14 (CI) are green and the workflow has actually run on this PR.
- [ ] V15 – V18 (quality bar) confirmed in code review.
- [x] Root README "Status" line reads `Phase 0 ✅ — runnable skeleton`.
- [ ] No new dependencies added beyond those listed in `requirements.md §3.2` and `§3.3` without an inline justification in the PR description.

When all boxes are checked: **squash-merge to `master`** and proceed to Phase 1 (Static Daily Checklist).
