import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/notifications/notification_service.dart';
import '../../auth/domain/user_model.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../planning/domain/plan_model.dart';
import '../data/timer_repository.dart';

class TodayTimerState {
  final UserModel? user;
  final String? planId;
  final List<PlanItemModel> items;
  final int wakingSeconds;
  final String? activeItemId;
  final DateTime? activeStartedAt;
  final int activeRemainingSeconds;
  final Duration serverOffset;
  final DateTime now;
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;
  final Set<String> notifiedOvertimeCategories;

  const TodayTimerState({
    this.user,
    this.planId,
    this.items = const [],
    this.wakingSeconds = 16 * 3600,
    this.activeItemId,
    this.activeStartedAt,
    this.activeRemainingSeconds = 0,
    this.serverOffset = Duration.zero,
    required this.now,
    this.isLoading = false,
    this.isOffline = false,
    this.errorMessage,
    this.notifiedOvertimeCategories = const {},
  });

  bool get hasPlanForToday => planId != null && items.isNotEmpty;

  DateTime get effectiveNow => now.add(serverOffset);

  /// Computes the exact real-time remaining seconds for any item,
  /// corrected for server clock offset.
  int getRemainingSecondsForItem(PlanItemModel item) {
    if (item.id == activeItemId && activeStartedAt != null) {
      final elapsed = effectiveNow.difference(activeStartedAt!).inSeconds;
      return activeRemainingSeconds - elapsed;
    }
    return item.remainingSeconds;
  }

  bool isItemRunning(PlanItemModel item) => item.id == activeItemId;

  bool isItemOvertime(PlanItemModel item) {
    return getRemainingSecondsForItem(item) < 0;
  }

  int getOvertimeSecondsForItem(PlanItemModel item) {
    final rem = getRemainingSecondsForItem(item);
    return rem < 0 ? -rem : 0;
  }

  /// Total remaining seconds across all categories plus unallocated breathing room
  int get totalHoursLeftSeconds {
    if (items.isEmpty) return wakingSeconds;
    final totalRemainingFromCategories = items.fold(0, (sum, item) {
      final rem = getRemainingSecondsForItem(item);
      return sum + (rem > 0 ? rem : 0);
    });
    final totalPlanned = items.fold(0, (sum, item) => sum + item.plannedSeconds);
    final unallocatedBreathingRoom = max(0, wakingSeconds - totalPlanned);
    return totalRemainingFromCategories + unallocatedBreathingRoom;
  }

  /// Total planned seconds across all categories for today
  int get totalPlannedSeconds {
    return items.fold(0, (sum, item) => sum + item.plannedSeconds);
  }

