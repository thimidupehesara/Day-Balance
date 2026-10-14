import 'package:flutter/material.dart';

/// Centralized design tokens from Figma Style Guide:
/// Android · Material Design 3 · 360 × 800 dp · Flat, warm, quietly purposeful.
class AppColors {
  AppColors._();

  // 01 / Palette (Base)
  static const Color canvas = Color(0xFFF8F5EF); // #F8F5EF Canvas background
  static const Color surface = Color(0xFFFFFCF7); // #FFFCF7 Surface
  static const Color text = Color(0xFF292E28); // #292E28 Primary text / headings
  static const Color secondary = Color(0xFF62675D); // #62675D Secondary text / subtitles
  static const Color primarySage = Color(0xFF49664D); // #49664D Primary sage brand / buttons
  static const Color outline = Color(0xFF85897D); // #85897D Border outline
  static const Color error = Color(0xFFA43B32); // #A43B32 Error text / error border

  // Containers & Details
  static const Color paper = Color(0xFFEEE8DC); // #EEE8DC Paper
  static const Color sageContainer = Color(0xFFE0E8DB); // #E0E8DB Sage container
  static const Color divider = Color(0xFFDDDCD2); // #DDDCD2 Divider
  static const Color errorContainer = Color(0xFFF6E2DE); // #F6E2DE Error container
  static const Color white = Color(0xFFFFFFFF); // #FFFFFF White

  // Semantic & Backwards Compatibility Aliases
  static const Color primary = primarySage;
  static const Color background = canvas;
  static const Color backgroundCream = canvas;
  static const Color cardWarm = paper;
  static const Color trackGrey = divider;
  static const Color errorRed = error;
  static const Color surfaceVariant = paper;
  static const Color textPrimary = text;
  static const Color textSecondary = secondary;
  static const Color textOnPrimary = white;

  // 01 / Palette (Categories - matching Figma style guide)
  static const Color academic = Color(0xFFD4DEE5); // #D4DEE5
  static const Color lifeFamily = Color(0xFFEBD3BC); // #EBD3BC
  static const Color entertainment = Color(0xFFDDD3E4); // #DDD3E4
  static const Color personalReading = Color(0xFFD9E2CF); // #D9E2CF
  static const Color career = Color(0xFFC9DEDA); // #C9DEDA
  static const Color unplanned = Color(0xFFDEDED8); // #DEDED8
  static const Color rest = Color(0xFFE9CFCE); // #E9CFCE

  static Color colorForCategory(String categoryId) {
    switch (categoryId) {
      case 'academic':
        return academic;
      case 'life_family':
        return lifeFamily;
      case 'entertainment':
        return entertainment;
      case 'personal_reading':
        return personalReading;
      case 'career':
        return career;
      case 'unplanned':
        return unplanned;
      case 'rest':
        return rest;
      default:
        return unplanned;
    }
  }

  // Status
  static const Color success = primarySage;
  static const Color warning = Color(0xFFEBD3BC);
  static const Color overtime = error;
  static const Color disabled = Color(0xFFDDDCD2);

  // 02 / Sky & Celestial Animation Tokens (Setting Up Screen)
  static const Color sunWarm = Color(0xFFE5A855); // Warm amber sunrise / daytime sun
  static const Color sunReady = primarySage; // Sage brand sun settling as ready frame
  static const Color moonGlow = Color(0xFFEDE8DF); // Soft moon illumination
  static const Color skyDawn = Color(0xFFF5EBE0); // Dawn sky tint
  static const Color skyDay = Color(0xFFEBF1E8); // Midday light sky tint
  static const Color skyDusk = Color(0xFF6E687A); // Dusk lavender-tinted sky
  static const Color skyNight = Color(0xFF262A33); // Deep night sky
  static const Color starGlow = Color(0xFFFFFDF5); // Twinkling night stars
  static const Color horizonLine = divider; // Soft horizon divider (#DDDCD2)
}
