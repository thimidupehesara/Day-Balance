import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/hours_left_card.dart';
import '../../../shared/widgets/pill_stepper.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../timer/presentation/today_controller.dart';
import 'edit_plan_controller.dart';

/// Edit Today's Plan screen matching Figma 12_edit_plan.
/// Opened as a slide-up modal from Today's "Edit plan" button.
class EditPlanScreen extends ConsumerStatefulWidget {
  const EditPlanScreen({super.key});

  @override
  ConsumerState<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends ConsumerState<EditPlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(editPlanControllerProvider.notifier).initFromToday();
    });
  }

  Future<bool> _handleClose(BuildContext context, bool hasUnsavedChanges) async {
    if (!hasUnsavedChanges) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/today');
      }
      return true;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Discard changes?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        content: const Text(
          'You have unsaved changes to your plan. Do you want to discard them?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Keep editing',
              style: TextStyle(
                color: AppColors.primarySage,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (discard == true && context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/today');
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editPlanControllerProvider);
    final controller = ref.read(editPlanControllerProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleClose(context, state.hasUnsavedChanges);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: SafeArea(
          child: state.isLoading && state.items.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primarySage,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar: "Edit today’s plan" + Close X button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit today’s plan',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Close',
                            child: InkWell(
                              onTap: () =>
                                  _handleClose(context, state.hasUnsavedChanges),
                              borderRadius: BorderRadius.circular(24),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 24,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Top Hours Left Card
                            HoursLeftCard(
                              title:
                                  'Hours left to plan · ${TodayTimerState.formatShort(state.wakingSeconds)} available',
                              hoursText: state.isOverAllocated
                                  ? '−${TodayTimerState.formatDuration(state.overAllocatedSeconds)}'
                                  : TodayTimerState.formatDuration(
                                      state.secondsLeftToPlan),
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

                            // Category Rows with PillStepper
                            ...state.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Category color indicator bar
                                        Container(
                                          width: 4,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: item.categoryColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Category Name
                                        Expanded(
                                          child: Text(
                                            item.categoryName,
                                            style: const TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ),

                                        // Pill Stepper in 30-minute steps
                                        PillStepper(
                                          label: TodayTimerState.formatDuration(
                                              item.currentPlannedSeconds),
                                          onDecrement: () => controller
                                              .decrementCategory(item.categoryId),
                                          onIncrement: () => controller
                                              .incrementCategory(item.categoryId),
                                          canDecrement: item.canDecrement,
                                          canIncrement: true,
                                          usePlusMinus: true,
                                        ),
                                      ],
                                    ),

                                    // Minimum planned helper line when category has used time
                                    if (item.minPlannedSeconds > 0) ...[
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12),
                                        child: Text(
                                          item.friendlyMinText,
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTextStyles.fontFamily,
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),

                            // Informational note matching Figma 12
                            Text(
                              state.runningCategoryName != null
                                  ? 'Used time stays put. Only your plan changes. ${state.runningCategoryName} is still running.'
                                  : 'Used time stays put. Only your plan changes.',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),

                            // Over-allocated warning banner
                            if (state.isOverAllocated) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      AppIcons.warning,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You’re ${TodayTimerState.formatShort(state.overAllocatedSeconds)} over. Free up time to continue.',
                                        style: const TextStyle(
                                          fontFamily:
                                              AppTextStyles.fontFamily,
                                          color: AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Error message if any
                            if (state.errorMessage != null &&
                                !state.isOverAllocated) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Bottom Buttons: Cancel & Save plan
                            Row(
                              children: [
                                Expanded(
                                  child: AppSecondaryButton(
                                    label: 'Cancel',
                                    onPressed: () => _handleClose(
                                      context,
                                      state.hasUnsavedChanges,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppPrimaryButton(
                                    label: 'Save plan',
                                    isLoading: state.isSaving,
                                    onPressed: state.canSave
                                        ? () async {
                                            final ok =
                                                await controller.savePlan();
                                            if (ok && context.mounted) {
                                              if (context.canPop()) {
                                                context.pop();
                                              } else {
                                                context.go('/today');
                                              }
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
