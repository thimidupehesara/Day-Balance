import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_progress_bar.dart';

/// Category card widget for Today home screen matching Figma 09 designs:
/// supports idle/paused, actively running, and overtime states.
class CategoryTimerCard extends StatelessWidget {
  final String categoryName;
  final Color categoryColor;
  final String plannedText;
  final String remainingText;
  final double progress;
  final bool isRunning;
  final bool isOvertime;
  final String? overtimeText;
  final String? usedText;
  final VoidCallback onAction;

  const CategoryTimerCard({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.plannedText,
    required this.remainingText,
    required this.progress,
    this.isRunning = false,
    this.isOvertime = false,
    this.overtimeText,
    this.usedText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return _buildRunningOrOvertimeCard(context);
    }
    return _buildIdleCard(context);
  }

  /// Running / Overtime expanded active card
  Widget _buildRunningOrOvertimeCard(BuildContext context) {
    final borderColor = isOvertime ? AppColors.error : AppColors.primarySage;
    final backgroundColor =
        isOvertime ? AppColors.errorContainer : categoryColor;
    final statusColor = isOvertime ? AppColors.error : AppColors.primarySage;
    final statusText = isOvertime ? 'OVERTIME' : '● RUNNING';
    final timerTextColor = isOvertime ? AppColors.error : AppColors.text;
    final timerDisplay = isOvertime ? (overtimeText ?? remainingText) : remainingText;
    final subText = isOvertime && usedText != null
        ? 'Planned $plannedText · $usedText used'
        : 'Planned $plannedText · remaining';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category name + Running/Overtime status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Timer & Pause CTA Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timerDisplay,
                    style: TextStyle(
                      color: timerTextColor,
                      fontSize: isOvertime ? 24 : 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: isOvertime ? 0.5 : -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              // Pause button (>=48dp touch target)
              Semantics(
                button: true,
                label: 'Pause timer for $categoryName',
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySage,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'Pause',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          AppProgressBar(
            progress: progress,
            fillColor: isOvertime ? AppColors.error : AppColors.primarySage,
          ),
        ],
      ),
    );
  }

  /// Idle / Paused category card
  Widget _buildIdleCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Category color accent bar
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Name & Planned time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Planned $plannedText',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Remaining time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                remainingText,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'remaining',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Start CTA button (with >=48dp touch target)
          Semantics(
            button: true,
            label: 'Start timer for $categoryName',
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    color: AppColors.primarySage,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
