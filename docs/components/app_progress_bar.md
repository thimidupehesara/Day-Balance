# App Progress Bar
Status: DONE
Location: `/mobile/lib/shared/widgets/app_progress_bar.dart`

## Done
- Created `AppProgressBar` shared widget:
  - 4dp height with `BorderRadius.circular(100)`
  - Track color defaults to `#DDDCD2` (`AppColors.divider`)
  - Fill color defaults to `#49664D` (`AppColors.primarySage`), customizable for category colors or error/overtime states
  - Clamps ratio between 0.0 and 1.0 using `FractionallySizedBox`

## Usage
```dart
AppProgressBar(
  progress: 0.65,
  fillColor: AppColors.primarySage,
)
```
