import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/categories.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/plans_repository.dart';

class PlanState {
  final int wakingSeconds;
  final Map<String, int> plannedSeconds; // categoryId -> plannedSeconds
  final List<String> selectedCategoryIds;
  final String? existingPlanId;
  final bool isLoading;
  final String? errorMessage;

  const PlanState({
    this.wakingSeconds = 16 * 3600, // default 16 hours
    this.plannedSeconds = const {},
    this.selectedCategoryIds = const [],
    this.existingPlanId,
    this.isLoading = false,
    this.errorMessage,
  });

  int get totalPlannedSeconds {
    return plannedSeconds.values.fold(0, (sum, val) => sum + val);
  }

  int get diffSeconds => wakingSeconds - totalPlannedSeconds;

  int get secondsLeftToPlan => max(0, diffSeconds);

  bool get isOverAllocated => diffSeconds < 0;

  int get overAllocatedSeconds => diffSeconds < 0 ? -diffSeconds : 0;

  bool get isZeroHoursLeft => diffSeconds == 0 && totalPlannedSeconds > 0;

  int get entertainmentSeconds => plannedSeconds['entertainment'] ?? 0;

  double get entertainmentRatio {
    if (totalPlannedSeconds <= 0) return 0.0;
    return entertainmentSeconds / totalPlannedSeconds;
  }

  bool get hasEntertainmentWarning => entertainmentRatio > 0.30;

  bool get canStartDay => !isOverAllocated && totalPlannedSeconds > 0 && !isLoading;

  /// Standard duration format matching Figma: e.g. "0h 30m", "14h 30m", "4h 00m"
  static String formatDuration(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Compact duration format: e.g. "30m", "1h", "1h 30m"
  static String formatShort(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  PlanState copyWith({
    int? wakingSeconds,
    Map<String, int>? plannedSeconds,
    List<String>? selectedCategoryIds,
    String? existingPlanId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlanState(
      wakingSeconds: wakingSeconds ?? this.wakingSeconds,
      plannedSeconds: plannedSeconds ?? this.plannedSeconds,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      existingPlanId: existingPlanId ?? this.existingPlanId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PlanController extends Notifier<PlanState> {
  static const int stepSeconds = 1800; // 30 minutes

  @override
  PlanState build() => const PlanState();

  Future<void> initPlanForToday() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final plansRepo = ref.read(plansRepositoryProvider);

      final user = await onboardingRepo.getProfile();
      List<String> userCategories = await onboardingRepo.getUserCategories();
      if (userCategories.isEmpty) {
        userCategories = kCategories.map((c) => c.id).toList();
      }

      // Calculate waking seconds from profile
      int wakingSec = 16 * 3600; // fallback
      if (user.wakeTime != null && user.bedtime != null) {
        final wakeParts = user.wakeTime!.split(':');
        final bedParts = user.bedtime!.split(':');
        int wakeMin = int.parse(wakeParts[0]) * 60 + int.parse(wakeParts[1]);
        int bedMin = int.parse(bedParts[0]) * 60 + int.parse(bedParts[1]);
        if (bedMin <= wakeMin) bedMin += 24 * 60;
        final routineMin = user.routineMinutes ?? 0;
        final netMin = max(60, (bedMin - wakeMin) - routineMin);
        wakingSec = netMin * 60;
      }

      // Check if plan already exists for today
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final existingPlan = await plansRepo.getTodayPlan(todayStr);

      final map = <String, int>{};
      for (final catId in userCategories) {
        map[catId] = 0;
      }

      String? planId;
      if (existingPlan != null) {
        planId = existingPlan.id;
        wakingSec = existingPlan.wakingSeconds;
        for (final item in existingPlan.items) {
          map[item.categoryId] = item.plannedSeconds;
        }
      }

      state = state.copyWith(
        wakingSeconds: wakingSec,
        plannedSeconds: map,
        selectedCategoryIds: userCategories,
        existingPlanId: planId,
        isLoading: false,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  void incrementCategory(String categoryId) {
    if (state.totalPlannedSeconds + stepSeconds > 24 * 3600) return;

    final updated = Map<String, int>.from(state.plannedSeconds);
    updated[categoryId] = (updated[categoryId] ?? 0) + stepSeconds;
    state = state.copyWith(plannedSeconds: updated, clearError: true);
  }

  void decrementCategory(String categoryId) {
    final current = state.plannedSeconds[categoryId] ?? 0;
    if (current < stepSeconds) return;

    final updated = Map<String, int>.from(state.plannedSeconds);
    updated[categoryId] = current - stepSeconds;
    state = state.copyWith(plannedSeconds: updated, clearError: true);
  }

  Future<bool> savePlan() async {
    if (state.isOverAllocated) {
      state = state.copyWith(
        errorMessage: 'Free up time to continue',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plansRepo = ref.read(plansRepositoryProvider);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final itemsPayload = state.plannedSeconds.entries
          .where((entry) => entry.value > 0)
          .map((entry) => {
                'categoryId': entry.key,
                'plannedSeconds': entry.value,
              })
          .toList();

      if (itemsPayload.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Assign time to at least one category to start your day',
        );
        return false;
      }

      if (state.existingPlanId != null) {
        await plansRepo.updatePlan(
          planId: state.existingPlanId!,
          wakingSeconds: state.wakingSeconds,
          items: itemsPayload,
        );
      } else {
        await plansRepo.createPlan(
          planDate: todayStr,
          wakingSeconds: state.wakingSeconds,
          items: itemsPayload,
        );
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }
}

final planControllerProvider =
    NotifierProvider<PlanController, PlanState>(PlanController.new);
