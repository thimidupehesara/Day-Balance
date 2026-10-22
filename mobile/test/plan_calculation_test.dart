import 'package:flutter_test/flutter_test.dart';
import 'package:day_balance/features/planning/presentation/plan_controller.dart';

void main() {
  group('PlanState & Planning Math Tests', () {
    test('formatDuration formats hours and padded minutes', () {
      expect(PlanState.formatDuration(0), '0h 00m');
      expect(PlanState.formatDuration(1800), '0h 30m');
      expect(PlanState.formatDuration(3600), '1h 00m');
      expect(PlanState.formatDuration(4 * 3600), '4h 00m');
      expect(PlanState.formatDuration(14 * 3600 + 1800), '14h 30m');
    });

    test('formatShort formats compact time strings', () {
      expect(PlanState.formatShort(1800), '30m');
      expect(PlanState.formatShort(3600), '1h');
      expect(PlanState.formatShort(3 * 3600), '3h');
      expect(PlanState.formatShort(3600 + 1800), '1h 30m');
    });

    test('calculates normal remaining hours left to plan', () {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        plannedSeconds: {
          'academic': 4 * 3600,
          'life_family': 2 * 3600,
          'entertainment': 2 * 3600,
          'personal_reading': 2 * 3600,
          'career': 2 * 3600,
          'unplanned': 1 * 3600,
          'rest': 1 * 3600,
        }, // total = 14h
      );

      expect(state.totalPlannedSeconds, 14 * 3600);
      expect(state.diffSeconds, 1800); // 30m left
      expect(state.secondsLeftToPlan, 1800);
      expect(state.isOverAllocated, false);
      expect(state.isZeroHoursLeft, false);
      expect(state.canStartDay, true);
    });

    test('detects zero hours left state', () {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        plannedSeconds: {
          'academic': 4 * 3600,
          'life_family': 2 * 3600,
          'entertainment': 2 * 3600,
          'personal_reading': 2 * 3600,
          'career': 2 * 3600,
          'unplanned': 1 * 3600,
          'rest': 1 * 3600 + 1800,
        }, // total = 14h 30m
      );

      expect(state.totalPlannedSeconds, 14 * 3600 + 1800);
      expect(state.diffSeconds, 0);
      expect(state.secondsLeftToPlan, 0);
      expect(state.isZeroHoursLeft, true);
      expect(state.isOverAllocated, false);
      expect(state.canStartDay, true);
    });

    test('detects over-allocated state correctly', () {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        plannedSeconds: {
          'academic': 5 * 3600,
          'life_family': 3 * 3600,
          'entertainment': 3 * 3600,
          'personal_reading': 2 * 3600,
          'career': 2 * 3600 + 1800,
        }, // total = 15h 30m (1h over)
      );

      expect(state.totalPlannedSeconds, 15 * 3600 + 1800);
      expect(state.diffSeconds, -3600);
      expect(state.secondsLeftToPlan, 0);
      expect(state.isOverAllocated, true);
      expect(state.overAllocatedSeconds, 3600);
      expect(state.isZeroHoursLeft, false);
      expect(state.canStartDay, false); // cannot start when over-allocated
    });

    test('calculates entertainment warning when > 30% of planned', () {
      // 3h entertainment out of 9h planned = 33.3% (> 30%)
      const warningState = PlanState(
        wakingSeconds: 14 * 3600,
        plannedSeconds: {
          'academic': 4 * 3600,
          'entertainment': 3 * 3600,
          'rest': 2 * 3600,
        },
      );
      expect(warningState.totalPlannedSeconds, 9 * 3600);
      expect(warningState.entertainmentSeconds, 3 * 3600);
      expect(warningState.entertainmentRatio, closeTo(0.333, 0.01));
      expect(warningState.hasEntertainmentWarning, true);

      // 2h entertainment out of 10h planned = 20% (<= 30%)
      const safeState = PlanState(
        wakingSeconds: 14 * 3600,
        plannedSeconds: {
          'academic': 5 * 3600,
          'entertainment': 2 * 3600,
          'rest': 3 * 3600,
        },
      );
      expect(safeState.entertainmentRatio, 0.20);
      expect(safeState.hasEntertainmentWarning, false);
    });
  });
}
