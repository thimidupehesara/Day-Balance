import '../../../shared/widgets/app_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/step_progress_bar.dart';
import 'onboarding_controller.dart';

class OnboardingResultScreen extends ConsumerWidget {
  const OnboardingResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);

    return AppPage(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Back Button
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/onboarding/routine');
                    }
                  },
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Step 3 of 3 Progress Bar
                    const StepProgressBar(currentStep: 3),
                    const SizedBox(height: 32),

                    // Illustration / Sun icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sageContainer,
                        ),
                        child: const Icon(
                          AppIcons.hoursAwake,
                          size: 44,
                          color: AppColors.primarySage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Headline block
                    const Text('You have', style: AppTextStyles.h1),
                    const SizedBox(height: 8),
                    Text(
                      state.netHoursFormatted,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySage,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'per day. Let’s plan it.',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 32),

                    // Breakdown List
                    _BreakdownRow(
                      label: 'Hours awake',
                      value: state.grossHoursFormatted,
                    ),
                    const SizedBox(height: 12),
                    _BreakdownRow(
                      label: 'Morning routine',
                      value: '− ${state.morningRoutineMinutes}m',
                    ),
                    const SizedBox(height: 12),
                    _BreakdownRow(
                      label: 'Wind-up routine',
                      value: '− ${state.windUpRoutineMinutes}m',
                    ),
                    const SizedBox(height: 16),

                    // Divider line
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 16),

                    // Note on breathing room
                    const Text(
                      'Not every hour needs a job. A little breathing room is part of a good plan.',
                      style: AppTextStyles.body14,
                    ),
                    const SizedBox(height: 32),

                    // Primary Button: Choose my categories
                    AppPrimaryButton(
                      label: 'Choose my categories',
                      onPressed: () => context.go('/onboarding/categories'),
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

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body14),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
