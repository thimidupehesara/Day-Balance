import '../../../shared/widgets/app_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/pill_stepper.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/step_progress_bar.dart';
import 'onboarding_controller.dart';

class OnboardingRoutineScreen extends ConsumerWidget {
  const OnboardingRoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Format info card calculation string
    final grossHours = state.grossWakingMinutes ~/ 60;
    final rHours = state.routineMinutes ~/ 60;
    final rMins = state.routineMinutes % 60;
    final rStr = rHours > 0 && rMins > 0
        ? '${rHours}h ${rMins}m'
        : rHours > 0
        ? '${rHours}h'
        : '${rMins}m';
    final topCardText = '${grossHours}h awake − $rStr of routines';

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
                      context.go('/onboarding/schedule');
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

                    // Step 2 of 3 Progress Bar
                    const StepProgressBar(currentStep: 2),
                    const SizedBox(height: 32),

                    // Headings
                    const Text(
                      'Leave room for the everyday.',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Getting ready and winding down count too. Set this time aside before you plan.',
                      style: AppTextStyles.body14,
                    ),
                    const SizedBox(height: 32),

                    // Morning Routine Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              AppIcons.morningRoutine,
                              size: 24,
                              color: AppColors.setupAccent,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Morning routine',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            PillStepper(
                              label: '${state.morningRoutineMinutes} min',
                              canDecrement: state.morningRoutineMinutes >= 15,
                              canIncrement:
                                  state.routineMinutes + 15 <=
                                  state.grossWakingMinutes,
                              onDecrement: () {
                                controller.setMorningRoutineMinutes(
                                  state.morningRoutineMinutes - 15,
                                );
                              },
                              onIncrement: () {
                                controller.setMorningRoutineMinutes(
                                  state.morningRoutineMinutes + 15,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 36),
                          child: Text(
                            'Get ready, eat, ease into the day.',
                            style: AppTextStyles.body14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Wind-up Routine Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              AppIcons.windUpRoutine,
                              size: 24,
                              color: AppColors.setupAccent,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Wind-up routine',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            PillStepper(
                              label: '${state.windUpRoutineMinutes} min',
                              canDecrement: state.windUpRoutineMinutes >= 15,
                              canIncrement:
                                  state.routineMinutes + 15 <=
                                  state.grossWakingMinutes,
                              onDecrement: () {
                                controller.setWindUpRoutineMinutes(
                                  state.windUpRoutineMinutes - 15,
                                );
                              },
                              onIncrement: () {
                                controller.setWindUpRoutineMinutes(
                                  state.windUpRoutineMinutes + 15,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 36),
                          child: Text(
                            'Unplug and get ready for bed.',
                            style: AppTextStyles.body14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Breakdown Info Card (Figma: #EEE8DC, radius 16)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.paper, AppColors.surface],
                        ),
                        border: Border.all(
                          color: AppColors.outline.withValues(alpha: .3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topCardText, style: AppTextStyles.body14),
                          const SizedBox(height: 8),
                          Text(
                            '${state.netHoursFormatted} to plan',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primarySage,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Routines stay protected, outside your plan.',
                            style: AppTextStyles.caption12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Caption
                    const Text(
                      'Adjust in 15-minute steps.',
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
                    ],

                    // Button: See my daily hours
                    AppPrimaryButton(
                      label: 'See my daily hours',
                      isLoading: state.isLoading,
                      onPressed: () async {
                        final ok = await controller.saveRoutine();
                        if (ok && context.mounted) {
                          context.go('/onboarding/result');
                        }
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
