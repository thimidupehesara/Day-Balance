# Hours Left Card
Status: DONE
Location: `/mobile/lib/shared/widgets/hours_left_card.dart`

## Done
- Created `HoursLeftCard` shared component:
  - Supports "Hours left to plan" (screen 08) and "Total hours left" (screen 09)
  - Displays large value (32sp) with responsive subText (e.g. "of 14h 30m")
  - Supports `isOverAllocated` state with `#A43B32` error coloring
  - Optional progress bar via `AppProgressBar`
  - Optional trailing widget (e.g. 48dp Edit Plan button on Today)

## Usage
```dart
HoursLeftCard(
  title: 'Hours left to plan',
  hoursText: '0h 30m',
  subText: 'of 14h 30m',
  progress: 0.96,
  isOverAllocated: false,
)
```
