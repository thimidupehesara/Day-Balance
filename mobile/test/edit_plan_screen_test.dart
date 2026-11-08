import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:day_balance/features/planning/presentation/edit_plan_controller.dart';
import 'package:day_balance/features/planning/presentation/edit_plan_screen.dart';

class TestEditPlanController extends EditPlanController {
  final EditPlanState _initialState;
  TestEditPlanController(this._initialState);

  @override
  EditPlanState build() => _initialState;

  @override
  Future<void> initFromToday() async {}
}

void main() {
  Widget createWidget(EditPlanState state) {
    return ProviderScope(
      overrides: [
        editPlanControllerProvider
            .overrideWith(() => TestEditPlanController(state)),
      ],
      child: const MaterialApp(
        home: EditPlanScreen(),
      ),
    );
  }

  group('EditPlanScreen Widget Tests', () {
    testWidgets('renders Edit today’s plan header, hours left, and categories',
        (tester) async {
      final state = EditPlanState(
        planId: 'plan-123',
        wakingSeconds: 14 * 3600 + 1800, // 14h 30m
        runningCategoryName: 'Academic',
        items: const [
          EditPlanCategoryItem(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColor: Color(0xFF4A6B82),
            initialPlannedSeconds: 4 * 3600,
            currentPlannedSeconds: 4 * 3600,
            usedSeconds: 3 * 3600, // 3h used
            minPlannedSeconds: 3 * 3600, // 3h min
            isRunning: true,
          ),
          EditPlanCategoryItem(
            categoryId: 'life_family',
            categoryName: 'Life/Family',
            categoryColor: Color(0xFFEBD3BC),
            initialPlannedSeconds: 2 * 3600,
            currentPlannedSeconds: 2 * 3600,
            usedSeconds: 0,
            minPlannedSeconds: 0,
            isRunning: false,
          ),
        ],
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Edit today’s plan'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Hours Left Card
      expect(
        find.text('Hours left to plan · 14h 30m available'),
        findsOneWidget,
      );
      // 14h 30m waking - 6h planned = 8h 30m left
      expect(find.text('8h 30m'), findsOneWidget);

      // Categories displayed
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Life/Family'), findsOneWidget);

      // Minimum planned warning line for Academic
      expect(
        find.text("You've already used 3h here, so 3h is the minimum."),
        findsOneWidget,
      );

      // Informational note
      expect(
        find.text(
          'Used time stays put. Only your plan changes. Academic is still running.',
        ),
        findsOneWidget,
      );

      // Buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save plan'), findsOneWidget);
    });

    testWidgets('shows over-allocated warning when planned exceeds waking hours',
        (tester) async {
      const state = EditPlanState(
        planId: 'plan-123',
        wakingSeconds: 6 * 3600, // 6h waking
        items: [
          EditPlanCategoryItem(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColor: Color(0xFF4A6B82),
            initialPlannedSeconds: 7 * 3600,
            currentPlannedSeconds: 7 * 3600, // 7h planned (1h over)
            usedSeconds: 0,
            minPlannedSeconds: 0,
            isRunning: false,
          ),
        ],
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('−1h 00m'), findsOneWidget);
      expect(
        find.text('You’re 1h over. Free up time to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('prompts discard confirmation when closing with unsaved changes',
        (tester) async {
      const state = EditPlanState(
        planId: 'plan-123',
        wakingSeconds: 14 * 3600,
        items: [
          EditPlanCategoryItem(
            categoryId: 'academic',
            categoryName: 'Academic',
            categoryColor: Color(0xFF4A6B82),
            initialPlannedSeconds: 4 * 3600,
            currentPlannedSeconds: 5 * 3600, // modified!
            usedSeconds: 0,
            minPlannedSeconds: 0,
            isRunning: false,
          ),
        ],
      );

      await tester.pumpWidget(createWidget(state));
      await tester.pumpAndSettle();

      // Tap Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap Keep editing
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      // Dialog closed, still on EditPlanScreen
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit today’s plan'), findsOneWidget);
    });
  });
}
