import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:day_balance/features/summary/domain/summary_model.dart';
import 'package:day_balance/features/summary/presentation/summary_controller.dart';
import 'package:day_balance/features/summary/presentation/summary_screen.dart';

class TestSummaryController extends SummaryController {
  final SummaryState _initialState;
  TestSummaryController(this._initialState);

  @override
  SummaryState build() => _initialState;

  @override
  Future<void> fetchSummary([DateTime? date]) async {}
}

void main() {
  Widget createWidget(SummaryState state) {
    return ProviderScope(
      overrides: [
        summaryControllerProvider
            .overrideWith(() => TestSummaryController(state)),
      ],
      child: const MaterialApp(
        home: SummaryScreen(),
      ),
    );
  }

  group('SummaryScreen Widget Tests', () {
    testWidgets('renders planned vs actual summary matching Figma 13',
        (tester) async {
      final summary = PlanSummaryModel(
        planId: 'plan-123',
        planDate: '2026-10-14',
        wakingSeconds: 15 * 3600, // 15h
        totalPlannedSeconds: 14 * 3600 + 1800, // 14h 30m
        totalActualSeconds: 14 * 3600, // 14h 00m
        serverTime: DateTime(2026, 10, 14, 22, 15),
        categories: const [
          CategorySummaryModel(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColorHex: '#4A6B82',
            plannedSeconds: 4 * 3600 + 900, // 4h 15m
            actualSeconds: 4 * 3600, // 4h 00m
            remainingSeconds: 900,
            overtimeSeconds: 0,
            isRunning: false,
          ),
          CategorySummaryModel(
            categoryId: 'life_family',
            categoryName: 'Life/Family',
            categoryColorHex: '#EBD3BC',
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
        date: DateTime(2026, 10, 14),
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Your day, in balance'), findsOneWidget);
      expect(find.text('WEDNESDAY, 14 OCTOBER'), findsOneWidget);
      expect(find.text('You made room.'), findsOneWidget);

      // Big Stats Row
      expect(find.text('14h 00m'), findsOneWidget);
      expect(find.text('of 14h 30m planned'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('left as breathing room'), findsOneWidget);

      // Legend
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);

      // Category paired items
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('4h 00m / 4h 15m'), findsOneWidget);
      expect(find.text('Life/Family'), findsOneWidget);
      expect(find.text('2h 00m / 2h 00m'), findsOneWidget);

      // Insight Card
      expect(
        find.text('You used 4h of your 4h 15m Academic time.'),
        findsOneWidget,
      );

      // Bottom Nav
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders empty state when no plan exists for today',
        (tester) async {
      final state = SummaryState(
        summary: null,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Your day, in balance'), findsOneWidget);
      expect(find.text('No plan for today yet'), findsOneWidget);
      expect(find.text('Plan my day'), findsOneWidget);
    });

    testWidgets('renders overtime label when actual exceeds planned',
        (tester) async {
      final summary = PlanSummaryModel(
        planId: 'plan-123',
        planDate: '2026-10-14',
        wakingSeconds: 14 * 3600,
        totalPlannedSeconds: 10 * 3600,
        totalActualSeconds: 10 * 3600 + 1800, // 10h 30m (30m over)
        serverTime: DateTime.now(),
        categories: const [
          CategorySummaryModel(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColorHex: '#4A6B82',
            plannedSeconds: 10 * 3600,
            actualSeconds: 10 * 3600 + 1800,
            remainingSeconds: -1800,
            overtimeSeconds: 1800,
            isRunning: false,
          ),
        ],
      );

      final state = SummaryState(
        summary: summary,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Your day unfolded.'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('over planned time'), findsOneWidget);
    });
  });
}