  /// Format running active timer (e.g. "2:45:00")
  static String formatCountdown(int seconds) {
    final sTotal = seconds < 0 ? -seconds : seconds;
    final h = sTotal ~/ 3600;
    final m = (sTotal % 3600) ~/ 60;
    final s = sTotal % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Format overtime string matching Figma: "+0:12:30 over"
  static String formatOvertime(int overtimeSeconds) {
    final h = overtimeSeconds ~/ 3600;
    final m = (overtimeSeconds % 3600) ~/ 60;
    final s = overtimeSeconds % 60;
    return '+$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} over';
  }

  /// Standard duration format matching Figma: "14h 30m", "2h 00m", "0h 30m"
  static String formatDuration(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Short duration format: "4h", "2h", "1h 30m", "30m"
  static String formatShort(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// Overtime used string: e.g. "4h 12m" for "Planned 4h · 4h 12m used"
  static String formatUsed(int plannedSec, int overtimeSec) {
    final totalUsed = plannedSec + overtimeSec;
    final h = totalUsed ~/ 3600;
    final m = (totalUsed % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// Greeting with user's name: "Hello, `<name>`"; fallback "Hello!"
  String get greeting {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return 'Hello, $name';
    }
    return 'Hello!';
  }

  TodayTimerState copyWith({
    UserModel? user,
    String? planId,
    bool clearPlanId = false,
    List<PlanItemModel>? items,
    int? wakingSeconds,
    String? activeItemId,
    bool clearActiveItem = false,
    DateTime? activeStartedAt,
    int? activeRemainingSeconds,
    Duration? serverOffset,
    DateTime? now,
    bool? isLoading,
    bool? isOffline,
    String? errorMessage,
    bool clearError = false,
    Set<String>? notifiedOvertimeCategories,
  }) {
    return TodayTimerState(
      user: user ?? this.user,
      planId: clearPlanId ? null : (planId ?? this.planId),
      items: items ?? this.items,
      wakingSeconds: wakingSeconds ?? this.wakingSeconds,
      activeItemId:
          clearActiveItem ? null : (activeItemId ?? this.activeItemId),
      activeStartedAt:
          clearActiveItem ? null : (activeStartedAt ?? this.activeStartedAt),
      activeRemainingSeconds: clearActiveItem
          ? 0
          : (activeRemainingSeconds ?? this.activeRemainingSeconds),
      serverOffset: serverOffset ?? this.serverOffset,
      now: now ?? this.now,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notifiedOvertimeCategories:
          notifiedOvertimeCategories ?? this.notifiedOvertimeCategories,
    );
  }
}

class TodayController extends Notifier<TodayTimerState> {
  Timer? _ticker;

  @override
  TodayTimerState build() {
    _startTicker();

    ref.onDispose(() {
      _ticker?.cancel();
    });

    return TodayTimerState(now: DateTime.now());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final newNow = DateTime.now();
      state = state.copyWith(now: newNow);
      _checkOvertimeThreshold();
    });
  }

  void _checkOvertimeThreshold() {
    if (state.activeItemId == null || state.activeStartedAt == null) return;

    final activeItem = state.items.firstWhere(
      (item) => item.id == state.activeItemId,
      orElse: () => PlanItemModel(
        id: '',
        dailyPlanId: '',
        categoryId: '',
        categoryName: '',
        categoryDescription: '',
        categoryColor: '',
        categoryIcon: '',
        plannedSeconds: 0,
        remainingSeconds: 0,
      ),
    );

    if (activeItem.id.isEmpty) return;

    final currentRemaining = state.getRemainingSecondsForItem(activeItem);

    if (currentRemaining <= 0 &&
        !state.notifiedOvertimeCategories.contains(activeItem.id)) {
      final updatedNotified =
          Set<String>.from(state.notifiedOvertimeCategories)..add(activeItem.id);
      state = state.copyWith(notifiedOvertimeCategories: updatedNotified);
      NotificationService.showOvertimeNotification(
        categoryName: activeItem.categoryName,
      );
    }
  }

  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final timerRepo = ref.read(timerRepositoryProvider);

      UserModel? user;
      int wakingSec = 16 * 3600;

      try {
        user = await onboardingRepo.getProfile();
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
      } catch (_) {
        // Non-blocking fallback if profile fetch fails
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final status = await timerRepo.getStatus(todayStr);

      final serverTime = DateTime.tryParse(status.serverTime) ?? DateTime.now();
      final serverOffset = serverTime.difference(DateTime.now());

      String? activeId;
      DateTime? startedAt;
      int remSeconds = 0;

      if (status.activeItem != null) {
        activeId = status.activeItem!.id;
        startedAt = status.activeItem!.startedAt;
        remSeconds = status.activeItem!.remainingSeconds;
      }

      state = state.copyWith(
        user: user,
        planId: status.planId,
        clearPlanId: status.planId == null,
        items: status.items,
        wakingSeconds: wakingSec,
        activeItemId: activeId,
        clearActiveItem: activeId == null,
        activeStartedAt: startedAt,
        activeRemainingSeconds: remSeconds,
        serverOffset: serverOffset,
        isLoading: false,
        isOffline: false,
        now: DateTime.now(),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final isOfflineErr = msg.toLowerCase().contains('connection') ||
          msg.toLowerCase().contains('socket') ||
          msg.toLowerCase().contains('network') ||
          msg.toLowerCase().contains('offline');

      state = state.copyWith(
        isLoading: false,
        isOffline: isOfflineErr,
        errorMessage: msg,
      );
    }
  }

  Future<void> startTimer(String planItemId) async {
    try {
      final repo = ref.read(timerRepositoryProvider);
      final activeItem = await repo.startTimer(planItemId);

      // Re-fetch fresh list so auto-paused item is also updated
      await fetchStatus();

      state = state.copyWith(
        activeItemId: activeItem.id,
        activeStartedAt: activeItem.startedAt,
        activeRemainingSeconds: activeItem.remainingSeconds,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: msg);
    }
  }

  Future<void> pauseTimer() async {
    try {
      final repo = ref.read(timerRepositoryProvider);
      await repo.pauseTimer();

      await fetchStatus();
      state = state.copyWith(clearActiveItem: true);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: msg);
    }
  }
}

final todayControllerProvider =
    NotifierProvider<TodayController, TodayTimerState>(TodayController.new);
