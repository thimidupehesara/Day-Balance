import '../../../shared/widgets/app_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_time_picker.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/step_progress_bar.dart';
import '../../../shared/widgets/tap_field.dart';
import 'onboarding_controller.dart';

class OnboardingScheduleScreen extends ConsumerWidget {
  const OnboardingScheduleScreen({super.key});

  String _formatTime(TimeOfDay t) {
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Calculate awake and sleep progress fractions
    final double awakeFraction = (state.grossWakingMinutes / (24 * 60)).clamp(
      0.05,
      0.95,
    );
    final double sleepFraction = 1.0 - awakeFraction;

    return AppPage(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/register');
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

                    // Step 1 of 3 Progress Bar
                    const StepProgressBar(currentStep: 1),
                    const SizedBox(height: 32),

                    // Headings
                    const Text(
                      'When does your day begin?',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start with your usual rhythm. You can change this whenever life shifts.',
                      style: AppTextStyles.body14,
                    ),
                    const SizedBox(height: 32),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked =
                            constraints.maxWidth < 310 ||
                            MediaQuery.textScalerOf(context).scale(16) > 21;
                        final width = stacked
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 24,
                          children: [
                            SizedBox(
                              width: width,
                              child: TapField(
                                label: 'Wake-up time',
                                value: _formatTime(state.wakeTime),
                                icon: Icons.wb_sunny_outlined,
                                onTap: () async {
                                  final picked = await showAppTimePicker(
                                    context: context,
                                    title: 'Wake-up time',
                                    initialTime: state.wakeTime,
                                  );
                                  if (picked != null) {
                                    controller.setWakeTime(picked);
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: TapField(
                                label: 'Bedtime',
                                value: _formatTime(state.bedtime),
                                icon: Icons.nightlight_outlined,
                                onTap: () async {
                                  final picked = await showAppTimePicker(
                                    context: context,
                                    title: 'Bedtime',
                                    initialTime: state.bedtime,
                                  );
                                  if (picked != null) {
                                    controller.setBedtime(picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Hours Awake Card (Figma: #EEE8DC, radius 16)
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.hoursAwake,
                                size: 24,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Hours awake',
                                style: AppTextStyles.body14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.grossHoursFormatted,
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 40,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2-segment progress bar: awake vs sleep
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 8,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: (awakeFraction * 1000).toInt(),
                                    child: Container(
                                      color: AppColors.setupAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    flex: (sleepFraction * 1000).toInt(),
                                    child: Container(
                                      color: AppColors.trackGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.awakeRangeFormatted,
                            style: AppTextStyles.caption12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transition caption
                    const Text(
                      'Next, we’ll make room for your routines.',
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

                    // Continue Button
                    AppPrimaryButton(
                      label: 'Continue',
                      isLoading: state.isLoading,
                      onPressed: () async {
                        final ok = await controller.saveSchedule();
                        if (ok && context.mounted) {
                          context.go('/onboarding/routine');
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
