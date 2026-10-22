# Plans Module
Status: DONE
Location: `/backend/src/modules/plans/`
Verified: Live HTTP end-to-end test in `backend/src/scripts/test-core-flow.ts` against Neon PostgreSQL.

## Exact Rules Implemented

1. **Server Time as Source of Truth**:
   Every plan response includes `serverTime` (ISO 8601 string, e.g. `2026-10-14T13:30:00.000Z`) so the client phone can detect and correct for clock drift.
2. **Server-Computed Waking Seconds**:
   `waking_seconds` is strictly computed by the server from the user's profile (`wake_time`, `bedtime`, and `routine_minutes`). Client-sent `wakingSeconds` is untrusted and ignored.
   - Calculation: `wakingSeconds = max(0, (grossWakingMinutes - routineMinutes) * 60)`.
   - Supports crossing midnight (e.g. 7 AM wake to 1 AM bedtime = 18h gross).
   - Fallback defaults if profile fields are null: wake `07:00:00`, bedtime `23:00:00`, routine `0`.
   - Planned seconds across all items must not exceed `waking_seconds` (HTTP 400 with clear message: `Total planned time (X s) cannot exceed available waking time (Y s)`).
   - Each item's `plannedSeconds` must be a multiple of 30 minutes (1800 s) and non-negative (HTTP 400).
3. **One Plan per User per Date (Idempotent Creation)**:
   The client sends `planDate` as `YYYY-MM-DD` (the user's local date). Creating a plan for a date that already has one returns the existing plan with HTTP 200 OK (`message: 'Plan already exists for this date, returning existing plan'`). This ensures complete idempotency and safety against network retries.
4. **Editing Planned Seconds While Timer Runs (Rule 6)**:
   When `PATCH /api/plans/:id` updates `plannedSeconds`:
   `newRemaining = oldRemaining + (newPlanned - oldPlanned)`.
   The `started_at` timestamp is untouched, preserving the running timer without restarting or resetting it.
5. **Planned vs Actual Summary (Rule 8)**:
   Actual time per category is the sum of its `time_entries` in PostgreSQL. An open entry (`ended_at IS NULL`) dynamically counts elapsed time up to server `now()`.
   Endpoints: `GET /api/plans/summary?date=YYYY-MM-DD` and `GET /api/plans/:id/summary`.
6. **Past-Day Plan Immutability (Rule 10)**:
   Plans for dates before today are historical records and cannot be modified. `PATCH /api/plans/:id` on a past-day plan returns HTTP 400 (`Cannot modify a plan from a past date`).
7. **Security & Ownership (Rule 9)**:
   All endpoints require a valid JWT Bearer token in the `Authorization` header. Any attempt by user B to read or modify user A's plan returns HTTP 404 (`Daily plan not found`).

---

## Endpoints, Request & Response Examples

### 1. Create Daily Plan
- **Route**: `POST /api/plans`
- **Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "planDate": "2026-10-14",
  "items": [
    { "categoryId": "academic", "plannedSeconds": 7200 },
    { "categoryId": "career", "plannedSeconds": 7200 },
    { "categoryId": "entertainment", "plannedSeconds": 3600 }
  ]
}
```
- **Response (201 Created)**:
```json
{
  "message": "Plan created successfully",
  "data": {
    "plan": {
      "id": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
      "userId": "e0b5b865-d033-4bba-83c6-b4a0a704ed91",
      "planDate": "2026-10-14",
      "wakingSeconds": 54000,
      "createdAt": "2026-10-14T13:29:29.327Z",
      "items": [
        {
          "id": "11111111-2222-3333-4444-555555555555",
          "dailyPlanId": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
          "categoryId": "academic",
          "categoryName": "Academic",
          "categoryDescription": "Studies, homework, research, lectures",
          "categoryColor": "#4A6FA5",
          "categoryIcon": "school",
          "plannedSeconds": 7200,
          "remainingSeconds": 7200,
          "startedAt": null
        }
      ],
      "isExisting": false
    },
    "serverTime": "2026-10-14T13:29:29.327Z"
  },
  "serverTime": "2026-10-14T13:29:29.327Z"
}
```
- **Duplicate Plan Response (200 OK)**:
```json
{
  "message": "Plan already exists for this date, returning existing plan",
  "data": { "plan": { ... }, "serverTime": "2026-10-14T13:29:30.000Z" },
  "serverTime": "2026-10-14T13:29:30.000Z"
}
```

### 2. Get Today's Plan
- **Route**: `GET /api/plans/today` (optional query: `?date=YYYY-MM-DD`)
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**:
```json
{
  "data": {
    "plan": { "id": "...", "planDate": "2026-10-14", "wakingSeconds": 54000, "items": [ ... ] },
    "serverTime": "2026-10-14T13:29:35.000Z"
  },
  "serverTime": "2026-10-14T13:29:35.000Z"
}
```

### 3. Get Plan by ID
- **Route**: `GET /api/plans/:id`
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**: returns plan details with `serverTime`.

### 4. Update Plan Items
- **Route**: `PATCH /api/plans/:id`
- **Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "items": [
    { "categoryId": "academic", "plannedSeconds": 7200 },
    { "categoryId": "career", "plannedSeconds": 9000 },
    { "categoryId": "entertainment", "plannedSeconds": 3600 }
  ]
}
```
- **Response (200 OK)**:
```json
{
  "message": "Plan updated successfully",
  "data": { "plan": { ... }, "serverTime": "2026-10-14T13:30:00.000Z" },
  "serverTime": "2026-10-14T13:30:00.000Z"
}
```

