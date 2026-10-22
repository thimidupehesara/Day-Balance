import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/summary_repository.dart';
import '../domain/summary_model.dart';

class SummaryState {
  final PlanSummaryModel? summary;
  final bool isLoading;
  final String? errorMessage;
  final DateTime date;

  const SummaryState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
    required this.date,
  });

  bool get hasPlan => summary != null && summary!.hasPlan;

  bool get hasAnyTrackedTime =>
      summary != null && summary!.totalActualSeconds > 0;

  static String formatDuration(int totalSec) {
    final sTotal = totalSec < 0 ? 0 : totalSec;
    final h = sTotal ~/ 3600;
    final m = (sTotal % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static String formatShort(int totalSec) {
    final sTotal = totalSec < 0 ? 0 : totalSec;
    final h = sTotal ~/ 3600;
    final m = (sTotal % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// Generates a strictly FACTUAL, non-judgmental insight line
  /// computed directly from the user's actual numbers.
  String get insightLine {
    if (summary == null || !summary!.hasPlan) {
      return 'Plan your day to see your balance breakdown.';
    }

    if (summary!.totalActualSeconds == 0) {
      return 'No time tracked yet today. Start a timer to see your progress.';
    }

    final categories = summary!.categories;

    // Check if any category had overtime
    final overtimeCat = categories
        .where((c) => c.actualSeconds > c.plannedSeconds && c.plannedSeconds > 0)
        .toList();
    if (overtimeCat.isNotEmpty) {
      // Find category with largest overtime
      overtimeCat.sort(
        (a, b) => (b.actualSeconds - b.plannedSeconds)
            .compareTo(a.actualSeconds - a.plannedSeconds),
      );
      final topOver = overtimeCat.first;
      return '${topOver.categoryName} needed a little more time. Your buffer helped the day stay flexible.';
    }

    // Find the category with highest actual time
    final activeCategories = categories.where((c) => c.actualSeconds > 0).toList();
    if (activeCategories.isNotEmpty) {
      activeCategories.sort((a, b) => b.actualSeconds.compareTo(a.actualSeconds));
      final top = activeCategories.first;
      return 'You used ${formatShort(top.actualSeconds)} of your ${formatShort(top.plannedSeconds)} ${top.categoryName} time.';
    }

    return 'Your day stayed in balance with your planned routine.';
  }

  SummaryState copyWith({
    PlanSummaryModel? summary,
    bool? isLoading,
    String? errorMessage,
    DateTime? date,
    bool clearError = false,
  }) {
    return SummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      date: date ?? this.date,
    );
  }
}

class SummaryController extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    return SummaryState(date: DateTime.now());
  }

  Future<void> fetchSummary([DateTime? date]) async {
    final targetDate = date ?? state.date;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      date: targetDate,
    );

    try {
      final summaryRepo = ref.read(summaryRepositoryProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
      final summary = await summaryRepo.getSummary(dateStr);

      state = state.copyWith(
        summary: summary,
        isLoading: false,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
    }
  }
}

final summaryControllerProvider =
    NotifierProvider<SummaryController, SummaryState>(
  SummaryController.new,
);
