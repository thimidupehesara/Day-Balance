/// Text constants for the "Setting up your day" loading screen.
/// Kept in a single editable file matching the design tone: warm, calm, quietly purposeful.
class SettingUpTexts {
  SettingUpTexts._();
  static const chapters = [
    (
      eyebrow: 'KNOW YOUR TIME',
      title: 'A day that fits\nyour life.',
      body: 'See the hours left after sleep and routines, so you can plan a day that feels doable.',
      status: 'Finding your daily rhythm',
    ),
    (
      eyebrow: 'CHOOSE WHAT MATTERS',
      title: 'Make room\nfor your priorities.',
      body: 'Give study, work and family their time, with space for rest and the unexpected.',
      status: 'Making room for your priorities',
    ),
    (
      eyebrow: 'ONE THING AT A TIME',
      title: 'Be here.\nOne moment fully.',
      body: 'Start a timer for what you’re doing. Switch activities, and the previous timer pauses.',
      status: 'Preparing your focus timers',
    ),
    (
      eyebrow: 'LEARN YOUR RHYTHM',
      title: 'See your day.\nShape tomorrow.',
      body: 'Compare planned and actual time to see where your hours went and plan with more clarity.',
      status: 'Finishing your daily setup',
    ),
  ];

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
    final personalLine = personalWakingHours(
      wakingHours > 0 ? wakingHours : 16,
    );

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
