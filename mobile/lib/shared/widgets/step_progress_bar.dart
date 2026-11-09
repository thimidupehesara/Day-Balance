import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 3-segment progress bar with "YOUR DAY · X OF 3" label matching Figma onboarding screens.
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final int totalSteps; // default 3

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  }) : assert(currentStep >= 1 && currentStep <= totalSteps);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR DAY · $currentStep OF $totalSteps',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.setupAccent,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final isFilled = index < currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: isFilled ? AppColors.setupAccent : AppColors.divider,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
