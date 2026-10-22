# Switch Sheet
Status: DONE
Location: `/mobile/lib/features/timer/presentation/switch_sheet.dart`

Figma Reference: `11_switch_sheet.png`, `_11_switch_sheet.dart` (`https://www.figma.com/design/hEpqC6LfjEHogSWvzYCgkz/Untitled?node-id=7-6027`)

## Done
- Created `SwitchSheet` in `mobile/lib/features/timer/presentation/switch_sheet.dart` as a modal bottom sheet matching Figma screen 11.
- Drag handle pill: 32x4dp, radius 100, color `AppColors.outline` (`#85897D`).
- Sheet background: `AppColors.canvas` (`#F8F5EF`), top corner radius 28dp.
- Header:
  - Title: "Pause [ActiveCategory] and start [TargetCategory]?" (fontSize 24, `AppColors.text`).
  - Subtitle: "Your [Xh Ym] in [ActiveCategory] will be waiting when you come back." (fontSize 14, `AppColors.secondary`).
- Preview Card:
  - Rounded card (radius 16dp) in Target Category pastel color (`AppColors.colorForCategory`).
  - Target Category icon (24x24dp).
  - Text: "[TargetCategory] · [Remaining] remaining" (fontSize 14, `AppColors.text`, medium weight).
- Action buttons row:
  - Cancel button: Outlined pill button (radius 100, border `AppColors.outline`, text `AppColors.primarySage`, bold 14). Dismisses sheet without switching.
  - Confirm button: Filled pill button (radius 100, background `AppColors.primarySage`, text white, bold 14). Triggers switch and dismisses sheet.
- Footer caption: "Only one timer runs at a time." (fontSize 12, `AppColors.secondary`).
- Wiring:
  - Wired into `TodayScreen`: tapping "Start" on an inactive category while another is active triggers `SwitchSheet.show(...)`.
  - Wired into `ActiveTimerScreen`: tapping "Switch" or any category in "MOVE TO SOMETHING ELSE" triggers `SwitchSheet.show(...)`.
- Verified with widget tests (`mobile/test/switch_sheet_test.dart`) and full test suite pass.
