import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:day_balance/core/theme/app_colors.dart';
import 'package:day_balance/core/theme/app_icons.dart';
import 'package:day_balance/features/timer/presentation/switch_sheet.dart';

void main() {
  group('SwitchSheet Widget Tests', () {
    testWidgets('renders all Figma 11_switch_sheet elements accurately',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SwitchSheet.show(
                    context,
                    activeCategoryName: 'Academic',
                    activeRemainingText: '2h 45m',
                    targetCategoryName: 'Life/Family',
                    targetRemainingText: '2h',
                    targetCategoryColor: AppColors.lifeFamily,
                    targetCategoryIcon: AppIcons.categoryLifeFamily,
                    onConfirm: () {
                      confirmed = true;
                    },
                  );
                },
                child: const Text('Open Switch'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Switch'));
      await tester.pumpAndSettle();

      // Check title and subtitle
      expect(find.text('Pause Academic and start Life/Family?'), findsOneWidget);
      expect(
        find.text(
            'Your 2h 45m in Academic will be waiting when you come back.'),
        findsOneWidget,
      );

      // Check target category preview card
      expect(find.text('Life/Family · 2h remaining'), findsOneWidget);

      // Check CTA buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      // Check footer note
      expect(find.text('Only one timer runs at a time.'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('Cancel button dismisses sheet without calling onConfirm',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SwitchSheet.show(
                    context,
                    activeCategoryName: 'Academic',
                    activeRemainingText: '2h 45m',
                    targetCategoryName: 'Career',
                    targetRemainingText: '2h',
                    targetCategoryColor: AppColors.career,
                    targetCategoryIcon: AppIcons.categoryCareer,
                    onConfirm: () {
                      confirmed = true;
                    },
                  );
                },
                child: const Text('Open Switch'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Switch'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(find.text('Pause Academic and start Career?'), findsNothing);
    });
  });
}
