import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized text style tokens matching Day-Balance Figma Style Guide (02 / TYPE):
/// Font: Roboto
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    letterSpacing: 2,
    color: AppColors.setupAccent,
    height: 1.5,
  );
  static const String fontFamily = 'Roboto';
  static const String monoFontFamily = 'RobotoMono';
  // Android's bundled serif face; no runtime font download for onboarding.
  static const TextStyle setupHeading = TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: ['Georgia', 'Times New Roman'],
    fontSize: 37,
    height: 1.14,
    letterSpacing: -1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.setupForeground,
  );
  static const String _fontFamily = fontFamily;
  static const String _monoFontFamily = monoFontFamily;

  // Display 40/44 (Roboto Medium)
  static const TextStyle display = TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: ['Georgia', 'Times New Roman'],
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  // Heading 32/38 (Roboto Medium) - Login Title "Good to see you."
  static const TextStyle heading = TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: ['Georgia', 'Times New Roman'],
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  // Title 22 (Roboto Medium)
  static const TextStyle title = TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: ['Georgia', 'Times New Roman'],
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  // Body 16/22 (Roboto Regular) - Subtitle "Log in and pick up where you left off."
  static const TextStyle body16 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.secondary,
  );

  // Body 14/20 (Roboto Regular) - Input text, body
  static const TextStyle body14 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  // Caption 12/17 (Roboto Regular) - Floating labels
  static const TextStyle caption12 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 17 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondary,
  );

  // Buttons: Roboto Semibold 14/20
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  // Outlined Button text: Roboto Semibold 14/20
  static const TextStyle buttonOutlined = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  // Action link ("Forgot password?")
  static const TextStyle link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primarySage,
  );

  // Error text (Roboto Regular 12/17 #A43B32)
  static const TextStyle error = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 17 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  // Focus 52/62 (Roboto Mono Medium) - Large Timer
  static const TextStyle timerLarge = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 52,
    height: 62 / 52,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  // Card 30/36 (Roboto Mono Medium) - Medium Timer
  static const TextStyle timerMedium = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  // Small metadata 10-11 (Roboto Mono Medium)
  static const TextStyle metadata = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
  );

  // Backward compatibility aliases (as const)
  static const TextStyle h1 = heading;
  static const TextStyle h2 = title;
  static const TextStyle h3 = title;
  static const TextStyle headlineSmall = title;
  static const TextStyle bodyLarge = body16;
  static const TextStyle bodyMedium = body14;
  static const TextStyle bodySmall = caption12;
  static const TextStyle label = caption12;
  static const TextStyle labelSmall = caption12;
}
