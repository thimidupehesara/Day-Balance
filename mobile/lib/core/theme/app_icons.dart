import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Single source of truth for all icons used in Day-Balance.
/// Uses Material Symbols (Rounded style, weight 400, outlined).
class AppIcons {
  AppIcons._();

  // Navigation & Actions
  static const IconData back = Symbols.arrow_back_rounded;
  static const IconData dropdown = Symbols.keyboard_arrow_down_rounded;
  static const IconData chevronLeft = Symbols.chevron_left_rounded;
  static const IconData chevronRight = Symbols.chevron_right_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData add = Symbols.add_rounded;
  static const IconData remove = Symbols.remove_rounded;
  static const IconData play = Symbols.play_arrow_rounded;
  static const IconData pause = Symbols.pause_rounded;
  static const IconData edit = Symbols.edit_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData warning = Symbols.warning_rounded;
  static const IconData refresh = Symbols.refresh_rounded;

  // Checkbox
  static const IconData checkboxChecked = Symbols.check_box_rounded;
  static const IconData checkboxUnchecked = Symbols.check_box_outline_blank_rounded;

  // Password Visibility
  static const IconData visibility = Symbols.visibility_rounded;
  static const IconData visibilityOff = Symbols.visibility_off_rounded;

  // Onboarding & Time
  static const IconData hoursAwake = Symbols.wb_sunny_rounded;
  static const IconData morningRoutine = Symbols.wb_twilight_rounded;
  static const IconData windUpRoutine = Symbols.bedtime_rounded;
  static const IconData time = Symbols.schedule_rounded;

  // Category Icons (matching 7 standard categories)
  static const IconData categoryAcademic = Symbols.school_rounded;
  static const IconData categoryLifeFamily = Symbols.home_rounded;
  static const IconData categoryEntertainment = Symbols.smart_display_rounded;
  static const IconData categoryPersonalReading = Symbols.menu_book_rounded;
  static const IconData categoryCareer = Symbols.work_rounded;
  static const IconData categoryUnplanned = Symbols.more_horiz_rounded;
  static const IconData categoryRest = Symbols.spa_rounded;

  /// Helper to get Category icon by category id
  static IconData iconForCategory(String categoryId) {
    switch (categoryId) {
      case 'academic':
        return categoryAcademic;
      case 'life_family':
        return categoryLifeFamily;
      case 'entertainment':
        return categoryEntertainment;
      case 'personal_reading':
        return categoryPersonalReading;
      case 'career':
        return categoryCareer;
      case 'unplanned':
        return categoryUnplanned;
      case 'rest':
        return categoryRest;
      default:
        return categoryUnplanned;
    }
  }
}
