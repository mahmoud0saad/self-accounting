Daily Self-Accountability App (Muhasabah) 📝


Daily Self-Accountability App (Muhasabah) 📝
1. App Overview
Purpose: An app designed to help users track their daily worship and actions through an interactive checklist.  

Gamification: The app relies on a points system to evaluate daily achievement and motivate consistency.  

2. Gamification & Progress System
Total Progress: Displayed at the top of the screen as a percentage (%).  

Calculation Mechanism:

Each task is assigned a specific number of points (e.g., 2 points for Sunnah prayers, 4 points for Quran reading).  

The progress is calculated as: (Total points of completed tasks / Total points of all tasks) × 100.  

3. Suggested Daily Checklist
  Fajr (Dawn) & Early Morning
Waking up Adhkar (2 points).  

Sunnah before Fajr (2 points).  

First Congregation (Jama’ah) (2 points).  

Post-prayer Adhkar (2 points).  

Morning Adhkar (2 points).  

Duha Prayer - 4 Rak'ahs (2 points).  

  Dhuhr (Noon)
Sunnah before Dhuhr - 4 Rak'ahs (2 points).  

First Congregation (Jama’ah) (2 points).  

Post-prayer Adhkar (2 points).  

Sunnah after Dhuhr (2 points).  

 Asr (Afternoon)
First Congregation (Jama’ah) (2 points).  

Post-prayer Adhkar (2 points).  

Evening Adhkar (2 points).  

  Maghrib (Sunset)
First Congregation (Jama’ah) (2 points).  

Post-prayer Adhkar (2 points).  

Sunnah after Maghrib (2 points).  
  Isha (Night)
First Congregation (Jama’ah) (2 points).  

Post-prayer Adhkar (2 points).  

Sunnah after Isha (2 points).  

  Qiyam al-Layl & Evening Devotion
Two Rak'ahs of Qiyam al-Layl (Night Prayer) (4 points).  

Daily Quran Portion (Wird) - Two quarters (4 points).  

Witr Prayer (1 point).  

Adhkar before sleep (2 points).  

  Quran & Fasting
Memorizing half a page (2 points).  

Reading six quarters (approx. 1.5 Juz') (2 points).  

Fasting (Monday and Thursday) (5 points).  

  Miscellaneous Adhkar (2 points per task)
Restroom Adhkar (Entering/Leaving).  

Clothing Adhkar (Putting on/Taking off).  

Wudu (Ablution) Adhkar.  

House Adhkar (Entering/Leaving).  

Mosque Adhkar (Entering/Leaving).  

Walking to the Mosque Adhkar.  

Eating and Drinking Adhkar.  

Riding/Traveling Adhkar.  

4. Suggested Technical Features
Dashboard: Display a graph showing the level of achievement over a week or a month.  

Smart Notifications: Send alerts for prayer times and Adhkar.  

Challenges: Ability to add a weekly challenge (e.g., completing a specific part of the Quran).  

Task Customization: Allow users to add their own tasks and assign custom points to them.  


5. Developer Notes
Database: mysql can be used to store the daily logs efficiently.  

Interface: A calm and comfortable design using eye-friendly colors, such as soft green by flutter .



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

Phase 1 ✅ — static daily checklist (EN + AR)

---

## Specs

Phase 0 source of truth lives in `specs/2026-05-11-foundations/`:

- `requirements.md`
- `plan.md`
- `validation.md`

Phase 1 source of truth lives in `specs/2026-05-12-static-daily-checklist/`:

- `requirements.md`
- `plan.md`
- `validation.md`
