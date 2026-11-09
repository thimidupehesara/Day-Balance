import 'package:day_balance/core/theme/app_theme.dart';
import 'package:day_balance/features/auth/presentation/welcome_screen.dart';
import 'package:day_balance/shared/widgets/primary_button.dart';
import 'package:day_balance/shared/widgets/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }

  group('WelcomeScreen Widget Tests', () {
    testWidgets('renders the evening welcome page and entry actions',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Logo and Brand Name
      expect(find.text('Day-Balance'), findsOneWidget);

      // Display Heading and Subtitle
      expect(find.text('Make room\nfor your day.'), findsOneWidget);
      expect(
        find.text(
            'Plan your hours. Do one thing at a time.\nLeave room for life.'),
        findsOneWidget,
      );

      // Category Preview Pills inside the visual card stack
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('3 h'), findsOneWidget);

      expect(find.text('Life/Family'), findsOneWidget);
      expect(find.text('2 h'), findsOneWidget);

      expect(find.text('Rest/Recovery'), findsOneWidget);
      expect(find.text('1 h'), findsOneWidget);

      // Call to action buttons
      expect(find.byType(AppPrimaryButton), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);

      expect(find.byType(AppSecondaryButton), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
