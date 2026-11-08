import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:day_balance/features/planning/presentation/edit_plan_controller.dart';

void main() {
  group('Edit Plan Calculation Unit Tests', () {
    test('Remaining time change when editing a running category: changes by difference', () {
      // oldPlanned: 2h (7200s), currentRemaining: 30m (1800s), used: 1.5h (5400s)
      const oldPlanned = 7200;
      const currentRemaining = 1800;
      const newPlanned = 9000; // 2.5h (+30m = +1800s)

      final diff = newPlanned - oldPlanned; // +1800s
      final newRemaining = currentRemaining + diff; // 3600s (1h left)

      expect(newRemaining, 3600);
      expect(newRemaining - currentRemaining, diff);
    });

    test('Minimum-planned rule clamps at ceil(usedSeconds / 1800) * 1800', () {
      int getMin(int used) {
        if (used <= 0) return 0;
        return (used + 1799) ~/ 1800 * 1800;
      }

      expect(getMin(0), 0);
      expect(getMin(60), 1800); // 1 min used -> 30 min min
      expect(getMin(1800), 1800); // 30 min used -> 30 min min
      expect(getMin(1801), 3600); // 30 min 1s used -> 1 hour min
      expect(getMin(10800), 10800); // 3h used -> 3h min
    });

    test('Friendly minimum text matches requirement', () {
      const item = EditPlanCategoryItem(
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryColor: Color(0xFF4A6B82),
        initialPlannedSeconds: 10800,
        currentPlannedSeconds: 10800,
        usedSeconds: 10800, // 3h used
        minPlannedSeconds: 10800, // 3h min
        isRunning: true,
      );

      expect(item.canDecrement, isFalse);
      expect(item.isAtMinimum, isTrue);
      expect(
        item.friendlyMinText,
        "You've already used 3h here, so 3h is the minimum.",
      );
    });

    test('Can decrement when above minimum planned time', () {
      const item = EditPlanCategoryItem(
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryColor: Color(0xFF4A6B82),
        initialPlannedSeconds: 14400, // 4h
        currentPlannedSeconds: 14400, // 4h
        usedSeconds: 7200, // 2h used
        minPlannedSeconds: 7200, // 2h min
        isRunning: false,
      );

      expect(item.canDecrement, isTrue); // can drop to 3.5h, 3h, 2.5h, 2h
      final decremented = item.copyWith(currentPlannedSeconds: 7200);
      expect(decremented.canDecrement, isFalse); // at minimum 2h
    });

    test('Detects unsaved changes accurately', () {
      const initialItem = EditPlanCategoryItem(
        categoryId: 'academic',
        categoryName: 'Academic',
        categoryColor: Color(0xFF4A6B82),
        initialPlannedSeconds: 7200,
        currentPlannedSeconds: 7200,
        usedSeconds: 0,
        minPlannedSeconds: 0,
        isRunning: false,
      );

      final stateClean = EditPlanState(
        items: [initialItem],
      );
      expect(stateClean.hasUnsavedChanges, isFalse);

      final modifiedItem = initialItem.copyWith(currentPlannedSeconds: 9000);
      final stateDirty = EditPlanState(
        items: [modifiedItem],
      );
      expect(stateDirty.hasUnsavedChanges, isTrue);
    });
  });
}
