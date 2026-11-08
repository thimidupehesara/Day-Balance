import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:day_balance/features/onboarding/presentation/onboarding_categories_screen.dart';
import 'package:day_balance/features/onboarding/data/onboarding_repository.dart';
import 'package:day_balance/core/constants/categories.dart';
import 'package:day_balance/core/theme/app_theme.dart';
import 'package:dio/dio.dart';

class CategoryTestRepository extends OnboardingRepository {
  CategoryTestRepository() : super(Dio());
  bool fail = false;
  final saved = [...kCategories];
  @override
  Future<List<Category>> getAvailableCategories() async => [...saved];
  @override
  Future<Category> createCustomCategory({
    required String name,
    required String description,
    required String color,
  }) async {
    if (fail) throw Exception('Could not save. Please try again.');
    final category = Category(
      id: 'custom:test:guitar',
      name: name,
      description: description,
      color: Color(int.parse('FF${color.substring(1)}', radix: 16)),
      icon: Icons.category_outlined,
      sortOrder: 100,
    );
    saved.add(category);
    return category;
  }
}

void main() {
  testWidgets(
    'OnboardingCategoriesScreen renders all 7 categories and supports toggling',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(
              CategoryTestRepository(),
            ),
          ],
          child: const MaterialApp(home: OnboardingCategoriesScreen()),
        ),
      );

      expect(find.text('Your categories'), findsOneWidget);
      expect(find.text('What fills your day?'), findsOneWidget);
      expect(
        find.text('Keep what fits. You can change these later.'),
        findsOneWidget,
      );

      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Life/Family'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.text('Personal/Reading'), findsOneWidget);
      expect(find.text('Career'), findsOneWidget);
      expect(find.text('Unplanned/Extra capacity'), findsOneWidget);
      expect(find.text('Rest/Recovery'), findsOneWidget);

      expect(find.text('7 categories selected'), findsOneWidget);
      expect(find.text('Plan my day'), findsOneWidget);

      // Tap on Academic to deselect
      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();

      expect(find.text('6 categories selected'), findsOneWidget);

      // Tap again to reselect
      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();

      expect(find.text('7 categories selected'), findsOneWidget);
    },
  );

  testWidgets(
    'Plan my day button navigates to /onboarding/setting-up without saving directly',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding/categories',
        routes: [
          GoRoute(
            path: '/onboarding/categories',
            builder: (context, state) => const OnboardingCategoriesScreen(),
          ),
          GoRoute(
            path: '/onboarding/setting-up',
            builder: (context, state) =>
                const Scaffold(body: Text('Setting Up Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(
              CategoryTestRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(find.text('Plan my day'), findsOneWidget);

      // Scroll Plan my day button into view and tap
      await tester.ensureVisible(find.text('Plan my day'));
      await tester.tap(find.text('Plan my day'));
      await tester.pumpAndSettle();

      // Verify it navigates to /onboarding/setting-up
      expect(find.text('Setting Up Screen'), findsOneWidget);
    },
  );
  testWidgets(
    'Custom category validates, retries without losing input, and persists after remount',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = CategoryTestRepository();
      Widget page() => ProviderScope(
        overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingCategoriesScreen(),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add custom category'));
      await tester.tap(find.text('Add custom category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a category name'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Academic');
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      expect(find.text('That category already exists'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Guitar practice',
      );
      repo.fail = true;
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save. Please try again.'), findsWidgets);
      expect(find.text('Guitar practice'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('8 categories selected'), findsOneWidget);
      expect(repo.saved.last.name, 'Guitar practice');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('Guitar practice'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
