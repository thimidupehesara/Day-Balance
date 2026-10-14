# Day-Balance Documentation Progress

> This is the master index. Every doc is listed here with its status.
> Any AI tool should read this first before touching anything.

## Status Definitions
- **PLANNED**: Not started.
- **DRAFT**: Code written and compiles, but NOT run or tested end-to-end.
- **DONE**: Verified by actually running it (e.g. a real API call or emulator test).
- **PAUSED**: Deliberately stopped, waiting on something (design, decision).

---

## Setup & Infrastructure

| Doc | Status | Summary | Notes |
|-----|--------|---------|-------|
| [Backend Setup](setup/backend_setup.md) | DONE | Express + TS + Drizzle project, health endpoint, DB connection | Verified live: Express server running, Neon DB & Object Storage connected |
| [Mobile Setup](setup/mobile_setup.md) | DONE | Flutter project, dependencies, folder structure, theme, router | Verified with `flutter analyze` and `flutter test` |
| [Database Schema](backend/database_schema.md) | DONE | Drizzle schema with all tables, seed script | Verified live: schema pushed to Neon PostgreSQL and 7 categories seeded |
| [Environment Config](setup/environment_config.md) | DONE | .env.example, zod validation, required variables | Verified live: Neon DB, S3 Object Storage, and secrets loaded |

## Backend Modules

| Doc | Status | Summary | Notes |
|-----|--------|---------|-------|
| [Auth Module](backend/auth.md) | DONE | Register, login, logout, refresh, delete account | Verified live with real backend HTTP requests and Neon DB |
| [Users Module](backend/users.md) | DONE | Profile, onboarding fields (wakeTime, bedtime, routineMinutes, onboardingDone) | Verified live with `test-onboarding-flow.ts` against Neon DB |
| [Categories Module](backend/categories.md) | DONE | List categories, user selection (`/api/categories/mine`) | Verified live with `test-onboarding-flow.ts` against Neon DB |
| [Plans Module](backend/plans.md) | DONE | Daily plans, plan items CRUD, server waking seconds, planned vs actual summary | Verified live with `test-core-flow.ts` against Neon DB |
| [Timer Module](backend/timer.md) | DONE | Atomic start/auto-pause in transaction, pause/overtime, resume, concurrency locking | Verified live with `test-core-flow.ts` and unit tests against Neon DB |

## Mobile Screens

| Doc | Status | Summary | Notes |
|-----|--------|---------|-------|
| [Welcome Screen](screens/welcome.md) | DONE | Welcome and landing screen strictly matching Figma `_01_welcome.dart` | Verified with widget tests; rebuilt from Figma `.dart` export |
| [Login Screen](screens/login.md) | DONE | Email + password login strictly matching Figma `_03_login.dart` | Verified with widget tests and live auth flow |
| [Register Screen](screens/register.md) | DONE | Name, email, password, confirm password, terms strictly matching Figma `_02_register.dart` | Verified with widget tests and live auth flow |
| [Onboarding Schedule](screens/onboarding_schedule.md) | DONE | Wake time & bedtime selector with custom wheel time picker matching Figma `_04_onboarding_schedule.dart` | Verified with widget tests, midnight crossing math, and live API |
| [Onboarding Routine](screens/onboarding_routine.md) | DONE | Morning & wind-up routine steppers matching Figma `_05_onboarding_routine.dart` | Verified with widget tests, routine math, and live API |
| [Onboarding Result](screens/onboarding_result.md) | DONE | Daily net hours calculation & breakdown matching Figma `_06_onboarding_result.dart` | Verified with widget tests and router transitions |
| [Onboarding Categories](screens/onboarding_categories.md) | DONE | Select categories from the 7 matching Figma `_07_choose_categories.dart` | Verified with widget tests and live API |
| [Setting Up Screen](screens/setup_loading.md) | DONE | "Setting up your day" loading screen with custom sky animation, honest social proof, and error retry | Built from spec; verified live and with widget tests |
| [Plan Screen](screens/plan.md) | DONE | Daily planning with 30m steppers, zero hours left, and over-allocated states matching Figma 08 | Verified with widget tests and live API |
| [Today Screen](screens/today.md) | DONE | Main screen with before-planning, active timers, overtime, and screen 16 offline state matching Figma 09 | Verified with widget tests and live API |
| [Summary Screen](screens/summary.md) | PLANNED | End-of-day planned vs actual | Not started |
| [Settings Screen](screens/settings.md) | PLANNED | User preferences, logout, delete account | Not started |

## Mobile Components

| Doc | Status | Summary | Notes |
|-----|--------|---------|-------|
| [Dio Client](components/dio_client.md) | DONE | HTTP client with JWT interceptor | Multi-platform baseUrl, token refresh verified |
| [App Router](components/app_router.md) | DONE | GoRouter with smooth horizontal shared axis and fade-through transitions | Verified with smoke test and live navigation |
| [Theme System](components/theme_system.md) | DONE | AppColors, AppTextStyles, AppTheme | Extracted from Figma Style Guide |
| [App Icons](components/app_icons.md) | DONE | Single source of truth for all icons using Material Symbols | Rounded style, weight 400, outlined |
| [App Transitions](components/app_transitions.md) | DONE | Smooth shared-axis and fade-through page transitions | Uses `animations` package |
| [App Time Picker](components/app_time_picker.md) | DONE | 3-wheel scrolling wheel time picker dialog (Hour, Minute 5m, AM/PM) | Uses `ListWheelScrollView` with haptic feedback |
| [App Back Button](components/app_back_button.md) | DONE | Back button with 48dp minimum touch target | Uses `AppIcons.back` |
| [Step Progress Bar](components/step_progress_bar.md) | DONE | 3-segment pill progress indicator ("YOUR DAY · X OF 3") | Fully responsive |
| [Tap Field](components/tap_field.md) | DONE | Outlined tap field with floating label and dropdown indicator | 56dp height |
| [Info Card](components/info_card.md) | DONE | Tinted warm card for calculation summaries | `#EEE8DC` background, 16dp radius |
| [Pill Stepper](components/pill_stepper.md) | DONE | Stepper pill with 48dp touch targets and minus/plus icons | Clamped to valid limits |
| [Category Tile](components/category_tile.md) | DONE | Selectable tinted tile with custom checkbox | Full opacity when active, dimmed when inactive |
| [Primary Button](components/primary_button.md) | DONE | 48dp pill primary CTA button | Built to Figma specs with loading state |
| [Secondary Button](components/secondary_button.md) | DONE | 48dp pill outlined CTA button | Built to Figma specs |
| [App Text Field](components/app_text_field.md) | DONE | Outlined text field with floating label | 4dp radius, 56dp height, error styling |
| [App Password Field](components/app_password_field.md) | DONE | Password field with show/hide toggle | Accessible 48dp toggle target, error styling |
| [Category Constants](components/category_constants.md) | DONE | 7 fixed categories with colors and icons | Matches project specification categories |
| [App Progress Bar](components/app_progress_bar.md) | DONE | 4dp rounded progress bar with custom track and fill colors | Used in planning and category cards |
| [Hours Left Card](components/hours_left_card.md) | DONE | Top summary card for hours left to plan and total hours left | Supports over-allocated error state |
| [Category Card](components/category_card.md) | DONE | Category timer card with idle, running, and overtime states | Supports auto-pause and overtime text |
| [Notification Service](components/notification_service.md) | DRAFT | Local notification helper for timer overtime | Not wired into the app yet |

---

## Next Steps
- Active Timer screen (10) and Switch sheet (11)
- Local notifications
- Edit plan screen (12)
