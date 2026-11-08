import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:day_balance/features/auth/domain/user_model.dart';
import 'package:day_balance/features/onboarding/data/onboarding_repository.dart';
import 'package:day_balance/features/onboarding/presentation/setting_up_screen.dart';
import 'package:day_balance/features/onboarding/presentation/setting_up_sky.dart';

class FakeOnboardingRepository extends OnboardingRepository {
  bool shouldFail = false;
  int saveCount = 0;
  Completer<void>? pending;
  FakeOnboardingRepository() : super(Dio());
  @override
  Future<List<String>> updateUserCategories(List<String> categoryIds) async {
    saveCount++;
    if (pending != null) await pending!.future;
    if (shouldFail) throw Exception('Network connection timed out');
    return categoryIds;
  }

  @override
  Future<UserModel> updateProfile({
    String? wakeTime,
    String? bedtime,
    int? routineMinutes,
    bool? onboardingDone,
    String? displayName,
  }) async {
    return UserModel(
      id: 'test-user',
      email: 'test@example.com',
      wakeTime: wakeTime,
      bedtime: bedtime,
      routineMinutes: routineMinutes,
      onboardingDone: onboardingDone ?? false,
    );
  }
}

Widget loadingTestApp(
  FakeOnboardingRepository repo, {
  bool reduced = false,
  double scale = 1,
}) {
  final router = GoRouter(
    initialLocation: '/setup',
    routes: [
      GoRoute(path: '/setup', builder: (_, _) => const SettingUpScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Today Screen')),
      ),
      GoRoute(
        path: '/onboarding/categories',
        builder: (_, _) => const Scaffold(body: Text('Categories Screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
    ),
  );
}

Future<void> tapVisible(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  test('sun and moon use a shared left-to-right rising and setting arc', () {
    final start = SettingUpSkyPainter.orbit(0, 390, 373);
    final top = SettingUpSkyPainter.orbit(.5, 390, 373);
    final end = SettingUpSkyPainter.orbit(1, 390, 373);
    expect(start.dx, lessThan(top.dx));
    expect(top.dx, lessThan(end.dx));
    expect(top.dy, lessThan(start.dy));
    expect(end.dy, start.dy);
    expect(
      SettingUpSkyPainter.orbit(.25, 390, 373).dy,
      closeTo(SettingUpSkyPainter.orbit(.75, 390, 373).dy, .001),
    );
  });

  testWidgets('fast save still presents every chapter before Continue', (
    tester,
  ) async {
    final repo = FakeOnboardingRepository();
    await tester.pumpWidget(loadingTestApp(repo));
    await tester.pump();
    expect(find.text('KNOW YOUR TIME'), findsOneWidget);
    expect(find.text('Step into my day'), findsNothing);
    for (final title in [
      'CHOOSE WHAT MATTERS',
      'ONE THING AT A TIME',
      'LEARN YOUR RHYTHM',
    ]) {
      await tester.pump(const Duration(seconds: 4));
      expect(find.text(title), findsOneWidget);
      expect(find.text('Step into my day'), findsNothing);
    }
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));
    await tapVisible(tester, 'Step into my day');
    expect(find.text('Today Screen'), findsOneWidget);
    expect(repo.saveCount, 1);
  });

  testWidgets('slow save cannot navigate when the animation finishes', (
    tester,
  ) async {
    final repo = FakeOnboardingRepository()..pending = Completer<void>();
    await tester.pumpWidget(loadingTestApp(repo));
    await tester.pump();
    await tester.pump(const Duration(seconds: 17));
    expect(find.text('Saving your preferences…'), findsOneWidget);
    expect(find.text('Step into my day'), findsNothing);
    repo.pending!.complete();
    await tester.pump();
    await tapVisible(tester, 'Step into my day');
    expect(find.text('Today Screen'), findsOneWidget);
  });

  testWidgets('error is immediate and retry starts a fresh save and sequence', (
    tester,
  ) async {
    final repo = FakeOnboardingRepository()..shouldFail = true;
    await tester.pumpWidget(loadingTestApp(repo));
    await tester.pump();
    expect(find.text("Couldn't save your day"), findsOneWidget);
    repo.shouldFail = false;
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('KNOW YOUR TIME'), findsOneWidget);
    await tester.pump(const Duration(seconds: 17));
    await tapVisible(tester, 'Step into my day');
    expect(repo.saveCount, 2);
    expect(find.text('Today Screen'), findsOneWidget);
  });

  testWidgets('error Back returns to category selection', (tester) async {
    await tester.pumpWidget(
      loadingTestApp(FakeOnboardingRepository()..shouldFail = true),
    );
    await tester.pump();
    await tapVisible(tester, 'Back');
    expect(find.text('Categories Screen'), findsOneWidget);
  });

  testWidgets('reduced motion has a static scene and no artificial wait', (
    tester,
  ) async {
    await tester.pumpWidget(
      loadingTestApp(FakeOnboardingRepository(), reduced: true),
    );
    await tester.pump();
    final sky = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<SettingUpSkyPainter>()
        .single;
    expect(sky.reduceMotion, isTrue);
    await tapVisible(tester, 'Step into my day');
    expect(find.text('Today Screen'), findsOneWidget);
  });

  testWidgets('small screen and enlarged text keep copy above progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      loadingTestApp(FakeOnboardingRepository(), scale: 1.6),
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      if (i > 0) await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      final progress = tester.getRect(find.byType(LinearProgressIndicator));
      final title = tester.getRect(
        find.text(
          [
            'A day that fits\nyour life.',
            'Make room\nfor your priorities.',
            'Be here.\nOne moment fully.',
            'See your day.\nShape tomorrow.',
          ][i],
        ),
      );
      expect(progress.top, greaterThan(title.bottom + 32));
    }
    await tester.pump(const Duration(seconds: 4));
    await tapVisible(tester, 'Step into my day');
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during a pending save leaves no callbacks or timers', (
    tester,
  ) async {
    final repo = FakeOnboardingRepository()..pending = Completer<void>();
    await tester.pumpWidget(loadingTestApp(repo));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    repo.pending!.complete();
    await tester.pump(const Duration(seconds: 20));
    expect(tester.takeException(), isNull);
  });
}
