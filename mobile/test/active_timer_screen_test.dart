import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:day_balance/features/planning/domain/plan_model.dart';
import 'package:day_balance/features/timer/presentation/active_timer_screen.dart';
import 'package:day_balance/features/timer/presentation/today_controller.dart';

class TestTodayController extends TodayController {
  final TodayTimerState _initialState;
  bool pausedCalled = false;
  String? startedPlanItemId;

  TestTodayController(this._initialState);

  @override
  TodayTimerState build() => _initialState;

  @override
  Future<void> fetchStatus() async {}

  @override
  Future<void> pauseTimer() async {
    pausedCalled = true;
  }

  @override
  Future<void> startTimer(String planItemId) async {
    startedPlanItemId = planItemId;
  }
}

void main() {
  final academicItem = PlanItemModel(
    id: 'item-1',
    dailyPlanId: 'plan-1',
    categoryId: 'academic',
    categoryName: 'Academic',
    categoryDescription: 'Study, lectures, reading',
    categoryColor: '#D4DEE5',
    categoryIcon: 'school',
    plannedSeconds: 4 * 3600, // 4h
    remainingSeconds: 2 * 3600 + 45 * 60, // 2h 45m
    startedAt: DateTime(2026, 10, 14, 8, 26),
  );

  final lifeFamilyItem = PlanItemModel(
    id: 'item-2',
    dailyPlanId: 'plan-1',
    categoryId: 'life_family',
    categoryName: 'Life/Family',
    categoryDescription: 'Cooking, chores, family time',
    categoryColor: '#EBD3BC',
    categoryIcon: 'home',
    plannedSeconds: 2 * 3600,
    remainingSeconds: 2 * 3600,
  );

  final careerItem = PlanItemModel(
    id: 'item-3',
    dailyPlanId: 'plan-1',
    categoryId: 'career',
    categoryName: 'Career',
    categoryDescription: 'Work, meetings, projects',
    categoryColor: '#C9DEDA',
    categoryIcon: 'work',
    plannedSeconds: 2 * 3600,
    remainingSeconds: 2 * 3600,
  );

  Widget createWidget({
    required TodayTimerState state,
    required TestTodayController controller,
    String? initialPlanItemId,
  }) {
    return ProviderScope(
      overrides: [
        todayControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp(
        home: ActiveTimerScreen(initialPlanItemId: initialPlanItemId),
      ),
    );
  }

  group('ActiveTimerScreen Widget Tests', () {
    testWidgets('renders all Figma 10_active_timer elements when running',
        (tester) async {
      final state = TodayTimerState(
        planId: 'plan-1',
        items: [academicItem, lifeFamilyItem, careerItem],
        activeItemId: 'item-1',
        activeStartedAt: DateTime(2026, 10, 14, 8, 26),
        activeRemainingSeconds: 2 * 3600 + 45 * 60,
        now: DateTime(2026, 10, 14, 8, 26), // 0 seconds elapsed since start
      );

      final controller = TestTodayController(state);

      await tester.pumpWidget(createWidget(
        state: state,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Top bar
      expect(find.text('Focus time'), findsOneWidget);
      expect(find.text('End session'), findsOneWidget);

      // Active category header
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Just this, for now.'), findsOneWidget);

      // Dial countdown and subtitle
      expect(find.text('2:45:00'), findsOneWidget);
      expect(find.text('remaining of 4h 00m'), findsOneWidget);

      // Running status line
      expect(
        find.text('Running since 8:26 AM · 1h 15m used'),
        findsOneWidget,
      );

      // Action buttons
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);

      // Move to something else section
      expect(find.text('MOVE TO SOMETHING ELSE'), findsOneWidget);
      expect(find.text('Life/Family'), findsOneWidget);
      expect(find.text('Career'), findsOneWidget);
      expect(
        find.text('Switching pauses Academic. Your time stays here.'),
        findsOneWidget,
      );
    });

    testWidgets('Pause button triggers controller.pauseTimer()', (tester) async {
      final state = TodayTimerState(
        planId: 'plan-1',
        items: [academicItem, lifeFamilyItem],
        activeItemId: 'item-1',
        activeStartedAt: DateTime(2026, 10, 14, 8, 26),
        activeRemainingSeconds: 2 * 3600 + 45 * 60,
        now: DateTime(2026, 10, 14, 8, 26),
      );

      final controller = TestTodayController(state);

      await tester.pumpWidget(createWidget(
        state: state,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pause'));
      await tester.pump();

      expect(controller.pausedCalled, isTrue);
    });

    testWidgets('Resume button shown when paused, and triggers startTimer()',
        (tester) async {
      final state = TodayTimerState(
        planId: 'plan-1',
        items: [academicItem, lifeFamilyItem],
        activeItemId: null, // Paused
        now: DateTime(2026, 10, 14, 9, 0),
      );

      final controller = TestTodayController(state);

      await tester.pumpWidget(createWidget(
        state: state,
        controller: controller,
        initialPlanItemId: 'item-1',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();

      expect(controller.startedPlanItemId, equals('item-1'));
    });

    testWidgets('renders overtime state correctly', (tester) async {
      // 10 minutes past planned time
      final overtimeItem = PlanItemModel(
        id: 'item-1',
        dailyPlanId: 'plan-1',
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryDescription: 'Study',
        categoryColor: '#D4DEE5',
        categoryIcon: 'school',
        plannedSeconds: 4 * 3600,
        remainingSeconds: -600, // 10 minutes overtime
      );

      final state = TodayTimerState(
        planId: 'plan-1',
        items: [overtimeItem],
        activeItemId: null,
        now: DateTime(2026, 10, 14, 12, 40),
      );

      final controller = TestTodayController(state);

      await tester.pumpWidget(createWidget(
        state: state,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      expect(find.text('+0:10:00 over'), findsOneWidget);
      expect(find.text('overtime'), findsOneWidget);
    });

    testWidgets(
        'Tapping an other category card opens SwitchSheet and confirms switch',
        (tester) async {
      final state = TodayTimerState(
        planId: 'plan-1',
        items: [academicItem, lifeFamilyItem],
        activeItemId: 'item-1',
        activeStartedAt: DateTime(2026, 10, 14, 8, 26),
        activeRemainingSeconds: 2 * 3600 + 45 * 60,
        now: DateTime(2026, 10, 14, 8, 26),
      );

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TestTodayController(state);

      await tester.pumpWidget(createWidget(
        state: state,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Ensure visible and tap on Life/Family card under MOVE TO SOMETHING ELSE
      await tester.ensureVisible(find.text('Life/Family'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Life/Family'));
      await tester.pumpAndSettle();

      // Check Switch Sheet opened
      expect(
        find.text('Pause Academic and start Life/Family?'),
        findsOneWidget,
      );

      // Confirm switch
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(controller.startedPlanItemId, equals('item-2'));
    });
  });
}
