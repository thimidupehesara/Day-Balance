# Plans Module

## Rules
- **Server Time Truth**: Every response returns `serverTime` (ISO string) for client clock drift correction.
- **Waking Seconds**: Server computes `waking_seconds = max(0, (grossWakingMinutes - routineMinutes) * 60)` from user profile. Client-sent values are ignored.
- **Constraints**: Total planned <= waking seconds; item planned seconds must be non-negative multiples of 1800s (30m).
- **One Plan Per Date**: `POST /api/plans` for an existing date idempotently returns the existing plan (200 OK, `isExisting: true`).
- **Editing Plan**: Adjusts `remainingSeconds` by `(newPlanned - oldPlanned)` preserving `startedAt`. Minimum planned time cannot be less than `ceil(usedSeconds / 1800) * 1800`.
- **Immutability**: Past-date plans cannot be modified.
- **Isolation**: Queries and mutations strictly scoped to authenticated `userId`.

## Error Codes
- `400`: Planned time exceeds waking seconds, non-1800s multiple, past date edit, or planned < used time minimum.
- `401`: Missing or invalid JWT token.
- `404`: Plan not found or belongs to another user.

## Request & Response Example
`POST /api/plans`
```json
// Request
{
  "planDate": "2026-10-14",
  "items": [
    { "categoryId": "academic", "plannedSeconds": 7200 },
    { "categoryId": "career", "plannedSeconds": 7200 }
  ]
}

// Response (201 Created)
{
  "message": "Plan created successfully",
  "data": {
    "plan": {
      "id": "b7ad205b-12dc-4e6b-a4cb-18f92f34401e",
      "planDate": "2026-10-14",
      "wakingSeconds": 54000,
      "items": [
        { "categoryId": "academic", "plannedSeconds": 7200, "remainingSeconds": 7200, "startedAt": null }
      ]
    },
    "serverTime": "2026-10-14T13:29:29.327Z"
  },
  "serverTime": "2026-10-14T13:29:29.327Z"
}
```
