import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/categories.dart';
import '../../timer/presentation/today_controller.dart';
import '../data/plans_repository.dart';

class EditPlanCategoryItem {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final int initialPlannedSeconds;
  final int currentPlannedSeconds;
  final int usedSeconds;
  final int minPlannedSeconds;
  final bool isRunning;

  const EditPlanCategoryItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.initialPlannedSeconds,
    required this.currentPlannedSeconds,
    required this.usedSeconds,
    required this.minPlannedSeconds,
    required this.isRunning,
  });

  bool get canDecrement =>
      currentPlannedSeconds - 1800 >= minPlannedSeconds &&
      currentPlannedSeconds >= 1800;

  bool get isAtMinimum =>
      minPlannedSeconds > 0 && currentPlannedSeconds == minPlannedSeconds;

  String get friendlyMinText {
    if (minPlannedSeconds <= 0) return '';
    final usedStr = TodayTimerState.formatShort(usedSeconds);
    final minStr = TodayTimerState.formatShort(minPlannedSeconds);
    return "You've already used $usedStr here, so $minStr is the minimum.";
  }

  EditPlanCategoryItem copyWith({
    int? currentPlannedSeconds,
  }) {
    return EditPlanCategoryItem(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      initialPlannedSeconds: initialPlannedSeconds,
      currentPlannedSeconds:
          currentPlannedSeconds ?? this.currentPlannedSeconds,
      usedSeconds: usedSeconds,
      minPlannedSeconds: minPlannedSeconds,
      isRunning: isRunning,
    );
  }
}

class EditPlanState {
  final String? planId;
  final int wakingSeconds;
  final List<EditPlanCategoryItem> items;
  final String? runningCategoryName;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const EditPlanState({
    this.planId,
    this.wakingSeconds = 16 * 3600,
    this.items = const [],
    this.runningCategoryName,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  int get totalPlannedSeconds =>
      items.fold(0, (sum, i) => sum + i.currentPlannedSeconds);

  int get diffSeconds => wakingSeconds - totalPlannedSeconds;

  int get secondsLeftToPlan => max(0, diffSeconds);

  bool get isOverAllocated => diffSeconds < 0;

  int get overAllocatedSeconds => diffSeconds < 0 ? -diffSeconds : 0;

  bool get isZeroHoursLeft => diffSeconds == 0 && totalPlannedSeconds > 0;

  bool get hasUnsavedChanges =>
      items.any((i) => i.currentPlannedSeconds != i.initialPlannedSeconds);

  bool get canSave =>
      !isOverAllocated && totalPlannedSeconds > 0 && !isSaving && !isLoading;

  EditPlanState copyWith({
    String? planId,
    int? wakingSeconds,
    List<EditPlanCategoryItem>? items,
    String? runningCategoryName,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditPlanState(
      planId: planId ?? this.planId,
      wakingSeconds: wakingSeconds ?? this.wakingSeconds,
      items: items ?? this.items,
      runningCategoryName: runningCategoryName ?? this.runningCategoryName,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EditPlanController extends Notifier<EditPlanState> {
  static const int stepSeconds = 1800; // 30 minutes

  @override
  EditPlanState build() => const EditPlanState();

  Future<void> initFromToday() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final todayState = ref.read(todayControllerProvider);
      final todayItems = todayState.items;

      String? runningCatName;
      final categoryItems = <EditPlanCategoryItem>[];

      for (final item in todayItems) {
        final isRunning = todayState.isItemRunning(item);
        if (isRunning) {
          runningCatName = item.categoryName;
        }

        final currentRem = todayState.getRemainingSecondsForItem(item);
        final used = max(0, item.plannedSeconds - currentRem);
        final minPlanned = used <= 0 ? 0 : (used + 1799) ~/ 1800 * 1800;

        Color catColor = const Color(0xFF85897D);
        final found = kCategories.where((c) => c.id == item.categoryId);
        if (found.isNotEmpty) {
          catColor = found.first.color;
        }

        categoryItems.add(
          EditPlanCategoryItem(
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            categoryColor: catColor,
            initialPlannedSeconds: item.plannedSeconds,
            currentPlannedSeconds: item.plannedSeconds,
            usedSeconds: used,
            minPlannedSeconds: minPlanned,
            isRunning: isRunning,
          ),
        );
      }

      state = state.copyWith(
        planId: todayState.planId,
        wakingSeconds: todayState.wakingSeconds,
        items: categoryItems,
        runningCategoryName: runningCatName,
        isLoading: false,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  void incrementCategory(String categoryId) {
    if (state.totalPlannedSeconds + stepSeconds > 24 * 3600) return;

    final updated = state.items.map((item) {
      if (item.categoryId == categoryId) {
        return item.copyWith(
          currentPlannedSeconds: item.currentPlannedSeconds + stepSeconds,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated, clearError: true);
  }

  void decrementCategory(String categoryId) {
    final updated = state.items.map((item) {
      if (item.categoryId == categoryId && item.canDecrement) {
        return item.copyWith(
          currentPlannedSeconds: item.currentPlannedSeconds - stepSeconds,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated, clearError: true);
  }

  Future<bool> savePlan() async {
    if (state.planId == null) {
      state = state.copyWith(errorMessage: 'No active plan found to update');
      return false;
    }

    if (state.isOverAllocated) {
      state = state.copyWith(errorMessage: 'Free up time to continue');
      return false;
    }

    // Verify minimum planned rule locally before network call
    for (final item in state.items) {
      if (item.currentPlannedSeconds < item.minPlannedSeconds) {
        state = state.copyWith(errorMessage: item.friendlyMinText);
        return false;
      }
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final plansRepo = ref.read(plansRepositoryProvider);

      final itemsPayload = state.items
          .where((i) => i.currentPlannedSeconds > 0)
          .map((i) => {
                'categoryId': i.categoryId,
                'plannedSeconds': i.currentPlannedSeconds,
              })
          .toList();

      await plansRepo.updatePlan(
        planId: state.planId!,
        wakingSeconds: state.wakingSeconds,
        items: itemsPayload,
      );

      // Refresh today screen so changes appear immediately
      await ref.read(todayControllerProvider.notifier).fetchStatus();

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isSaving: false, errorMessage: msg);
      return false;
    }
  }
}

final editPlanControllerProvider =
    NotifierProvider<EditPlanController, EditPlanState>(
  EditPlanController.new,
);
