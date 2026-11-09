import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Outlined secondary button matching Day-Balance design system:
/// Height: 48dp, Pill radius 100, Border: #85897D, Text: #49664D or #292E28
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color? foregroundColor;

  const AppSecondaryButton({
    super.key,
    String? text,
    String? label,
    required this.onPressed,
    this.isEnabled = true,
    this.foregroundColor,
  }) : text = label ?? text ?? '';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? AppColors.primarySage,
          disabledForegroundColor: AppColors.disabled,
          side: const BorderSide(color: AppColors.outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Text(
          text,
          style: AppTextStyles.buttonOutlined.copyWith(
            color: foregroundColor ?? AppColors.primarySage,
          ),
        ),
      ),
    );
  }
}
