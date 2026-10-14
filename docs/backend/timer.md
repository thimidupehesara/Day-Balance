# Timer Module
Status: DONE
Location: `/backend/src/modules/timer/`
Verified: Live HTTP end-to-end test in `backend/src/scripts/test-core-flow.ts` and unit tests in `src/tests/timer-math.test.ts` against Neon PostgreSQL.

## Exact Rules Implemented

1. **Server Time as Source of Truth**:
   The server's current timestamp `now = new Date()` is the sole authority for start, pause, and resume. Every timer response returns `serverTime` (ISO 8601 string) allowing client applications to calculate drift and render per-second countdowns accurately.
2. **Atomic Auto-Pause & Single Running Timer Invariant (Rule 4)**:
   Starting a timer sets `started_at = now`, inserts a new open `time_entries` record, and automatically pauses any other currently running timer for that user—all within ONE database transaction (`db.transaction`).
   - Concurrency serialization: Uses row-level locking (`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`) within the transaction to serialize simultaneous requests for the same user.
   - Database backstop: Partial unique index `plan_items_one_running_timer` (`UNIQUE(user_id) WHERE started_at IS NOT NULL`) guarantees at the database level that no two timers can ever run simultaneously for a single user.
3. **Pause & Overtime (Rule 5)**:
   Pausing computes `elapsedSeconds = max(0, floor((now - started_at) / 1000))` and updates `remaining_seconds = remaining_seconds - elapsedSeconds`, clears `started_at = null`, and updates open `time_entries` with `ended_at = now`.
   - `remaining_seconds` is stored as a signed 32-bit integer and CAN BE NEGATIVE.
   - Negative remaining seconds represent **overtime**. The response returns `isOvertime: true` and `overtimeSeconds: abs(remaining_seconds)`.
4. **Editing Planned Seconds while Timer Runs (Rule 6)**:
   When a plan is updated while an item's timer is actively running, `remaining_seconds` is adjusted by `newPlanned - oldPlanned`, and `started_at` is preserved intact. The running timer is not restarted or reset.
5. **Timer Past Midnight (Rule 7)**:
   Timers calculate elapsed duration via millisecond timestamps (`now.getTime() - startedAt.getTime()`). A timer that runs past midnight continues counting toward the daily plan and plan item it started on; it does not reset or migrate across days.
6. **Cross-User Security Isolation (Rule 9)**:
   All timer endpoints verify that the target `planItemId` belongs to the authenticated user. Any attempt by user B to start or pause user A's timer returns HTTP 404 (`Plan item not found`).
7. **Edge Cases Handled (Rule 10)**:
   - **Idempotent Start**: Calling `POST /api/timer/start` on an already running item returns HTTP 200 with `isAlreadyRunning: true` without creating duplicate time entries or modifying `started_at`.
   - **Clear Error on Non-Running Pause**: Calling `POST /api/timer/pause` when no timer is active returns HTTP 400 (`No active timer is currently running`). If a specific `planItemId` is passed that is not running, returns HTTP 400 (`Plan item is not currently running`).
   - **Past-Day Protection**: Attempting to start a timer for a plan whose `planDate < today` returns HTTP 400 (`Cannot start timer for a past date's plan`).

---

## Endpoints, Request & Response Examples

