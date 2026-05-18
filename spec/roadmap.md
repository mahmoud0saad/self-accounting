# Roadmap — Daily Self-Accountability App (Muhasabah)

Tiny phases (~3–5 days each). Each phase is independently shippable, demoable, and leaves the app in a working state. **MVP = end of Phase 5** (checklist + points + dashboard charts + notifications).

---

## Phase 0 — Foundations (3 days)
**Goal:** A runnable Flutter app and an empty NestJS API skeleton, both in CI.

- Initialize Flutter project (Android + iOS + Web targets).
- Initialize NestJS project with TypeScript, Prisma, MySQL connection string.
- Set up monorepo structure (`/app` Flutter, `/api` backend, `/spec` docs).
- Configure linting, formatting, and a basic GitHub Actions pipeline (build + test).
- Define the soft-green Material 3 theme + typography.

**Exit:** App launches to an empty themed home screen on all 3 platforms. API responds to `GET /v1/health`.

---

## Phase 1 — Static Daily Checklist (4 days)
**Goal:** Show the full daily checklist from the README, locally, with no persistence.

- Hard-code the default task catalog (Fajr → Misc Adhkar) with point values.
- Group tasks by category (Fajr, Dhuhr, Asr, Maghrib, Isha, Qiyam, Quran & Fasting, Misc).
- Render a scrollable, sectioned list with checkbox rows (1-tap toggle).
- Computed daily progress bar at top showing `(completed points / total points) × 100`.

**Exit:** User can tap tasks and see the % move. No data persists between launches.

---

## Phase 2 — Local Persistence with SQLite (4 days)
**Goal:** The checklist remembers today and yesterday.

- Add `drift` + SQLite schema for `tasks` and `daily_logs`.
- Seed default tasks on first launch.
- Persist task completions per day; auto-reset display at local midnight.
- Repository layer + Riverpod providers wired end-to-end.

**Exit:** Closing/reopening the app preserves today's progress. Switching days shows correct historical state.

---

## Phase 3 — History & Streaks (3 days)
**Goal:** Make consistency visible.

- 7-day strip on the home screen (color-coded by completion %).
- Current streak + longest streak counters.
- "On this day" navigation to view/edit past days (within a configurable window, e.g., 7 days).

**Exit:** User sees their last 7 days at a glance and a live streak counter.

---

## Phase 4 — Dashboard & Charts (4 days)
**Goal:** Weekly & monthly insights.

- Dedicated Dashboard screen with `fl_chart`:
  - Weekly bar chart of daily %.
  - Monthly heatmap (GitHub-contributions style).
  - Per-category breakdown (which categories the user excels at / neglects).
- Empty/loading states.

**Exit:** Dashboard renders meaningful charts from real local data.

---

## Phase 5 — Local Notifications (3 days) — **MVP shipped at end of this phase**
**Goal:** Gentle nudges, no backend required.

- User can enable/disable notifications per category.
- Default schedule covers the 5 prayer windows + morning/evening Adhkar + pre-sleep Adhkar.
- Times configurable via simple time pickers (no prayer-time API yet).
- End-of-day summary notification (e.g., 9:30 PM) if completion < 50%.

**Exit:** Notifications fire reliably on Android & iOS. **App is feature-complete for solo, offline use → public MVP release candidate.**

---

## Phase 6 — Backend & Optional Sync (5 days)
**Goal:** Power-users can sync across devices.

- Implement `/v1/auth` (email/password + Google OAuth), `/v1/tasks`, `/v1/logs` endpoints.
- Flutter: optional sign-in flow; on sign-in, merge local data → server.
- Sync queue: offline writes replay when online.
- Conflict resolution: last-write-wins on `(user_id, date, task_id)`.

**Exit:** A signed-in user can log on phone, open the web build, and see identical state.

---

## Phase 7 — Task Customization (4 days)
**Goal:** User-defined tasks and weights.

- CRUD UI for custom tasks (name, category, points, icon).
- Ability to hide/disable default tasks without deleting them.
- Validations: prevent negative points; cap per-task points to keep system balanced.
- Sync custom tasks if signed in.

**Exit:** Users can fully tailor their checklist to their own routine.

---

## Phase 8 — Weekly Challenges (4 days)
**Goal:** Add a layer of fresh motivation on top of the daily loop.

- Predefined challenge templates (e.g., "Read 1 Juz' this week", "Pray all Fajr in congregation").
- Custom user-defined challenges.
- Challenge progress widget on home + completion celebration.

**Exit:** First batch of challenges live; users can opt in/out weekly.

---

## Post-Roadmap (Backlog, not scheduled)
- Prayer-time API integration (Aladhan / IslamicFinder) to auto-shift notification times by location.
- Multi-language polish (Arabic copy review, RTL audit).
- Apple Watch / Wear OS quick-tick companion.
- Data export (CSV / JSON) for users to keep their own records.
- Themes (dark mode, additional calm palettes).

---

## Cadence Summary

| Phase | Duration | Cumulative | Milestone |
|---|---|---|---|
| 0 | 3 days | 3 d | Skeletons up |
| 1 | 4 days | 7 d | Checklist visible |
| 2 | 4 days | 11 d | Data persists |
| 3 | 3 days | 14 d | Streaks live |
| 4 | 4 days | 18 d | Dashboard live |
| **5** | **3 days** | **21 d** | **MVP shipped** |
| 6 | 5 days | 26 d | Cloud sync |
| 7 | 4 days | 30 d | Custom tasks |
| 8 | 4 days | 34 d | Challenges |

> ~3 weeks to MVP, ~5 weeks to full v1.0.