### 5. Get Planned vs Actual Summary
- **Route**: `GET /api/plans/summary?date=YYYY-MM-DD` (or `GET /api/plans/:id/summary`)
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**:
```json
{
  "data": {
    "summary": {
      "planId": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
      "planDate": "2026-10-14",
      "wakingSeconds": 54000,
      "totalPlannedSeconds": 19800,
      "totalActualSeconds": 35,
      "categories": [
        {
          "categoryId": "academic",
          "categoryName": "Academic",
          "categoryDescription": "Studies, homework, research, lectures",
          "categoryColor": "#4A6FA5",
          "categoryIcon": "school",
          "plannedSeconds": 7200,
          "actualSeconds": 21,
          "remainingSeconds": -3618,
          "overtimeSeconds": 3618,
          "isRunning": false,
          "startedAt": null
        },
        {
          "categoryId": "career",
          "categoryName": "Career",
          "categoryDescription": "Work, projects, professional development",
          "categoryColor": "#E07A5F",
          "categoryIcon": "work",
          "plannedSeconds": 9000,
          "actualSeconds": 14,
          "remainingSeconds": 8986,
          "overtimeSeconds": 0,
          "isRunning": true,
          "startedAt": "2026-10-14T13:32:00.000Z"
        }
      ]
    },
    "serverTime": "2026-10-14T13:32:42.280Z"
  },
  "serverTime": "2026-10-14T13:32:42.280Z"
}
```

---

## Error Codes

| Status | Error Message | Description |
|---|---|---|
| `400 Bad Request` | `Planned seconds must be multiples of 30 minutes (1800 seconds)` | `plannedSeconds` is not a multiple of 1800 |
| `400 Bad Request` | `Total planned time (X s) cannot exceed available waking time (Y s)` | Sum of planned seconds exceeds server-computed waking time |
| `400 Bad Request` | `Cannot modify a plan from a past date` | Attempted to update a historical plan (`planDate < today`) |
| `400 Bad Request` | `Cannot remove a category with an active running timer. Pause it first.` | Category deletion blocked while timer is running |
| `401 Unauthorized` | `Missing or invalid token` | Unauthenticated request or expired token |
| `404 Not Found` | `Daily plan not found` | Plan does not exist or belongs to another user (security isolation) |

---

## Done
- [x] Server-computed `waking_seconds` from user profile (`wakeTime`, `bedtime`, `routineMinutes`), client value untrusted
- [x] Validation: planned seconds >= 0, multiples of 30 minutes (1800s), sum <= waking_seconds (400 Bad Request)
- [x] One plan per user per date: idempotent `POST /api/plans` returns existing plan if already created (200 OK)
- [x] Added `serverTime` (ISO string) to all plan endpoint responses
- [x] Implemented planned vs actual summary endpoints (`GET /api/plans/summary?date=YYYY-MM-DD` and `GET /api/plans/:id/summary`)
- [x] Past date handling: forbid modifying past-day plans (`PATCH /api/plans/:id` returns 400)
- [x] Preserving running timer state when updating planned_seconds (remaining changes by difference, started_at intact)
- [x] Security: verified user ownership on all endpoints (404 for unauthorized cross-user access)
- [x] Live HTTP verification in `backend/src/scripts/test-core-flow.ts` passed 14/14 checks against Neon PostgreSQL
