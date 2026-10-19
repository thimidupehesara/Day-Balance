import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/onboarding/presentation/onboarding_schedule_screen.dart';
import '../../features/onboarding/presentation/onboarding_routine_screen.dart';
import '../../features/onboarding/presentation/onboarding_result_screen.dart';
import '../../features/onboarding/presentation/onboarding_categories_screen.dart';
import '../../features/onboarding/presentation/setting_up_screen.dart';
import '../../features/planning/presentation/plan_screen.dart';
import '../../features/timer/presentation/today_screen.dart';
import '../../features/timer/presentation/active_timer_screen.dart';
import 'app_transitions.dart';

// Placeholder screens — will be replaced with real implementations
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

/// App router configuration using go_router with smooth CustomTransitionPage transitions.
final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    // Auth & Welcome (SharedAxis)
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const RegisterScreen(),
      ),
    ),

    // Onboarding (FadeThrough from Auth into Step 1, then SharedAxis between steps)
    GoRoute(
      path: '/onboarding/schedule',
      name: 'onboarding-schedule',
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        state: state,
        child: const OnboardingScheduleScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/routine',
      name: 'onboarding-routine',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const OnboardingRoutineScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/result',
      name: 'onboarding-result',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const OnboardingResultScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/categories',
      name: 'onboarding-categories',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const OnboardingCategoriesScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/setting-up',
      name: 'onboarding-setting-up',
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        state: state,
        child: const SettingUpScreen(),
      ),
    ),

    // Main app (FadeThrough into /home, SharedAxis for subpages)
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        state: state,
        child: const TodayScreen(),
      ),
    ),
    GoRoute(
      path: '/today',
      name: 'today',
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        state: state,
        child: const TodayScreen(),
      ),
    ),
    GoRoute(
      path: '/plan',
      name: 'plan',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const PlanScreen(),
      ),
    ),
    GoRoute(
      path: '/timer',
      name: 'timer',
      pageBuilder: (context, state) {
        final planItemId = state.uri.queryParameters['planItemId'];
        return AppTransitions.sharedAxis(
          state: state,
          child: ActiveTimerScreen(initialPlanItemId: planItemId),
        );
      },
    ),
    GoRoute(
      path: '/summary',
      name: 'summary',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const _PlaceholderScreen(title: 'Day Summary'),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => AppTransitions.sharedAxis(
        state: state,
        child: const _PlaceholderScreen(title: 'Settings'),
      ),
    ),
  ],
);
