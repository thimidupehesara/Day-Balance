# Plan Screen
Status: DONE
Location: `/mobile/lib/features/planning/presentation/plan_screen.dart`

Figma Reference: `08_daily_planning`, `08_daily_planning_zero_hours_left`, `08_daily_planning_over_allocated`

## Done
- Rebuilt `PlanScreen` and `PlanController` according to Figma exports and specs.
- Displays only categories selected by the user in onboarding (or all if none specified).
- Top "Hours left to plan" section using `HoursLeftCard`:
  - Total waking hours calculated by profile wake time, bedtime, and routines.
  - Progress bar tracking planned proportion vs available waking time.
  - Under-budget state: Sage primary text, breathing room helper text ("30m will stay as extra breathing room.").
  - Zero hours left state: "0h 00m", sage info card "Every hour has a place. You can adjust your plan as the day unfolds.", active "Start my day" button.
  - Over-allocated state: error color "−1h 00m", full error progress bar, warning banner "You’re 1h over. Free up an hour before starting your day.", and disabled button "Free up 1h to continue".
- PillStepper in 30-minute steps with category color indicator bar and plus/minus icons matching Figma.
- Gentle nudge banner when Entertainment exceeds 30% of planned time: "3h for Entertainment. Does that leave enough room for the rest of your day?"
- Saves plan via `POST /api/plans` (or `PATCH /api/plans/:id`) and routes to `/home` (Today).
- Unit tests (`mobile/test/plan_calculation_test.dart`) and widget tests (`mobile/test/plan_screen_test.dart`) verifying all calculations and screen states.
