import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/hours_left_card.dart';
import '../../../shared/widgets/pill_stepper.dart';
import '../../../shared/widgets/primary_button.dart';
import 'plan_controller.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(planControllerProvider.notifier).initPlanForToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planControllerProvider);
    final controller = ref.read(planControllerProvider.notifier);

    final displayCategories = kCategories.where((cat) {
      if (state.selectedCategoryIds.isEmpty) return true;
      return state.selectedCategoryIds.contains(cat.id);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: state.isLoading && state.plannedSeconds.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primarySage,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Row(
                      children: [
                        AppBackButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Plan your day',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Top Summary Section ("Hours left to plan")
                          HoursLeftCard(
                            title: 'Hours left to plan',
                            hoursText: state.isOverAllocated
                                ? '−${PlanState.formatDuration(state.overAllocatedSeconds)}'
                                : PlanState.formatDuration(state.secondsLeftToPlan),
                            subText:
                                'of ${PlanState.formatDuration(state.wakingSeconds)}',
                            progress: state.isOverAllocated
                                ? 1.0
                                : (state.wakingSeconds > 0
                                    ? (state.totalPlannedSeconds /
                                            state.wakingSeconds)
                                        .clamp(0.0, 1.0)
                                    : 0.0),
                            isOverAllocated: state.isOverAllocated,
                          ),

                          const SizedBox(height: 20),

                          // Categories List with Steppers
                          ...displayCategories.map((cat) {
                            final plannedSec =
                                state.plannedSeconds[cat.id] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  // Category color bar
                                  Container(
                                    width: 4,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Category Name
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),

                                  // Stepper
                                  PillStepper(
                                    label: PlanState.formatDuration(plannedSec),
                                    onDecrement: () => controller
                                        .decrementCategory(cat.id),
                                    onIncrement: () => controller
                                        .incrementCategory(cat.id),
                                    canDecrement: plannedSec >=
                                        PlanController.stepSeconds,
                                    canIncrement: true,
                                    usePlusMinus: true,
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),

                          // Dynamic State Nudge / Warning Banners
                          if (state.isOverAllocated) ...[
                            _buildAlertBanner(
                              backgroundColor: AppColors.errorContainer,
                              iconColor: AppColors.error,
                              textColor: AppColors.error,
                              icon: AppIcons.warning,
                              text:
                                  "You’re ${PlanState.formatShort(state.overAllocatedSeconds)} over. Free up ${PlanState.formatShort(state.overAllocatedSeconds) == '1h' ? 'an hour' : PlanState.formatShort(state.overAllocatedSeconds)} before starting your day.",
                            ),
                          ] else if (state.isZeroHoursLeft) ...[
                            _buildAlertBanner(
                              backgroundColor: const Color(0xFFE0E8DB),
                              iconColor: AppColors.primarySage,
                              textColor: AppColors.primarySage,
                              icon: AppIcons.info,
                              text:
                                  'Every hour has a place. You can adjust your plan as the day unfolds.',
                            ),
                          ] else if (state.hasEntertainmentWarning) ...[
                            _buildAlertBanner(
                              backgroundColor: const Color(0xFFE0E8DB),
                              iconColor: AppColors.primarySage,
                              textColor: AppColors.primarySage,
                              icon: AppIcons.info,
                              text:
                                  '${PlanState.formatShort(state.entertainmentSeconds)} for Entertainment. Does that leave enough room for the rest of your day?',
                            ),
                          ],

                          // Error message from server if any
                          if (state.errorMessage != null &&
                              !state.isOverAllocated) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Bottom Actions Section
                          if (!state.isOverAllocated &&
                              state.secondsLeftToPlan > 0) ...[
                            Text(
                              '${PlanState.formatShort(state.secondsLeftToPlan)} will stay as extra breathing room.',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          if (state.isOverAllocated) ...[
                            Semantics(
                              button: true,
                              enabled: false,
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.outline,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Free up ${PlanState.formatShort(state.overAllocatedSeconds)} to continue',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            AppPrimaryButton(
                              text: 'Start my day',
                              isLoading: state.isLoading,
                              isEnabled: state.canStartDay,
                              onPressed: () async {
                                final success = await controller.savePlan();
                                if (success && context.mounted) {
                                  context.go('/home');
                                }
                              },
                            ),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAlertBanner({
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
