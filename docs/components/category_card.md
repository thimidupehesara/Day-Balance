# Category Card
Status: DONE
Location: `/mobile/lib/shared/widgets/category_card.dart`

## Done
- Created `CategoryTimerCard` shared widget:
  - **Running State**: Category tinted background, 1.5px sage border, "● RUNNING" badge, large 30sp tabular countdown, Pause button with >=48dp touch target, and progress bar
  - **Overtime State**: Light red container `#F6E2DE`, 1.5px error border `#A43B32`, "OVERTIME" badge, "+0:12:30 over" formatted text, and red progress bar
  - **Idle / Paused State**: `#FFFFCF7` surface, 4dp category color accent bar, planned hours subtext, remaining hours, and accessible "Start" action button

## Usage
```dart
CategoryTimerCard(
  categoryName: 'Academic',
  categoryColor: AppColors.academic,
  plannedText: '4h 00m',
  remainingText: '2:45:00',
  progress: 0.31,
  isRunning: true,
  isOvertime: false,
  onAction: () => controller.toggleTimer('academic'),
)
```
