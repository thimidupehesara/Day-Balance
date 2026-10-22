# Summary Screen
Status: DONE
Location: `/mobile/lib/features/summary/presentation/summary_screen.dart`

Figma Reference: `13_end_of_day_summary` (Row 20 in `design/FIGMA_LINKS.md`)

## Done
- Backend: Verified `GET /api/plans/summary?date=YYYY-MM-DD`:
  - Returns `planId`, `planDate`, `wakingSeconds`, `totalPlannedSeconds`, `totalActualSeconds`, `categories`, and `serverTime`.
  - Computes `actualSeconds` from sum of `time_entries` (including active open entry up to server's `now()`).
  - Strict data isolation: authenticated user only sees their own summary data.
- Mobile: Built `SummaryScreen`, `SummaryController`, and `SummaryRepository` matching Figma 13:
  - Header: `AppBackButton` + `"Your day, in balance"`.
  - Date string in uppercase (`"WEDNESDAY, 14 OCTOBER"`).
  - Headline: `"You made room."` (or `"Your day unfolded."` if over-budget).
  - Big stats row: total actual (`"14h 00m"` of `"14h 30m planned"`) and breathing room (`"30m"` `"left as breathing room"` or overtime).
  - Legend: Planned (`#DEDED8`) and Actual (`#49664D`).
  - Paired category bars: Top bar (planned, tinted opacity) and bottom bar (actual, solid category color) with duration text.
  - Factual insight card: `#E0E8DB` background, non-judgmental factual observation calculated strictly from user's actual data.
  - Handles empty state when no plan exists for today (`"No plan for today yet"`) with primary button to plan (`/plan`).
  - Handles active running timer updates on open or pull-to-refresh (`RefreshIndicator`).
  - Bottom navigation bar: active `"History"` tab navigating to `/summary`, `"Today"` tab navigating to `/today`.
- Unit and widget tests:
  - `mobile/test/summary_calculation_test.dart`
  - `mobile/test/summary_screen_test.dart`
  - Backend integration tests in `backend/src/scripts/test-core-flow.ts` and `backend/src/scripts/test-live-user-experience.ts`.
