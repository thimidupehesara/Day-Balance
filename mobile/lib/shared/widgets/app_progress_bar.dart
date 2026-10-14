import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Clean rounded 4dp horizontal progress bar matching Figma style guide.
class AppProgressBar extends StatelessWidget {
  /// Progress ratio from 0.0 to 1.0. Clamped automatically.
  final double progress;

  /// Progress bar height. Defaults to 4.0.
  final double height;

  /// Background track color. Defaults to [AppColors.divider].
  final Color trackColor;

  /// Filled progress color. Defaults to [AppColors.primarySage].
  final Color fillColor;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 4.0,
    this.trackColor = AppColors.divider,
    this.fillColor = AppColors.primarySage,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: clampedRatio,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}
