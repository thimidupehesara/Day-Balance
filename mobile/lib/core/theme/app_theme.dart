import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 theme configuration matching Day-Balance Figma Style Guide:
/// 8dp rhythm · 4/8/16/24/32/40dp · Page inset 24dp · Input radius 4 · Pill radius 100
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primarySage,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Roboto',
      textTheme: Typography.material2021().white.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.text, size: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppColors.primarySage,
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
        labelStyle: AppTextStyles.caption12,
        errorStyle: AppTextStyles.error,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
