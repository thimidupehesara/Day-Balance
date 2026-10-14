/// Text constants for the "Setting up your day" loading screen.
/// Kept in a single editable file matching the design tone: warm, calm, quietly purposeful.
class SettingUpTexts {
  SettingUpTexts._();

  // Initial reading line
  static const String readingRhythm = 'Reading your rhythm...';

  // Personal line derived from user's waking hours
  static String personalWakingHours(int hours) =>
      "You're awake about $hours hours a day.";

  // Social proof line shown only when honest count >= 25
  static String socialProof(int count) =>
      '$count people have a routine like yours.';

  // Fallback social proof line when count < 25 or request fails/times out
  static const String socialProofFallback = 'Every plan leaves room for life.';

  // Friendly pacing lines that cross-fade during the animation
  static const List<String> friendlyLines = [
    'Folding your hours into tidy piles...',
    'Teaching the clock to relax...',
    'Making room for the good stuff...',
  ];

  // Final confirmation lines
  static const String settingUp = 'Setting up your day...';
  static const String allSet = 'All set.';

  // Screen 16 error state strings
  static const String errorTitle = "Couldn't save your day";
  static const String errorMessage =
      'Check your connection and try again. Your chosen schedule and categories are safe.';
  static const String tryAgainButton = 'Try again';
  static const String backButton = 'Back';
  static const String continueButton = 'Continue';

  /// Generates the complete, ordered text sequence for the loading screen.
  static List<String> buildTextSequence({
    required int grossWakingMinutes,
    required bool showable,
    required int? similarCount,
  }) {
    final wakingHours = (grossWakingMinutes / 60).round();
    final personalLine = personalWakingHours(wakingHours > 0 ? wakingHours : 16);

    final String socialLine;
    if (showable && similarCount != null && similarCount >= 25) {
      socialLine = socialProof(similarCount);
    } else {
      socialLine = socialProofFallback;
    }

    return [
      readingRhythm,
      personalLine,
      socialLine,
      ...friendlyLines,
      settingUp,
      allSet,
    ];
  }
}
