import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../planning/domain/plan_model.dart';
import 'switch_sheet.dart';
import 'today_controller.dart';

/// Fullscreen Focus Time screen for the currently active or selected category timer.
/// Strictly follows Figma 10_active_timer.png and _10_active_timer.dart.
class ActiveTimerScreen extends ConsumerStatefulWidget {
  final String? initialPlanItemId;

  const ActiveTimerScreen({
    super.key,
    this.initialPlanItemId,
  });

  @override
  ConsumerState<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends ConsumerState<ActiveTimerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(todayControllerProvider.notifier).fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);

    // Resolve active item: either the currently running item, the initial item requested, or first item
    PlanItemModel? currentItem;
    if (state.activeItemId != null) {
      currentItem = state.items.cast<PlanItemModel?>().firstWhere(
            (item) => item?.id == state.activeItemId,
            orElse: () => null,
          );
    }
    if (currentItem == null && widget.initialPlanItemId != null) {
      currentItem = state.items.cast<PlanItemModel?>().firstWhere(
            (item) => item?.id == widget.initialPlanItemId,
            orElse: () => null,
          );
    }
    if (currentItem == null && state.items.isNotEmpty) {
      currentItem = state.items.first;
    }

    if (currentItem == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: AppColors.text),
            onPressed: () => context.go('/home'),
          ),
          title: const Text(
            'Focus time',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.text,
              fontSize: 22,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'No active plan found for today.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.secondary,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final isRunning = state.isItemRunning(currentItem);
    final isOvertime = state.isItemOvertime(currentItem);
    final remainingSec = state.getRemainingSecondsForItem(currentItem);
    final overtimeSec = state.getOvertimeSecondsForItem(currentItem);

    final double progress;
    if (isOvertime) {
      progress = 1.0;
    } else if (currentItem.plannedSeconds > 0) {
      progress = ((currentItem.plannedSeconds - remainingSec) /
              currentItem.plannedSeconds)
          .clamp(0.0, 1.0);
    } else {
      progress = 0.0;
    }

    final timeString = isOvertime
        ? TodayTimerState.formatOvertime(overtimeSec)
        : TodayTimerState.formatCountdown(remainingSec);

    final plannedFormatted =
        TodayTimerState.formatDuration(currentItem.plannedSeconds);

    // Status / detail subtitle
    final String detailSubtitle;
    final int usedSeconds = isOvertime
        ? (currentItem.plannedSeconds + overtimeSec)
        : math.max(0, currentItem.plannedSeconds - remainingSec);
    final usedString = TodayTimerState.formatShort(usedSeconds);

    if (isRunning) {
      final startTimeStr = currentItem.startedAt != null
          ? DateFormat('h:mm a').format(currentItem.startedAt!)
          : DateFormat('h:mm a').format(state.now);
      detailSubtitle = 'Running since $startTimeStr · $usedString used';
    } else if (isOvertime) {
      detailSubtitle = 'Overtime · $usedString used';
    } else {
      detailSubtitle = 'Paused · $usedString used';
    }

    final otherItems =
        state.items.where((i) => i.id != currentItem!.id).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Top Bar: Back | "Focus time" | Spacer | "End session"
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Back to Today',
                      child: InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: const Icon(
                            AppIcons.back,
                            color: AppColors.text,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Focus time',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'End session',
                      child: TextButton(
                        onPressed: () async {
                          if (isRunning) {
                            await controller.pauseTimer();
                          }
                          if (context.mounted) {
                            context.go('/home');
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text(
                          'End session',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.primarySage,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Row: Icon + Category Name ("Academic")
                Row(
                  children: [
                    Icon(
                      AppIcons.iconForCategory(currentItem.categoryId),
                      size: 24,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      currentItem.categoryName,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle: "Just this, for now."
                const Text(
                  'Just this, for now.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.secondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Center Circular Ring Timer Dial (280 x 280)
                Center(
                  child: Semantics(
                    label:
                        'Timer for ${currentItem.categoryName}: $timeString',
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: _TimerDialPainter(
                                progress: progress,
                                trackColor: AppColors.timerTrack,
                                progressColor: isOvertime
                                    ? AppColors.error
                                    : AppColors.primarySage,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeString,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isOvertime
                                      ? AppColors.error
                                      : AppColors.text,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.0,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOvertime
                                    ? 'overtime'
                                    : 'remaining of $plannedFormatted',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isOvertime
                                      ? AppColors.error
                                      : AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle: "Running since 8:26 AM · 1h 15m used"
                Center(
                  child: Text(
                    detailSubtitle,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Controls Row: Pause/Resume (Filled) | Switch (Outlined)
                Row(
                  children: [
                    // Pause / Resume Button
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: isRunning ? 'Pause timer' : 'Resume timer',
                        child: InkWell(
                          onTap: () {
                            if (isRunning) {
                              controller.pauseTimer();
                            } else {
                              controller.startTimer(currentItem!.id);
                            }
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primarySage,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isRunning ? 'Pause' : 'Resume',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Switch Button
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Switch category',
                        child: InkWell(
                          onTap: () {
                            if (otherItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No other planned categories for today.',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                    ),
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            _showSwitchModal(
                              context,
                              activeItem: currentItem!,
                              targetItem: otherItems.first,
                              controller: controller,
                              state: state,
                            );
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.outline,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Switch',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.primarySage,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // "MOVE TO SOMETHING ELSE" Section
                if (otherItems.isNotEmpty) ...[
                  const Text(
                    'MOVE TO SOMETHING ELSE',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Cards Row
                  Row(
                    children: otherItems.map((item) {
                      final itemColor =
                          AppColors.colorForCategory(item.categoryId);
                      final icon = AppIcons.iconForCategory(item.categoryId);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Semantics(
                            button: true,
                            label: 'Switch to ${item.categoryName}',
                            child: InkWell(
                              onTap: () {
                                _showSwitchModal(
                                  context,
                                  activeItem: currentItem!,
                                  targetItem: item,
                                  controller: controller,
                                  state: state,
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: itemColor,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 22,
                                      color: AppColors.text,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.categoryName,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: AppColors.text,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Explanatory footnote: "Switching pauses [Active]. Your time stays here."
                  Text(
                    'Switching pauses ${currentItem.categoryName}. Your time stays here.',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSwitchModal(
    BuildContext context, {
    required PlanItemModel activeItem,
    required PlanItemModel targetItem,
    required TodayController controller,
    required TodayTimerState state,
  }) {
    final activeRemainingSec = state.getRemainingSecondsForItem(activeItem);
    final activeRemainingStr =
        TodayTimerState.formatShort(math.max(0, activeRemainingSec));

    final targetRemainingSec = state.getRemainingSecondsForItem(targetItem);
    final targetRemainingStr =
        TodayTimerState.formatShort(math.max(0, targetRemainingSec));

    SwitchSheet.show(
      context,
      activeCategoryName: activeItem.categoryName,
      activeRemainingText: activeRemainingStr,
      targetCategoryName: targetItem.categoryName,
      targetRemainingText: targetRemainingStr,
      targetCategoryColor: AppColors.colorForCategory(targetItem.categoryId),
      targetCategoryIcon: AppIcons.iconForCategory(targetItem.categoryId),
      onConfirm: () {
        controller.startTimer(targetItem.id);
      },
    );
  }
}

/// Custom painter for the 280dp circular ring countdown timer
class _TimerDialPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _TimerDialPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
