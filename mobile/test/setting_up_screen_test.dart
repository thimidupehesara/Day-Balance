import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:day_balance/features/auth/domain/user_model.dart';
import 'package:day_balance/features/onboarding/data/onboarding_repository.dart';
import 'package:day_balance/features/onboarding/presentation/setting_up_screen.dart';
import 'package:day_balance/features/onboarding/presentation/setting_up_constants.dart';

class FakeOnboardingRepository extends OnboardingRepository {
  bool shouldFail = false;
  int saveCount = 0;
  Map<String, dynamic> statsResponse = {
    'showable': true,
    'similarCount': 35,
    'totalUsers': 50,
  };

  FakeOnboardingRepository() : super(Dio());

  @override
  Future<Map<String, dynamic>> getSimilarRoutines({
    String? wakeTime,
    String? bedtime,
  }) async {
    return statsResponse;
  }

  @override
  Future<UserModel> updateProfile({
    String? wakeTime,
    String? bedtime,
    int? routineMinutes,
    bool? onboardingDone,
    String? displayName,
  }) async {
    if (shouldFail) {
      throw Exception('Network connection timed out');
    }
    return UserModel(
      id: 'test-user',
      email: 'test@example.com',
      displayName: 'Tester',
      wakeTime: wakeTime,
      bedtime: bedtime,
      routineMinutes: routineMinutes,
      onboardingDone: onboardingDone ?? false,
    );
  }

  @override
  Future<List<String>> updateUserCategories(List<String> categoryIds) async {
    saveCount++;
    if (shouldFail) {
      throw Exception('Network connection timed out');
    }
    return categoryIds;
  }
}

void main() {
  late FakeOnboardingRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeOnboardingRepository();
  });

  Widget createWidgetUnderTest({
    GoRouter? customRouter,
    bool disableAnimations = false,
  }) {
    final router = customRouter ??
        GoRouter(
          initialLocation: '/onboarding/setting-up',
          routes: [
            GoRoute(
              path: '/onboarding/categories',
              builder: (context, state) => const Scaffold(body: Text('Categories Screen')),
            ),
            GoRoute(
              path: '/onboarding/setting-up',
              builder: (context, state) => const SettingUpScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(body: Text('Today Screen')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
  }

  group('SettingUpScreen Widget Tests', () {
    testWidgets('shows calm sky animation, semantics label, and initial rhythm text',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Semantics label present
      expect(find.bySemanticsLabel('Setting up your day. Please wait.'), findsOneWidget);

      // RepaintBoundary wrapping the SkyPainter CustomPaint
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);

      // Initial text line
      expect(find.text(SettingUpTexts.readingRhythm), findsOneWidget);

      // Fast forward past the 4.5s delay + 300ms confirmation pause
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pump(const Duration(milliseconds: 500));

      // Tap continue button
      await tester.tap(find.text(SettingUpTexts.continueButton));
      await tester.pumpAndSettle();
      expect(find.text('Today Screen'), findsOneWidget);
    });

    testWidgets('waits minimum ~4.5 seconds before navigating to /home on success',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // At 2 seconds: save is complete, but minimum time (4.5s) has NOT passed
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Today Screen'), findsNothing);

      // Advance past 4.5s minimum display time + 300ms confirmation pause
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully routed after tapping continue
      await tester.tap(find.text(SettingUpTexts.continueButton));
      await tester.pumpAndSettle();
      expect(find.text('Today Screen'), findsOneWidget);
    });

    testWidgets('failure shows screen 16 error state with Try again and Back buttons',
        (tester) async {
      fakeRepo.shouldFail = true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      // Error UI visible immediately
      expect(find.text(SettingUpTexts.errorTitle), findsOneWidget);
      expect(find.text(SettingUpTexts.tryAgainButton), findsOneWidget);
      expect(find.text(SettingUpTexts.backButton), findsOneWidget);

      // Did not navigate to /home
      expect(find.text('Today Screen'), findsNothing);
    });

    testWidgets('Try again repeats the save operation', (tester) async {
      fakeRepo.shouldFail = true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(fakeRepo.saveCount, 1);
      expect(find.text(SettingUpTexts.tryAgainButton), findsOneWidget);

      // Now succeed on retry
      fakeRepo.shouldFail = false;
      await tester.tap(find.text(SettingUpTexts.tryAgainButton));
      await tester.pump();
      await tester.pump();

      // Wait for second save cycle (4.5s + 300ms)
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeRepo.saveCount, 2);
      await tester.tap(find.text(SettingUpTexts.continueButton));
      await tester.pumpAndSettle();
      expect(find.text('Today Screen'), findsOneWidget);
    });

    testWidgets('Back button returns to categories keeping selections', (tester) async {
      fakeRepo.shouldFail = true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.text(SettingUpTexts.backButton), findsOneWidget);

      // Tap Back
      await tester.tap(find.text(SettingUpTexts.backButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Categories Screen'), findsOneWidget);
    });

    testWidgets('reduce-motion mode renders static sun and simple progress indicator',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(disableAnimations: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // CircularProgressIndicator present in reduce-motion mode
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(SettingUpTexts.readingRhythm), findsOneWidget);

      // Complete minimum display time + confirmation pause
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(SettingUpTexts.continueButton));
      await tester.pumpAndSettle();
      expect(find.text('Today Screen'), findsOneWidget);
    });
  });
}
