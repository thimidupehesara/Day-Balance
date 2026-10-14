import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:day_balance/features/auth/domain/user_model.dart';
import 'package:day_balance/features/planning/domain/plan_model.dart';
import 'package:day_balance/features/timer/presentation/today_controller.dart';
import 'package:day_balance/features/timer/presentation/today_screen.dart';

class TestTodayController extends TodayController {
  final TodayTimerState _initialState;
  TestTodayController(this._initialState);

  @override
  TodayTimerState build() => _initialState;

  @override
  Future<void> fetchStatus() async {}
}

void main() {
  Widget createWidget(TodayTimerState state) {
    return ProviderScope(
      overrides: [
        todayControllerProvider.overrideWith(() => TestTodayController(state)),
      ],
      child: const MaterialApp(
        home: TodayScreen(),
      ),
    );
  }

  group('TodayScreen Widget Tests', () {
    testWidgets('renders before-planning state (09_today_home_before_planning)',
        (tester) async {
      final state = TodayTimerState(
        user: const UserModel(
          id: 'user-1',
          email: 'maya@example.com',
          displayName: 'Maya',
          wakeTime: '7:00',
          bedtime: '23:00',
          routineMinutes: 90,
          onboardingDone: true,
        ),
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        planId: null,
        items: const [],
        now: DateTime(2026, 10, 14, 9, 41),
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      // Top info
      expect(find.text('Hello, Maya'), findsOneWidget);
      expect(find.text('Total hours left'), findsOneWidget);
      expect(find.text('14h 30m'), findsOneWidget);

      // Before planning content
      expect(
        find.text('A fresh day. A little room to choose.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'You haven’t made a plan yet. Give your hours a place, then start one thing at a time.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('7:00 – 23:00 · routines already set aside'),
        findsOneWidget,
      );
      expect(find.text('Plan today'), findsOneWidget);

      // Edit plan button should not be present when no plan exists
      expect(find.byTooltip('Edit plan'), findsNothing);
    });

    testWidgets('renders planned home state with running card (09_today_home)',
        (tester) async {
      final localNow = DateTime(2026, 10, 14, 10, 0, 0);
      final startedAt = DateTime(2026, 10, 14, 10, 0, 0);

      final academicItem = PlanItemModel(
        id: 'item-1',
        dailyPlanId: 'plan-1',
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryDescription: '',
        categoryColor: '#D4DEE5',
        categoryIcon: 'school',
        plannedSeconds: 4 * 3600,
        remainingSeconds: 2 * 3600 + 45 * 60, // 2:45:00
        startedAt: startedAt,
      );

      final lifeItem = PlanItemModel(
        id: 'item-2',
        dailyPlanId: 'plan-1',
        categoryId: 'life_family',
        categoryName: 'Life/Family',
        categoryDescription: '',
        categoryColor: '#EBD3BC',
        categoryIcon: 'home',
        plannedSeconds: 2 * 3600,
        remainingSeconds: 2 * 3600,
      );

      final state = TodayTimerState(
        user: const UserModel(
          id: 'user-1',
          email: 'maya@example.com',
          displayName: 'Maya',
          wakeTime: '7:00',
          bedtime: '23:00',
          routineMinutes: 90,
          onboardingDone: true,
        ),
        planId: 'plan-1',
        items: [academicItem, lifeItem],
        activeItemId: 'item-1',
        activeStartedAt: startedAt,
        activeRemainingSeconds: 2 * 3600 + 45 * 60,
        serverOffset: Duration.zero,
        now: localNow,
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      // Running category card
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('● RUNNING'), findsOneWidget);
      expect(find.text('2:45:00'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      // Idle category card
      expect(find.text('Life/Family'), findsOneWidget);
      expect(find.text('Planned 2h'), findsOneWidget);
      expect(find.text('2h 00m'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('renders overtime state card (09_today_home_overtime)',
        (tester) async {
      final localNow = DateTime(2026, 10, 14, 11, 0, 0);
      final startedAt = DateTime(2026, 10, 14, 10, 0, 0);

      // 1 hour elapsed (3600s), remaining was 2850s -> overtime of 750s (12m 30s)
      final academicItem = PlanItemModel(
        id: 'item-1',
        dailyPlanId: 'plan-1',
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryDescription: '',
        categoryColor: '#D4DEE5',
        categoryIcon: 'school',
        plannedSeconds: 4 * 3600,
        remainingSeconds: 2850,
        startedAt: startedAt,
      );

      final state = TodayTimerState(
        planId: 'plan-1',
        items: [academicItem],
        activeItemId: 'item-1',
        activeStartedAt: startedAt,
        activeRemainingSeconds: 2850,
        serverOffset: Duration.zero,
        now: localNow,
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('OVERTIME'), findsOneWidget);
      expect(find.text('+0:12:30 over'), findsOneWidget);
      expect(find.text('Planned 4h · 4h 12m used'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets(
        'renders offline empty state matching Figma screen 16 (16_empty_error_states_no_connection)',
        (tester) async {
      final state = TodayTimerState(
        isOffline: true,
        items: const [],
        now: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('A little offline.'), findsOneWidget);
      expect(
        find.text(
          'We can’t connect right now. Your last saved plan is safe on this device.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
