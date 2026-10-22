import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:day_balance/features/planning/presentation/plan_controller.dart';
import 'package:day_balance/features/planning/presentation/plan_screen.dart';

class TestPlanController extends PlanController {
  final PlanState _initialState;
  TestPlanController(this._initialState);

  @override
  PlanState build() => _initialState;

  @override
  Future<void> initPlanForToday() async {}
}

void main() {
  Widget createWidget(PlanState state) {
    return ProviderScope(
      overrides: [
        planControllerProvider.overrideWith(() => TestPlanController(state)),
      ],
      child: const MaterialApp(
        home: PlanScreen(),
      ),
    );
  }

  group('PlanScreen Widget Tests', () {
    testWidgets('renders normal planning state (08_daily_planning)',
        (tester) async {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        selectedCategoryIds: ['academic', 'life_family', 'career'],
        plannedSeconds: {
          'academic': 4 * 3600,
          'life_family': 2 * 3600,
          'career': 1 * 3600 + 1800,
        }, // 7h 30m planned, 7h 00m left
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Plan your day'), findsOneWidget);
      expect(find.text('Hours left to plan'), findsOneWidget);
      expect(find.text('7h 00m'), findsOneWidget);
      expect(find.text('of 14h 30m'), findsOneWidget);

      // Selected categories displayed
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Life/Family'), findsOneWidget);
      expect(find.text('Career'), findsOneWidget);

      // Extra breathing room text
      expect(
        find.text('7h will stay as extra breathing room.'),
        findsOneWidget,
      );

      // Start button active
      expect(find.text('Start my day'), findsOneWidget);
    });

    testWidgets(
        'renders entertainment gentle nudge when entertainment > 30% of planned',
        (tester) async {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800,
        selectedCategoryIds: ['academic', 'entertainment'],
        plannedSeconds: {
          'academic': 4 * 3600,
          'entertainment': 3 * 3600, // 3h / 7h = 42.8%
        },
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '3h for Entertainment. Does that leave enough room for the rest of your day?',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders zero hours left state (08_daily_planning_zero_hours_left)',
        (tester) async {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        selectedCategoryIds: ['academic', 'life_family'],
        plannedSeconds: {
          'academic': 8 * 3600,
          'life_family': 6 * 3600 + 1800,
        }, // exactly 14h 30m
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('0h 00m'), findsOneWidget);
      expect(
        find.text(
          'Every hour has a place. You can adjust your plan as the day unfolds.',
        ),
        findsOneWidget,
      );
      expect(find.text('Start my day'), findsOneWidget);
    });

    testWidgets(
        'renders over-allocated state (08_daily_planning_over_allocated)',
        (tester) async {
      const state = PlanState(
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        selectedCategoryIds: ['academic', 'life_family'],
        plannedSeconds: {
          'academic': 9 * 3600,
          'life_family': 6 * 3600 + 1800,
        }, // 15h 30m planned = 1h over
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      // Negative hours left with minus
      expect(find.text('−1h 00m'), findsOneWidget);

      // Warning text
      expect(
        find.text(
          'You’re 1h over. Free up an hour before starting your day.',
        ),
        findsOneWidget,
      );

      // Disabled button with "Free up 1h to continue"
      expect(find.text('Free up 1h to continue'), findsOneWidget);
      expect(find.text('Start my day'), findsNothing);
    });
  });
}
