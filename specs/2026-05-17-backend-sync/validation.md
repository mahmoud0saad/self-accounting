# Validation — Phase 6: Backend & Optional Sync

> Manual checklist + a concrete demo walkthrough.
> All items must pass before the phase can be considered complete and merged.

---

## Manual Test Checklist

### Auth Flows

- [ ] **Register** — `POST /v1/auth/register` with valid email + password returns 201 and a token pair.
- [ ] **Duplicate register** — same email returns 409 Conflict.
- [ ] **Login** — `POST /v1/auth/login` with correct credentials returns 200 and a token pair.
- [ ] **Bad credentials** — wrong password returns 401 Unauthorized.
- [ ] **Token refresh** — `POST /v1/auth/refresh` with a valid refresh token returns a new token pair.
- [ ] **Expired access token** — API call with expired access token returns 401; Dio interceptor silently refreshes and retries.
- [ ] **Expired refresh token** — refresh attempt returns 401; Flutter signs the user out locally and redirects to sign-in screen.
- [ ] **Flutter sign-up screen** — form validates email format and minimum password length; shows inline errors.
- [ ] **Flutter sign-in screen** — successful login navigates to home; tokens are persisted in secure storage.
- [ ] **Sign-out** — clears tokens from secure storage; app returns to anonymous/local-only mode. Local data is preserved.

### Tasks API

- [ ] **List tasks** — `GET /v1/tasks` (authenticated) returns the default catalog + any user-custom tasks.
- [ ] **Create custom task** — `POST /v1/tasks` with valid payload returns 201 and the created task.
- [ ] **Unauthenticated access** — `GET /v1/tasks` without a token returns 401.
- [ ] **Flutter provider** — when signed in, the task list reflects server data; when signed out, it uses local Drift data.

### Logs API

- [ ] **Upsert log** — `PUT /v1/logs` with `{ date, task_id, completed, updated_at }` creates or updates the record.
- [ ] **LWW enforcement** — sending an older `updated_at` does not overwrite a newer server record.
- [ ] **Query by range** — `GET /v1/logs?from=2026-05-01&to=2026-05-17` returns only logs in that range.
- [ ] **Flutter provider** — completing a task while signed in pushes the change to the server.

### Sync Queue (Offline Writes)

- [ ] **Queue on offline** — disable network; complete a task in Flutter; verify a row is added to the local `sync_queue` table.
- [ ] **Replay on reconnect** — restore network; verify the queued mutation is pushed to the server automatically.
- [ ] **FIFO order** — queue multiple offline mutations; verify they replay in creation order.
- [ ] **Retry on failure** — simulate a server error (e.g. kill the API); verify the sync service retries with backoff and eventually succeeds.
- [ ] **Idempotency** — replaying the same mutation twice does not create duplicate records (upsert semantics).

### Conflict Resolution

- [ ] **Two-device conflict** — complete a task on Device A (timestamp T1), then complete a different set on Device B (timestamp T2 > T1). Sync both. Verify the server holds T2's state for conflicting records.
- [ ] **Pull reconciliation** — after server has newer data, pulling on Device A updates local records to match.

### Data Merge on First Sign-In

- [ ] **Local data preserved** — use the app offline for several days, accumulating logs. Sign up. Verify all local logs appear on the server.
- [ ] **No duplicates** — sign in on a second device; pull does not create duplicate log entries.
- [ ] **Empty local + existing server** — fresh install, sign in to an account that already has data. Verify local DB is populated from server.

### Deployment

- [ ] **Docker build** — `docker compose up` starts the NestJS app + MySQL without errors.
- [ ] **Health check** — `GET /v1/health` returns 200 from the containerised app.
- [ ] **Environment config** — `.env.example` documents all required variables; app refuses to start if `JWT_SECRET` is missing.

---

## Demo Walkthrough Scenario

This end-to-end scenario validates the complete sync flow across devices.

### Prerequisites

- NestJS API running (Docker or local).
- Flutter app built for Android (or emulator) and Web.
- A MySQL database reachable by the API.

### Steps

1. **Fresh install on Android** — launch the app. No account exists. The app
   shows the daily checklist in anonymous/local-only mode.

2. **Use the app offline** — toggle airplane mode. Complete several tasks
   (e.g. Fajr prayer, morning Adhkar). Verify the progress bar updates and
   data persists across app restarts.

3. **Sign up** — restore connectivity. Navigate to the sign-up screen. Register
   with an email and password. The app should:
   - Create the account on the server.
   - Push all locally accumulated logs to the server (merge-on-sign-in).
   - Transition to authenticated mode (no visible disruption to the checklist).

4. **Verify server state** — using curl or Postman, call
   `GET /v1/logs?from=2026-05-01&to=2026-05-17` with the user's access token.
   Confirm the response contains the same logs that were created locally.

5. **Open the web build** — launch the Flutter web app in a browser. Sign in
   with the same email and password. The checklist should show identical
   completion state as the Android device.

6. **Cross-device edit** — on the web, complete an additional task. Switch to
   the Android app. Pull/sync should reflect the new completion within a few
   seconds.

7. **Offline queue test** — on Android, enable airplane mode. Complete two
   more tasks. Re-enable connectivity. Verify the queued mutations sync to
   the server and the web build reflects them after a refresh.

8. **Sign out** — on Android, sign out. Verify:
   - Tokens are cleared.
   - Local data is still visible (app falls back to local-only mode).
   - The app does not attempt to sync.

### Pass Criteria

All eight steps complete without errors. Data is consistent across devices
at every checkpoint. No data loss occurs during merge, sync, or sign-out.
