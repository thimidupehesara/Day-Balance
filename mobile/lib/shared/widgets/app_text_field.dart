import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Text field matching Day-Balance Figma Style Guide:
/// Input radius 4, outline border, floating label cut into border, 56dp standard height
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final bool isEnabled;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.isEnabled = true,
    this.focusNode,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: isEnabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTextStyles.body16.copyWith(
            color: isEnabled ? AppColors.text : AppColors.secondary,
          ),
          cursorColor: AppColors.primarySage,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTextStyles.caption12.copyWith(
              color: hasError
                  ? AppColors.error
                  : (isEnabled ? AppColors.secondary : AppColors.outline),
            ),
            floatingLabelStyle: AppTextStyles.caption12.copyWith(
              color: hasError ? AppColors.error : AppColors.primarySage,
              fontWeight: FontWeight.w500,
            ),
            hintText: hintText,
            hintStyle: AppTextStyles.body16.copyWith(color: AppColors.outline),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primarySage,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: AppTextStyles.error),
        ],
      ],
    );
  }
}
