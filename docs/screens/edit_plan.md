# Edit Plan Screen
Status: DONE
Location: `/mobile/lib/features/planning/presentation/edit_plan_screen.dart`

Figma Reference: `12_edit_plan` (Row 19 in `design/FIGMA_LINKS.md`)

## Done
- Backend: Enforced minimum planned time rule in `PlansService.updatePlan`:
  - `minPlannedSeconds = ceil(usedSeconds / 1800) * 1800` (rounded up to 30m).
  - Rejects editing below used time with 400: `"You've already used X here, so Y is the minimum."`.
  - Rejects omitting/removing a category that already has used time today.
  - Never allows editing to create instant overtime.
  - If a category is running, remaining time changes by difference `(newPlanned - oldPlanned)` without resetting or restarting the timer.
- Mobile: Built `EditPlanScreen` and `EditPlanController` matching Figma 12:
  - Opened via slide-up modal transition `AppTransitions.modal` from Today's "Edit plan" icon button.
  - Reuses shared `HoursLeftCard`, `PillStepper`, and category indicator rows.
  - Clamps steppers to `minPlannedSeconds` and displays friendly note (`"You've already used 3h here, so 3h is the minimum."`).
  - Displays informational note: `"Used time stays put. Only your plan changes. [Category] is still running."`
  - Over-allocated state warning banner and disables saving until time is freed up.
  - Intercepts close/cancel and system back button with `PopScope`: prompts confirmation dialog `"Discard changes?"` if unsaved changes exist.
  - Saving calls `PUT /api/plans/:id`, shows loading indicator, and immediately triggers `todayControllerProvider.fetchStatus()` to refresh Today screen.
- Unit and widget tests:
  - `mobile/test/edit_plan_calculation_test.dart`
  - `mobile/test/edit_plan_screen_test.dart`
  - Backend math unit tests in `backend/src/tests/timer-math.test.ts`
  - Live flow verification in `backend/src/scripts/test-core-flow.ts` and `backend/src/scripts/test-live-user-experience.ts`.
