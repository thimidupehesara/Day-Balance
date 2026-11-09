import 'package:flutter/material.dart';

/// Approved Day-Balance evening palette:
/// Android · Material Design 3 · 360 × 800 dp · Flat, warm, quietly purposeful.
class AppColors {
  AppColors._();

  // 01 / Palette (Base)
  static const Color canvas = Color(0xFF11252D); // Canvas background
  static const Color surface = Color(0xFF1B343D); // Surface
  static const Color text = Color(
    0xFFFFF5E7,
  ); // Primary text / headings
  static const Color secondary = Color(
    0xFFBECDCA,
  ); // Secondary text / subtitles
  static const Color primarySage = Color(
    0xFFE3EADB,
  ); // Primary sage brand / buttons
  static const Color outline = Color(0xFF658079); // Border outline
  static const Color error = Color(
    0xFFF5B6A1,
  ); // Error text / error border

  // Containers & Details
  static const Color paper = Color(0xFF253F42); // Paper
  static const Color sageContainer = Color(
    0xFF2D4942,
  ); // Sage container
  static const Color divider = Color(0xFF385059); // Divider
  static const Color timerTrack = Color(
    0xFF30484F,
  ); // Circular timer track
  static const Color errorContainer = Color(
    0xFF4A3232,
  ); // Error container
  static const Color white = Color(0xFFFFFFFF); // White

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
  static const Color textOnPrimary = setupButtonText;

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
  static const Color disabled = Color(0xFF385059);

  // 02 / Sky & Celestial Animation Tokens (Setting Up Screen)
  static const Color setupBackground = Color(0xFF11252D);
  static const Color setupForeground = Color(0xFFFFF6E8);
  static const Color setupSecondary = Color(0xFFDDDEDA);
  static const Color setupMuted = Color(0xFFABB9BC);
  static const Color setupAccent = Color(0xFFE3C7A6);
  static const Color setupButton = Color(0xFFE3EADB);
  static const Color setupButtonText = Color(0xFF233C34);
  static const Color setupRidgeDay = Color(0xFF66777B);
  static const Color setupRidgeNight = Color(0xFF38465C);
  static const Color setupSeaDay = Color(0xFF9B9E96);
  static const Color setupSeaNight = Color(0xFF57647B);
  static const Color setupSeaDeep = Color(0xFF172F38);
  static const Color setupShore = Color(0xFF213F43);
  static const Color setupMist = Color(0xFF162D34);
  static const Color setupSunCore = Color(0xFFFFF9DA);
  static const Color setupSunMid = Color(0xFFFFE0A7);
  static const Color setupSunEdge = Color(0xFFFBBD76);
  static const Color setupMoonLight = Color(0xFFF6F0DC);
  static const Color setupMoonMid = Color(0xFFD9DCD5);
  static const Color setupMoonShade = Color(0xFF6F8194);
  static const Color setupCrater = Color(0xFF4B5B6D);
  static const Color setupMoonHalo = Color(0xFFD0DEF3);
  static const List<List<Color>> setupSkies = [
    [
      Color(0xFF243B52),
      Color(0xFF8F7180),
      Color(0xFFEAB38E),
      Color(0xFFF6C99B),
    ],
    [
      Color(0xFF2A5362),
      Color(0xFF70908B),
      Color(0xFFD5B999),
      Color(0xFFEDC399),
    ],
    [
      Color(0xFF303957),
      Color(0xFF895D70),
      Color(0xFFDC8D77),
      Color(0xFFF5B17D),
    ],
    [
      Color(0xFF111C35),
      Color(0xFF293451),
      Color(0xFF6B637B),
      Color(0xFFB19091),
    ],
    [
      Color(0xFF101D32),
      Color(0xFF21334A),
      Color(0xFF49546C),
      Color(0xFF777B8B),
    ],
  ];
  static const Color sunWarm = Color(
    0xFFE5A855,
  ); // Warm amber sunrise / daytime sun
  static const Color sunReady =
      primarySage; // Sage brand sun settling as ready frame
  static const Color moonGlow = Color(0xFFEDE8DF); // Soft moon illumination
  static const Color skyDawn = Color(0xFFF5EBE0); // Dawn sky tint
  static const Color skyDay = Color(0xFFEBF1E8); // Midday light sky tint
  static const Color skyDusk = Color(0xFF6E687A); // Dusk lavender-tinted sky
  static const Color skyNight = Color(0xFF262A33); // Deep night sky
  static const Color starGlow = Color(0xFFFFFDF5); // Twinkling night stars
  static const Color horizonLine = divider; // Soft horizon divider (#DDDCD2)
}
