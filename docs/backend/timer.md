# Timer Module

## Rules
- **Server Time Truth**: Server timestamp `now` is authoritative. Every response returns `serverTime` (ISO string).
- **Atomic Auto-Pause**: Starting item B pauses active item A in one transaction with row locking (`FOR UPDATE`). DB unique index ensures at most 1 running timer per user.
- **Pause & Overtime**: Pausing sets `remaining_seconds = remaining_seconds - elapsed`. Stored as signed integer; negative values represent overtime (`isOvertime: true`).
- **Plan Edits While Running**: Adjusts `remainingSeconds` by delta without touching `startedAt`.
- **Midnight Crossing**: Timers run continuously across midnight and attribute duration to the plan date they started on.
- **Isolation**: Timer actions require item ownership by authenticated `userId`.

## Edge Cases & Error Codes
- `200`: Starting an already running item is idempotent (`isAlreadyRunning: true`).
- `400`: Pausing when no timer is active, item not running, or starting timer on past-date plan.
- `401`: Missing or invalid JWT token.
- `404`: Plan item not found or belongs to another user.

## Request & Response Example
`POST /api/timer/start`
```json
// Request
{ "planItemId": "11111111-2222-3333-4444-555555555555" }

// Response (200 OK)
{
  "message": "Timer started successfully",
  "data": {
    "activeItem": {
      "id": "11111111-2222-3333-4444-555555555555",
      "categoryId": "career",
      "remainingSeconds": 7200,
      "startedAt": "2026-10-14T13:29:40.065Z"
    },
    "autoPausedItem": {
      "id": "22222222-3333-4444-5555-666666666666",
      "categoryId": "academic",
      "remainingSeconds": 7193,
      "startedAt": null
    },
    "serverTime": "2026-10-14T13:29:40.065Z",
    "isAlreadyRunning": false
  },
  "serverTime": "2026-10-14T13:29:40.065Z"
}
```
