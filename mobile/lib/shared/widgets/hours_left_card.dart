import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_progress_bar.dart';

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
    final color = isOverAllocated ? AppColors.error : AppColors.setupAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption12.copyWith(
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                hoursText,
                style: AppTextStyles.heading.copyWith(
                  fontSize: 36,
                  color: isOverAllocated ? AppColors.error : AppColors.text,
                ),
              ),
              if (subText != null)
                Text(subText!, style: AppTextStyles.caption12),
              ?trailing,
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            AppProgressBar(progress: progress!, fillColor: color),
          ],
        ],
      ),
    );
  }
}
