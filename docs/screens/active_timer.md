# Active Timer Screen
Status: DONE
Location: `/mobile/lib/features/timer/presentation/active_timer_screen.dart`

Figma Reference: `10_active_timer.png`, `_10_active_timer.dart` (`https://www.figma.com/design/hEpqC6LfjEHogSWvzYCgkz/Untitled?node-id=7-5976`)

## Done
- Created `ActiveTimerScreen` in `mobile/lib/features/timer/presentation/active_timer_screen.dart` strictly matching Figma screen 10 designs.
- Connected route `/timer` in `mobile/lib/core/router/app_router.dart` using `AppTransitions.sharedAxis` and accepting optional `planItemId` parameter.
- Top bar:
  - Back button (`AppIcons.back`) with minimum 48x48dp touch target, returning to `/home`.
  - Center title: "Focus time" (fontSize 22, color `AppColors.text`).
  - Right action: "End session" button (fontSize 14, bold, color `AppColors.primarySage`), pausing active timer and returning to Today.
- Active category header:
  - Row with category icon and category name (fontSize 22, color `AppColors.text`).
  - Subtitle: "Just this, for now." (fontSize 14, color `AppColors.secondary`).
- Circular Dial / Ring Display:
  - Custom circular dial painter `_TimerDialPainter` with 280dp diameter matching Figma.
  - Smooth 10dp stroke background ring in `AppColors.timerTrack` (`#E5E2D9`).
  - Progress arc swept clockwise by ratio `(planned - remaining) / planned` in `AppColors.primarySage` (or `AppColors.error` in overtime).
  - Center tabular digits countdown time (e.g. "2:45:00") or overtime format (`+H:MM:SS over`) with font feature `FontFeature.tabularFigures()`.
  - Subtitle below time: "remaining of Xh Ym" (or "overtime").
  - Detail text: "Running since HH:MM AM/PM · Xh Ym used" (or "Paused · Xh Ym used").
- Controls:
  - Left: "Pause" / "Resume" primary filled pill button (48dp height, color `AppColors.primarySage`, white text).
  - Right: "Switch" outlined pill button (48dp height, outline `AppColors.outline`, text `AppColors.primarySage`).
- "MOVE TO SOMETHING ELSE" section:
  - Title: "MOVE TO SOMETHING ELSE" (fontSize 12, uppercase).
  - Row of cards for other planned categories today with pastel background colors (`AppColors.colorForCategory`), icons, and category names.
  - Tapping a card opens the Switch Sheet (`11_switch_sheet.png`) for that category.
  - Explanatory footnote: "Switching pauses [ActiveCategory]. Your time stays here."
- Connected `TodayScreen`: tapping on category cards navigates to `/timer?planItemId=...`.
- Verified with widget tests (`mobile/test/active_timer_screen_test.dart`) and 0 lint warnings in `flutter analyze`.