### 1. Start Timer (with Auto-Pause)
- **Route**: `POST /api/timer/start`
- **Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "planItemId": "11111111-2222-3333-4444-555555555555"
}
```
- **Response (200 OK)**:
```json
{
  "message": "Timer started successfully",
  "data": {
    "activeItem": {
      "id": "11111111-2222-3333-4444-555555555555",
      "dailyPlanId": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
      "categoryId": "career",
      "categoryName": "Career",
      "categoryDescription": "Work, projects, professional development",
      "categoryColor": "#E07A5F",
      "categoryIcon": "work",
      "plannedSeconds": 7200,
      "remainingSeconds": 7200,
      "startedAt": "2026-10-14T13:29:40.065Z"
    },
    "autoPausedItem": {
      "id": "22222222-3333-4444-5555-666666666666",
      "dailyPlanId": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
      "categoryId": "academic",
      "categoryName": "Academic",
      "categoryDescription": "Studies, homework, research, lectures",
      "categoryColor": "#4A6FA5",
      "categoryIcon": "school",
      "plannedSeconds": 7200,
      "remainingSeconds": 7193,
      "startedAt": null
    },
    "serverTime": "2026-10-14T13:29:40.065Z",
    "isAlreadyRunning": false
  },
  "serverTime": "2026-10-14T13:29:40.065Z"
}
```

### 2. Pause Timer
- **Route**: `POST /api/timer/pause`
- **Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Request Body**: `{ "planItemId": "11111111-2222-3333-4444-555555555555" }` (or empty `{}` to pause whichever item is running)
- **Response (200 OK)**:
```json
{
  "message": "Timer paused successfully",
  "data": {
    "pausedItem": {
      "id": "11111111-2222-3333-4444-555555555555",
      "dailyPlanId": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
      "categoryId": "career",
      "categoryName": "Career",
      "categoryDescription": "Work, projects, professional development",
      "categoryColor": "#E07A5F",
      "categoryIcon": "work",
      "plannedSeconds": 7200,
      "remainingSeconds": 7194,
      "startedAt": null
    },
    "elapsedSeconds": 6,
    "isOvertime": false,
    "overtimeSeconds": 0,
    "serverTime": "2026-10-14T13:29:46.081Z"
  },
  "serverTime": "2026-10-14T13:29:46.081Z"
}
```

### 3. Pause Timer (Overtime Example)
- **Response (200 OK)** when elapsed exceeds remaining:
```json
{
  "message": "Timer paused successfully",
  "data": {
    "pausedItem": {
      "id": "11111111-2222-3333-4444-555555555555",
      "remainingSeconds": -3611,
      "startedAt": null
    },
    "elapsedSeconds": 10811,
    "isOvertime": true,
    "overtimeSeconds": 3611,
    "serverTime": "2026-10-14T13:30:00.000Z"
  },
  "serverTime": "2026-10-14T13:30:00.000Z"
}
```

### 4. Resume Timer
- **Route**: `POST /api/timer/resume`
- **Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Request Body**: `{ "planItemId": "11111111-2222-3333-4444-555555555555" }`
- **Response (200 OK)**: Delegates to `startTimer`, setting `started_at = now()`, resuming countdown with previously saved `remaining_seconds`.

### 5. Get Timer Status
- **Route**: `GET /api/timer/status?date=YYYY-MM-DD`
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**:
```json
{
  "data": {
    "serverTime": "2026-10-14T13:30:02.569Z",
    "planId": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
    "planDate": "2026-10-14",
    "activeItem": {
      "id": "11111111-2222-3333-4444-555555555555",
      "categoryId": "career",
      "categoryName": "Career",
      "plannedSeconds": 9000,
      "remainingSeconds": 8986,
      "startedAt": "2026-10-14T13:32:00.000Z"
    },
    "items": [ ... ]
  },
  "serverTime": "2026-10-14T13:30:02.569Z"
}
```

---

## Error Codes

| Status | Error Message | Description |
|---|---|---|
| `400 Bad Request` | `No active timer is currently running` | Paused called without active timer |
| `400 Bad Request` | `Plan item is not currently running` | Paused called on a specific item that isn't running |
| `400 Bad Request` | `Cannot start timer for a past date's plan` | Attempted to start timer on historical plan |
| `401 Unauthorized` | `Missing or invalid token` | Unauthenticated request or expired token |
| `404 Not Found` | `Plan item not found` | Item ID does not exist or belongs to another user |

---

## Done
- [x] Server time as source of truth with `serverTime` ISO string on every timer response
- [x] Single running timer invariant enforced via DB transaction and `SELECT ... FOR UPDATE` row lock on user
- [x] Auto-pause running timer when starting another item within the same transaction
- [x] Idempotent start on already running item
- [x] Pause timer: deduct elapsed, allow negative remaining_seconds (overtime), close time entry
- [x] Clear error (400) when pausing an item that is not running
- [x] Timer running past midnight math keeps counting on the plan it started on
- [x] Supported `POST /api/timer/resume` route
- [x] Security: verified user ownership on all endpoints (404 for unauthorized cross-user access)
- [x] Unit tests for timer math and concurrency / midnight crossing (13/13 passing in `src/tests/timer-math.test.ts`)
- [x] Live HTTP verification in `backend/src/scripts/test-core-flow.ts` passed 14/14 checks against Neon PostgreSQL
