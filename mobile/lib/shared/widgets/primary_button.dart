import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Primary action button matching Day-Balance design system:
/// Height: 48dp, Pill radius 100, Background: #49664D, Text: White Roboto Semibold 14/20
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;

  const AppPrimaryButton({
    super.key,
    String? text,
    String? label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
  }) : text = label ?? text ?? '';

  @override
  Widget build(BuildContext context) {
    final bool canPress = isEnabled && !isLoading && onPressed != null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canPress ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primarySage,
            foregroundColor: foregroundColor ?? AppColors.white,
            disabledBackgroundColor:
                disabledBackgroundColor ?? AppColors.disabled,
            disabledForegroundColor:
                disabledForegroundColor ?? AppColors.secondary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(
                    color: canPress ? foregroundColor : disabledForegroundColor,
                  ),
                ),
        ),
      ),
    );
  }
}
