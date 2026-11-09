import '../../../shared/widgets/app_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/category_tile.dart';
import '../../../shared/widgets/primary_button.dart';
import 'onboarding_controller.dart';
import 'custom_category_dialog.dart';

class OnboardingCategoriesScreen extends ConsumerStatefulWidget {
  const OnboardingCategoriesScreen({super.key});

  @override
  ConsumerState<OnboardingCategoriesScreen> createState() =>
      _OnboardingCategoriesScreenState();
}

class _OnboardingCategoriesScreenState
    extends ConsumerState<OnboardingCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(onboardingControllerProvider.notifier)
            .loadAvailableCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return AppPage(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button and "Your categories" title
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
              child: Row(
                children: [
                  AppBackButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/onboarding/result');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    'Your categories',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  )),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Headings
                    const Text('What fills your day?', style: AppTextStyles.h1),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep what fits. You can change these later.',
                      style: AppTextStyles.body14,
                    ),
                    const SizedBox(height: 24),

                    // 7 Category Tiles
                    ...state.availableCategories.map((cat) {
                      final isSelected = state.selectedCategories.contains(
                        cat.id,
                      );
                      return CategoryTile(
                        category: cat,
                        isSelected: isSelected,
                        onToggle: () => controller.toggleCategory(cat.id),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add custom category'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.setupAccent,
                        side: const BorderSide(color: AppColors.outline),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: state.isLoading
                          ? null
                          : () => showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const CustomCategoryDialog(),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Counter text: "X categories selected"
                    Text(
                      '${state.selectedCategories.length} categories selected',
                      style: AppTextStyles.caption12,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle caption
                    const Text(
                      'Make space for your own priorities. Custom categories are private to you.',
                      style: AppTextStyles.caption12,
                    ),
                    const SizedBox(height: 16),

                    if (state.errorMessage != null) ...[
                      Text(
                        state.errorMessage!,
                        style: AppTextStyles.caption12.copyWith(
                          color: AppColors.errorRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: controller.loadAvailableCategories,
                        child: const Text('Retry loading categories'),
                      ),
                    ],

                    // Primary Button: "Plan my day"
                    AppPrimaryButton(
                      label: 'Plan my day',
                      isEnabled:
                          state.selectedCategories.isNotEmpty &&
                          !state.isLoading,
                      onPressed: () {
                        context.go('/onboarding/setting-up');
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
