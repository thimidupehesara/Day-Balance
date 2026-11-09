import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:day_balance/core/theme/app_theme.dart';
import 'package:day_balance/core/constants/categories.dart';
import 'package:day_balance/features/auth/presentation/welcome_screen.dart';
import 'package:day_balance/features/auth/presentation/register_screen.dart';
import 'package:day_balance/features/auth/presentation/login_screen.dart';
import 'package:day_balance/features/onboarding/presentation/onboarding_schedule_screen.dart';
import 'package:day_balance/features/onboarding/presentation/onboarding_routine_screen.dart';
import 'package:day_balance/features/onboarding/presentation/onboarding_categories_screen.dart';
import 'package:day_balance/features/onboarding/data/onboarding_repository.dart';
import 'package:day_balance/features/planning/presentation/plan_screen.dart';
import 'package:day_balance/features/planning/presentation/plan_controller.dart';
import 'package:day_balance/features/planning/domain/plan_model.dart';
import 'package:day_balance/features/timer/presentation/today_controller.dart';
import 'package:day_balance/features/timer/presentation/today_screen.dart';
import 'package:day_balance/features/timer/presentation/active_timer_screen.dart';
import 'package:day_balance/features/summary/presentation/summary_controller.dart';
import 'package:day_balance/features/summary/presentation/summary_screen.dart';
import 'package:day_balance/features/summary/domain/summary_model.dart';
import 'onboarding_categories_screen_test.dart' show CategoryTestRepository;
import 'plan_screen_test.dart' show TestPlanController;
import 'today_screen_test.dart' show TestTodayController;
import 'summary_screen_test.dart' show TestSummaryController;

void main() {
  testWidgets('all redesigned pages fit phone widths and enlarged text', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final items = kCategories.take(3).map((c) => PlanItemModel(id: c.id, dailyPlanId: 'demo', categoryId: c.id,
      categoryName: c.name, categoryDescription: c.description, categoryColor: '#B9D0DA', categoryIcon: 'category',
      plannedSeconds: 7200, remainingSeconds: 5400)).toList();
    final timer = TodayTimerState(now: DateTime(2026, 11, 8, 12), planId: 'demo', items: items, wakingSeconds: 52200);
    final summary = PlanSummaryModel(planId: 'demo', planDate: '2026-11-08', wakingSeconds: 52200,
      totalPlannedSeconds: 21600, totalActualSeconds: 18000, serverTime: DateTime(2026, 11, 8, 22),
      categories: items.map((i) => CategorySummaryModel(categoryId: i.categoryId, categoryName: i.categoryName,
        categoryColorHex: i.categoryColor, plannedSeconds: 7200, actualSeconds: 6000, remainingSeconds: 1200,
        overtimeSeconds: 0, isRunning: false)).toList());
    final pages = <String, Widget>{'welcome': const WelcomeScreen(), 'register': const RegisterScreen(),
      'login': const LoginScreen(), 'schedule': const OnboardingScheduleScreen(), 'routine': const OnboardingRoutineScreen(),
      'categories': const OnboardingCategoriesScreen(), 'plan': const PlanScreen(), 'zero': const PlanScreen(),
      'over': const PlanScreen(), 'today': const TodayScreen(), 'timer': const ActiveTimerScreen(), 'summary': const SummaryScreen()};
    for (final size in [const Size(390, 840), const Size(320, 700)]) {
      tester.view.physicalSize = size;
      for (final entry in pages.entries) {
        await tester.pumpWidget(const SizedBox());
        final key = GlobalKey();
        final seconds = <String, int>{for (final c in kCategories) c.id: 7200};
        seconds['academic'] = entry.key == 'over' ? 14400 : entry.key == 'zero' ? 9000 : 7200;
        await tester.pumpWidget(ProviderScope(overrides: [
          onboardingRepositoryProvider.overrideWithValue(CategoryTestRepository()),
          planControllerProvider.overrideWith(() => TestPlanController(PlanState(wakingSeconds: 52200,
            selectedCategoryIds: kCategories.map((c) => c.id).toList(), plannedSeconds: seconds))),
          todayControllerProvider.overrideWith(() => TestTodayController(timer)),
          summaryControllerProvider.overrideWith(() => TestSummaryController(SummaryState(summary: summary, date: DateTime(2026, 11, 8)))),
        ], child: MaterialApp(theme: AppTheme.light, builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(size.width == 320 ? 1.5 : 1)), child: child!),
          home: RepaintBoundary(key: key, child: entry.value))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${entry.key} at $size');

      }
    }
  });
}
