import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_progress_bar.dart';

/// Top summary section ("Hours left to plan" / "Total hours left")
/// matching Figma screens 08 (Daily Planning) and 09 (Today Home).
class HoursLeftCard extends StatelessWidget {
  final String title;
  final String hoursText;
  final String? subText;
  final double? progress;
  final bool isOverAllocated;
  final Widget? trailing;

  const HoursLeftCard({
    super.key,
    required this.title,
    required this.hoursText,
    this.subText,
    this.progress,
    this.isOverAllocated = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isOverAllocated ? AppColors.error : AppColors.secondary;
    final valueColor =
        isOverAllocated ? AppColors.error : AppColors.primarySage;
    final progressFill =
        isOverAllocated ? AppColors.error : AppColors.primarySage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title label
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),

        // Main value row with optional subText and trailing widget
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hoursText,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    subText!,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
            ?trailing,
          ],
        ),

        // Progress bar (if provided)
        if (progress != null) ...[
          const SizedBox(height: 10),
          AppProgressBar(
            progress: progress!,
            fillColor: progressFill,
          ),
        ],
      ],
    );
  }
}
