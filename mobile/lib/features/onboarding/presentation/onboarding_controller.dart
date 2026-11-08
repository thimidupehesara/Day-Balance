import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_repository.dart';
import '../../../core/constants/categories.dart';

class OnboardingState {
  final TimeOfDay wakeTime;
  final TimeOfDay bedtime;
  final int morningRoutineMinutes;
  final int windUpRoutineMinutes;
  final Set<String> selectedCategories;
  final List<Category> availableCategories;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingState({
    this.wakeTime = const TimeOfDay(hour: 7, minute: 0),
    this.bedtime = const TimeOfDay(hour: 23, minute: 0),
    this.morningRoutineMinutes = 45,
    this.windUpRoutineMinutes = 45,
    this.selectedCategories = const {
      'academic',
      'life_family',
      'entertainment',
      'personal_reading',
      'career',
      'unplanned',
      'rest',
    },
    this.isLoading = false,
    this.availableCategories = kCategories,
    this.errorMessage,
  });

  /// Total minutes of morning + wind-up routines
  int get routineMinutes => morningRoutineMinutes + windUpRoutineMinutes;

  /// Total minutes awake between wake time and bedtime
  int get grossWakingMinutes {
    int wakeTotal = wakeTime.hour * 60 + wakeTime.minute;
    int bedTotal = bedtime.hour * 60 + bedtime.minute;
    if (bedTotal <= wakeTotal) {
      bedTotal += 24 * 60; // spans across midnight
    }
    return bedTotal - wakeTotal;
  }

  /// Sleep minutes in 24h
  int get sleepMinutes => (24 * 60) - grossWakingMinutes;

  /// Net minutes available after deducting fixed daily routines
  int get netAvailableMinutes {
    return max(0, grossWakingMinutes - routineMinutes);
  }

  /// Formatted gross waking hours e.g. "16h 00m"
  String get grossHoursFormatted {
    final h = grossWakingMinutes ~/ 60;
    final m = grossWakingMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Formatted net hours to plan e.g. "14h 30m"
  String get netHoursFormatted {
    final h = netAvailableMinutes ~/ 60;
    final m = netAvailableMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Subtitle string e.g. "7 AM — 11 PM awake · 8 hours of sleep"
  String get awakeRangeFormatted {
    String formatT(TimeOfDay t) {
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      return t.minute == 0
          ? '$h $period'
          : '$h:${t.minute.toString().padLeft(2, '0')} $period';
    }

    final sleepH = sleepMinutes ~/ 60;
    final sleepM = sleepMinutes % 60;
    final sleepStr = sleepM == 0
        ? '$sleepH hours of sleep'
        : '$sleepH h $sleepM m of sleep';
    return '${formatT(wakeTime)} — ${formatT(bedtime)} awake · $sleepStr';
  }

  OnboardingState copyWith({
    TimeOfDay? wakeTime,
    TimeOfDay? bedtime,
    int? morningRoutineMinutes,
    int? windUpRoutineMinutes,
    int? routineMinutes,
    Set<String>? selectedCategories,
    List<Category>? availableCategories,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    int finalMorning = morningRoutineMinutes ?? this.morningRoutineMinutes;
    int finalWindUp = windUpRoutineMinutes ?? this.windUpRoutineMinutes;
    if (routineMinutes != null &&
        morningRoutineMinutes == null &&
        windUpRoutineMinutes == null) {
      finalMorning = routineMinutes ~/ 2;
      finalWindUp = routineMinutes - finalMorning;
    }

    return OnboardingState(
      wakeTime: wakeTime ?? this.wakeTime,
      bedtime: bedtime ?? this.bedtime,
      morningRoutineMinutes: finalMorning,
      windUpRoutineMinutes: finalWindUp,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      availableCategories: availableCategories ?? this.availableCategories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  Future<void> loadAvailableCategories() async {
    try {
      final available = await ref
          .read(onboardingRepositoryProvider)
          .getAvailableCategories();
      if (!ref.mounted) return;
      // A creation may finish while this earlier request is still in flight.
      final merged = {for (final c in available) c.id: c};
      for (final c in state.availableCategories) {
        if (c.id.startsWith('custom:')) merged.putIfAbsent(c.id, () => c);
      }
      state = state.copyWith(
        availableCategories: merged.values.toList(),
        clearError: true,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        errorMessage:
            'Could not load saved custom categories. Tap retry to load them.',
      );
    }
  }

  Future<bool> addCustomCategory(
    String name,
    String description,
    String color,
  ) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final category = await ref
          .read(onboardingRepositoryProvider)
          .createCustomCategory(
            name: name.trim(),
            description: description.trim(),
            color: color,
          );
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        availableCategories: [...state.availableCategories, category],
        selectedCategories: {...state.selectedCategories, category.id},
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void setWakeTime(TimeOfDay time) {
    state = state.copyWith(wakeTime: time);
  }

  void setBedtime(TimeOfDay time) {
    state = state.copyWith(bedtime: time);
  }

  void setMorningRoutineMinutes(int minutes) {
    final maxAllowed = max(
      0,
      state.grossWakingMinutes - state.windUpRoutineMinutes,
    );
    final clamped = minutes.clamp(0, maxAllowed);
    state = state.copyWith(morningRoutineMinutes: clamped);
  }

  void setWindUpRoutineMinutes(int minutes) {
    final maxAllowed = max(
      0,
      state.grossWakingMinutes - state.morningRoutineMinutes,
    );
    final clamped = minutes.clamp(0, maxAllowed);
    state = state.copyWith(windUpRoutineMinutes: clamped);
  }

  void setRoutineMinutes(int minutes) {
    state = state.copyWith(routineMinutes: max(0, minutes));
  }

  void toggleCategory(String categoryId) {
    final updated = Set<String>.from(state.selectedCategories);
    if (updated.contains(categoryId)) {
      if (updated.length > 1) {
        updated.remove(categoryId);
      }
    } else {
      updated.add(categoryId);
    }
    state = state.copyWith(selectedCategories: updated);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<bool> saveSchedule() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateProfile(
        wakeTime: _formatTimeOfDay(state.wakeTime),
        bedtime: _formatTimeOfDay(state.bedtime),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> saveRoutine() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateProfile(routineMinutes: state.routineMinutes);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateUserCategories(state.selectedCategories.toList());
      await repo.updateProfile(onboardingDone: true);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  /// Full save of all onboarding preferences:
  /// wake time, bedtime, routine minutes, categories, and onboardingDone = true.
  Future<bool> completeFullOnboarding() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateUserCategories(state.selectedCategories.toList());
      if (!ref.mounted) return false;
      await repo.updateProfile(
        wakeTime: _formatTimeOfDay(state.wakeTime),
        bedtime: _formatTimeOfDay(state.bedtime),
        routineMinutes: state.routineMinutes,
        onboardingDone: true,
      );
      if (!ref.mounted) return false;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
