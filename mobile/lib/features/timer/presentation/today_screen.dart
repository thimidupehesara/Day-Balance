import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/category_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../planning/domain/plan_model.dart';
import 'switch_sheet.dart';
import 'today_controller.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(todayControllerProvider.notifier).fetchStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayControllerProvider.notifier).fetchStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: state.isLoading && state.items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primarySage,
                ),
              )
            : state.isOffline && state.items.isEmpty
                ? _buildOfflineScreen(controller)
                : RefreshIndicator(
                    color: AppColors.primarySage,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      await controller.fetchStatus();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Date Header: "WEDNESDAY, 14 OCTOBER"
                          Text(
                            DateFormat('EEEE, d MMMM')
                                .format(DateTime.now())
                                .toUpperCase(),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Greeting: "Good morning, Maya." / "Hello, Maya." / "Hello!"
                          Text(
                            state.greeting,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Top Summary Section: "Total hours left" + Edit plan button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total hours left',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: AppColors.secondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    TodayTimerState.formatDuration(
                                        state.totalHoursLeftSeconds),
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: AppColors.primarySage,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),

                              // Edit Plan Button (only when plan exists)
                              if (state.hasPlanForToday)
                                Semantics(
                                  button: true,
                                  label: 'Edit plan',
                                  child: InkWell(
                                    onTap: () => context.go('/plan'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        AppIcons.edit,
                                        size: 20,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Body: Before-Planning state OR Active Plan Category Cards
                          if (!state.hasPlanForToday)
                            _buildBeforePlanningState(context, state)
                          else
                            _buildPlannedCategoriesList(context, state, controller),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  /// Before-Planning empty state matching Figma 09_today_home_before_planning
  Widget _buildBeforePlanningState(BuildContext context, TodayTimerState state) {
    final wakeTime = state.user?.wakeTime ?? '7:00';
    final bedtime = state.user?.bedtime ?? '23:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decorative Illustration Card with colored category bars
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEEE8DC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 220,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.academic,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 176,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.lifeFamily,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 136,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.rest,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ],
          ),
        ),

        // Headline
        const Text(
          'A fresh day. A little room to choose.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Subtitle
        const Text(
          'You haven’t made a plan yet. Give your hours a place, then start one thing at a time.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.secondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Routine footnote
        Text(
          '$wakeTime – $bedtime · routines already set aside',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 36),

        // "Plan today" CTA Button
        AppPrimaryButton(
          text: 'Plan today',
          onPressed: () => context.go('/plan'),
        ),
      ],
    );
  }

  /// Planned categories list matching Figma 09_today_home & 09_today_home_overtime
  Widget _buildPlannedCategoriesList(
    BuildContext context,
    TodayTimerState state,
    TodayController controller,
  ) {
    return Column(
      children: state.items.map((item) {
        final isRunning = state.isItemRunning(item);
        final isOvertime = state.isItemOvertime(item);
        final remainingSec = state.getRemainingSecondsForItem(item);
        final overtimeSec = state.getOvertimeSecondsForItem(item);

        final plannedStr = TodayTimerState.formatShort(item.plannedSeconds);
        final remainingStr = isRunning
            ? TodayTimerState.formatCountdown(remainingSec)
            : TodayTimerState.formatDuration(remainingSec);
        final overtimeStr = TodayTimerState.formatOvertime(overtimeSec);
        final usedStr = TodayTimerState.formatUsed(item.plannedSeconds, overtimeSec);

        final progress = isOvertime
            ? 1.0
            : (item.plannedSeconds > 0
                ? ((item.plannedSeconds - remainingSec) / item.plannedSeconds)
                    .clamp(0.0, 1.0)
                : 0.0);

        final color = AppColors.colorForCategory(item.categoryId);

        return CategoryTimerCard(
          categoryName: item.categoryName,
          categoryColor: color,
          plannedText: plannedStr,
          remainingText: remainingStr,
          progress: progress,
          isRunning: isRunning,
          isOvertime: isOvertime,
          overtimeText: overtimeStr,
          usedText: usedStr,
          onTap: () {
            context.go('/timer?planItemId=${item.id}');
          },
          onAction: () {
            if (isRunning) {
              controller.pauseTimer();
            } else {
              // If another category is currently running, show SwitchSheet
              if (state.activeItemId != null && state.activeItemId != item.id) {
                final activeItem = state.items.cast<PlanItemModel?>().firstWhere(
                      (i) => i?.id == state.activeItemId,
                      orElse: () => null,
                    );
                if (activeItem != null) {
                  final activeRemainingSec =
                      state.getRemainingSecondsForItem(activeItem);
                  final activeRemainingStr = TodayTimerState.formatShort(
                    math.max(0, activeRemainingSec),
                  );
                  final targetRemainingStr = TodayTimerState.formatShort(
                    math.max(0, remainingSec),
                  );

                  SwitchSheet.show(
                    context,
                    activeCategoryName: activeItem.categoryName,
                    activeRemainingText: activeRemainingStr,
                    targetCategoryName: item.categoryName,
                    targetRemainingText: targetRemainingStr,
                    targetCategoryColor: color,
                    targetCategoryIcon:
                        AppIcons.iconForCategory(item.categoryId),
                    onConfirm: () {
                      controller.startTimer(item.id);
                    },
                  );
                  return;
                }
              }
              controller.startTimer(item.id);
            }
          },
        );
      }).toList(),
    );
  }

  /// Screen 16 offline / no-connection error view
  Widget _buildOfflineScreen(TodayController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              AppIcons.warning,
              size: 32,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'A little offline.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We can’t connect right now. Your last saved plan is safe on this device.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.secondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Spacer(),
          AppPrimaryButton(
            text: 'Try again',
            onPressed: () => controller.fetchStatus(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Persistent bottom navigation bar matching Figma design
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEEE8DC),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Today (Active)
          Semantics(
            button: true,
            selected: true,
            label: 'Today tab',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySage.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    AppIcons.time,
                    color: AppColors.primarySage,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Today',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.primarySage,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // History (Inactive placeholder)
          Semantics(
            button: true,
            label: 'History tab',
            child: InkWell(
              onTap: () {
                // Placeholder
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: Icon(
                      Icons.history_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'History',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile / Settings (Inactive placeholder)
          Semantics(
            button: true,
            label: 'Profile tab',
            child: InkWell(
              onTap: () {
                // Placeholder
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
