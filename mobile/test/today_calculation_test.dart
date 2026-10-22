import 'package:flutter_test/flutter_test.dart';
import 'package:day_balance/features/planning/domain/plan_model.dart';
import 'package:day_balance/features/timer/presentation/today_controller.dart';

void main() {
  group('TodayTimerState & Formatting Tests', () {
    test('formatCountdown formats H:MM:SS for running countdown', () {
      expect(TodayTimerState.formatCountdown(9900), '2:45:00'); // 2h 45m 00s
      expect(TodayTimerState.formatCountdown(3665), '1:01:05');
      expect(TodayTimerState.formatCountdown(60), '0:01:00');
      expect(TodayTimerState.formatCountdown(0), '0:00:00');
    });

    test('formatOvertime formats +H:MM:SS over matching Figma', () {
      // 12m 30s overtime = 750 seconds -> "+0:12:30 over"
      expect(TodayTimerState.formatOvertime(750), '+0:12:30 over');
      // 1h 05m 10s overtime = 3910 seconds -> "+1:05:10 over"
      expect(TodayTimerState.formatOvertime(3910), '+1:05:10 over');
    });

    test('formatUsed formats total used time', () {
      // Planned 4h, 12m overtime = 4h 12m used
      expect(TodayTimerState.formatUsed(4 * 3600, 750), '4h 12m');
      expect(TodayTimerState.formatUsed(2 * 3600, 1800), '2h 30m');
    });

    test('calculates running remaining time corrected by server offset', () {
      final localNow = DateTime(2026, 10, 14, 10, 0, 0);
      // Server clock is 10 seconds ahead
      const serverOffset = Duration(seconds: 10);
      // Timer started at 09:50:00 on server
      final startedAt = DateTime(2026, 10, 14, 9, 50, 0);

      final item = PlanItemModel(
        id: 'item-1',
        dailyPlanId: 'plan-1',
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryDescription: '',
        categoryColor: '#D4DEE5',
        categoryIcon: 'school',
        plannedSeconds: 4 * 3600, // 14400s
        remainingSeconds: 14400,
        startedAt: startedAt,
      );

      final state = TodayTimerState(
        planId: 'plan-1',
        items: [item],
        activeItemId: 'item-1',
        activeStartedAt: startedAt,
        activeRemainingSeconds: 14400,
        serverOffset: serverOffset,
        now: localNow,
      );

      // effectiveNow = localNow + 10s = 10:00:10
      // elapsed = 10:00:10 - 09:50:00 = 10 minutes 10 seconds = 610 seconds
      // remaining = 14400 - 610 = 13790 seconds
      expect(state.effectiveNow, DateTime(2026, 10, 14, 10, 0, 10));
      expect(state.getRemainingSecondsForItem(item), 13790);
      expect(state.isItemOvertime(item), false);
    });

    test('detects overtime when remaining goes below zero', () {
      final localNow = DateTime(2026, 10, 14, 11, 0, 0);
      final startedAt = DateTime(2026, 10, 14, 10, 0, 0);

      final item = PlanItemModel(
        id: 'item-1',
        dailyPlanId: 'plan-1',
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryDescription: '',
        categoryColor: '#D4DEE5',
        categoryIcon: 'school',
        plannedSeconds: 3600, // 1 hour planned
        remainingSeconds: 3000, // 50 minutes left when started
        startedAt: startedAt,
      );

      // 60 minutes elapsed, but only 50 minutes were left -> 10 minutes overtime!
      final state = TodayTimerState(
        planId: 'plan-1',
        items: [item],
        activeItemId: 'item-1',
        activeStartedAt: startedAt,
        activeRemainingSeconds: 3000,
        serverOffset: Duration.zero,
        now: localNow,
      );

      expect(state.getRemainingSecondsForItem(item), -600); // -600s
      expect(state.isItemOvertime(item), true);
      expect(state.getOvertimeSecondsForItem(item), 600);
      expect(TodayTimerState.formatOvertime(state.getOvertimeSecondsForItem(item)), '+0:10:00 over');
    });

    test('totalHoursLeftSeconds accounts for category remaining and breathing room', () {
      // 14h 30m waking seconds
      const wakingSec = 14 * 3600 + 1800; // 52200s
      final item1 = PlanItemModel(
        id: 'item-1',
        dailyPlanId: 'plan-1',
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryDescription: '',
        categoryColor: '#D4DEE5',
        categoryIcon: 'school',
        plannedSeconds: 4 * 3600,
        remainingSeconds: 2 * 3600 + 45 * 60, // 2h 45m left
      );
      final item2 = PlanItemModel(
        id: 'item-2',
        dailyPlanId: 'plan-1',
        categoryId: 'life_family',
        categoryName: 'Life/Family',
        categoryDescription: '',
        categoryColor: '#EBD3BC',
        categoryIcon: 'home',
        plannedSeconds: 10 * 3600,
        remainingSeconds: 10 * 3600, // 10h left
      );

      // Total planned = 14h. Breathing room = 30m.
      // Total remaining from categories = 2h 45m + 10h = 12h 45m.
      // Total hours left = 12h 45m + 30m = 13h 15m (matching Figma 09_today_home!)
      final state = TodayTimerState(
        wakingSeconds: wakingSec,
        planId: 'plan-1',
        items: [item1, item2],
        now: DateTime.now(),
      );

      expect(TodayTimerState.formatDuration(state.totalHoursLeftSeconds), '13h 15m');
    });
  });
}
