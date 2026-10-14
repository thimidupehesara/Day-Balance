# Today Screen
Status: DONE
Location: `/mobile/lib/features/timer/presentation/today_screen.dart`

Figma Reference: `09_today_home`, `09_today_home_before_planning`, `09_today_home_overtime`, `16_empty_error_states_no_connection`

## Done
- Built `TodayScreen` and `TodayController` according to Figma exports and specs.
- Before-planning state (`09_today_home_before_planning`):
  - Decorative illustration card with category accent bars.
  - Heading "A fresh day. A little room to choose."
  - Subtitle "You haven’t made a plan yet. Give your hours a place, then start one thing at a time."
  - Schedule footnote showing wake and bedtime with routines set aside.
  - "Plan today" button navigating to `/plan`.
- Top header:
  - Formatted uppercase date (e.g. "WEDNESDAY, 14 OCTOBER").
  - Greeting with user's name ("Hello, <name>"; fallback "Hello!").
  - "Total hours left" tracking available capacity, plus Edit plan button routing to `/plan`.
- Planned state (`09_today_home`):
  - One card per category using `CategoryTimerCard`.
  - Idle state: Category color accent bar, planned time, remaining time, and "Start" button.
  - Running state: Pastel category background, running status ("● RUNNING"), live countdown (e.g. "2:45:00"), and "Pause" button.
- Overtime state (`09_today_home_overtime`):
  - Red border and error container (`#F6E2DE`).
  - "OVERTIME" status badge.
  - Monospace red overtime string: e.g. "+0:12:30 over".
  - Subtitle: "Planned 4h · 4h 12m used".
- Single running timer rule:
  - Starting one category automatically pauses any other currently active timer on the server and updates UI seamlessly.
- Live countdown & server time offset:
  - Computed as `remaining = remaining_seconds - (now - started_at)` adjusted by `serverTime` offset.
  - Refreshes every second via ticker.
  - `WidgetsBindingObserver` re-synchronizes timer immediately on `AppLifecycleState.resumed`.
- Pull-to-refresh (`RefreshIndicator`) to sync latest state from backend.
- Screen 16 offline and error state ("A little offline.") with "Try again" retry button.
- Unit tests (`mobile/test/today_calculation_test.dart`) and widget tests (`mobile/test/today_screen_test.dart`) passing 100%.
- Real end-to-end integration test (`backend/src/scripts/test-live-user-experience.ts`) verified live against Neon database.
