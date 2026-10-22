import 'package:flutter_test/flutter_test.dart';
import 'package:day_balance/features/summary/domain/summary_model.dart';
import 'package:day_balance/features/summary/presentation/summary_controller.dart';

void main() {
  group('Summary Calculation & Insight Unit Tests', () {
    test('Calculates totals and breathing room correctly', () {
      final summary = PlanSummaryModel(
        planId: 'plan-1',
        planDate: '2026-10-22',
        wakingSeconds: 16 * 3600, // 57600s = 16h
        totalPlannedSeconds: 14 * 3600 + 1800, // 52200s = 14h 30m
        totalActualSeconds: 14 * 3600, // 50400s = 14h 00m
        serverTime: DateTime.now(),
        categories: const [
          CategorySummaryModel(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColorHex: '#4A6B82',
            plannedSeconds: 4 * 3600,
            actualSeconds: 4 * 3600 + 900,
            remainingSeconds: -900,
            overtimeSeconds: 900,
            isRunning: false,
          ),
        ],
      );

      // Breathing room = 16h - 14h 30m = 1h 30m (5400s)
      expect(summary.breathingRoomSeconds, 5400);
      expect(summary.isOverBudget, isFalse);
      expect(summary.overBudgetSeconds, 0);
    });

    test('Detects over-budget days correctly', () {
      final summary = PlanSummaryModel(
        planId: 'plan-1',
        planDate: '2026-10-22',
        wakingSeconds: 16 * 3600,
        totalPlannedSeconds: 10 * 3600,
        totalActualSeconds: 11 * 3600, // 1h over planned
        serverTime: DateTime.now(),
        categories: const [],
      );

      expect(summary.isOverBudget, isTrue);
      expect(summary.overBudgetSeconds, 3600);
    });

    test('Generates factual insight line when a category exceeded planned time', () {
      final summary = PlanSummaryModel(
        planId: 'plan-1',
        planDate: '2026-10-22',
        wakingSeconds: 16 * 3600,
        totalPlannedSeconds: 14 * 3600,
        totalActualSeconds: 14 * 3600 + 900,
        serverTime: DateTime.now(),
        categories: const [
          CategorySummaryModel(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColorHex: '#4A6B82',
            plannedSeconds: 4 * 3600,
            actualSeconds: 4 * 3600 + 900, // 4h 15m
            remainingSeconds: -900,
            overtimeSeconds: 900,
            isRunning: false,
          ),
          CategorySummaryModel(
            categoryId: 'career',
            categoryName: 'Career',
            categoryColorHex: '#85897D',
            plannedSeconds: 2 * 3600,
            actualSeconds: 2 * 3600,
            remainingSeconds: 0,
            overtimeSeconds: 0,
            isRunning: false,
          ),
        ],
      );

      final state = SummaryState(
        summary: summary,
        date: DateTime.now(),
      );

      expect(
        state.insightLine,
        'Academic needed a little more time. Your buffer helped the day stay flexible.',
      );
    });

    test('Generates factual insight line for top category when on schedule', () {
      final summary = PlanSummaryModel(
        planId: 'plan-1',
        planDate: '2026-10-22',
        wakingSeconds: 16 * 3600,
        totalPlannedSeconds: 14 * 3600,
        totalActualSeconds: 7 * 3600,
        serverTime: DateTime.now(),
        categories: const [
          CategorySummaryModel(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColorHex: '#4A6B82',
            plannedSeconds: 7 * 3600,
            actualSeconds: 5 * 3600 + 1200, // 5h 20m
            remainingSeconds: 3600 + 600,
            overtimeSeconds: 0,
            isRunning: false,
          ),
        ],
      );

      final state = SummaryState(
        summary: summary,
        date: DateTime.now(),
      );

      expect(
        state.insightLine,
        'You used 5h 20m of your 7h Academic time.',
      );
    });

    test('Handles zero tracked time insight gracefully', () {
      final summary = PlanSummaryModel(
        planId: 'plan-1',
        planDate: '2026-10-22',
        wakingSeconds: 16 * 3600,
        totalPlannedSeconds: 8 * 3600,
        totalActualSeconds: 0,
        serverTime: DateTime.now(),
        categories: const [
          CategorySummaryModel(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColorHex: '#4A6B82',
            plannedSeconds: 8 * 3600,
            actualSeconds: 0,
            remainingSeconds: 8 * 3600,
            overtimeSeconds: 0,
            isRunning: false,
          ),
        ],
      );

      final state = SummaryState(
        summary: summary,
        date: DateTime.now(),
      );

      expect(
        state.insightLine,
        'No time tracked yet today. Start a timer to see your progress.',
      );
    });
  });
}
