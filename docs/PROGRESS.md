# Day-Balance Progress

## Screens

| Screen | Status | Main File Path |
|---|---|---|
| 01 Welcome | Done | `mobile/lib/features/auth/presentation/welcome_screen.dart` |
| 02 Register | Done | `mobile/lib/features/auth/presentation/register_screen.dart` |
| 03 Login | Done | `mobile/lib/features/auth/presentation/login_screen.dart` |
| 04 Onboarding Schedule | Done | `mobile/lib/features/onboarding/presentation/onboarding_schedule_screen.dart` |
| 05 Onboarding Routine | Done | `mobile/lib/features/onboarding/presentation/onboarding_routine_screen.dart` |
| 06 Onboarding Result | Done | `mobile/lib/features/onboarding/presentation/onboarding_result_screen.dart` |
| 07 Onboarding Categories | Done | `mobile/lib/features/onboarding/presentation/onboarding_categories_screen.dart` |
| Setting Up Loading | Done | `mobile/lib/features/onboarding/presentation/setting_up_screen.dart` |
| 08 Daily Planning | Done | `mobile/lib/features/planning/presentation/plan_screen.dart` |
| 09 Today Home | Done | `mobile/lib/features/timer/presentation/today_screen.dart` |
| 10 Active Timer | Done | `mobile/lib/features/timer/presentation/active_timer_screen.dart` |
| 11 Switch Sheet | Done | `mobile/lib/features/timer/presentation/switch_sheet.dart` |
| 12 Edit Plan | Done | `mobile/lib/features/planning/presentation/edit_plan_screen.dart` |
| 13 End-of-Day Summary | Done | `mobile/lib/features/summary/presentation/summary_screen.dart` |
| 14 History Week | Not started | `mobile/lib/features/history/` |
| 15 Settings | Not started | `mobile/lib/features/settings/` |
| 16 Offline & Error States | Done | `mobile/lib/shared/widgets/error_state_view.dart` |

## Next Step
- Build History Week screen (14) or Settings screen (15).

## Known Issues
- Local notifications for category timer reaching zero are not wired into the app yet.
- Neon Object Storage S3 client requires `forcePathStyle: true` due to path-style addressing.
- Auth endpoints enforce rate-limiting (15 req/15 min in prod, relaxed in development/test).
