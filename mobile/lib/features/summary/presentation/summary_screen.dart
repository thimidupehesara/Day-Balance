import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/summary_model.dart';
import 'summary_controller.dart';

/// End-of-day Summary screen matching Figma 13_end_of_day_summary.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(summaryControllerProvider.notifier).fetchSummary();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(summaryControllerProvider.notifier).fetchSummary();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryControllerProvider);
    final controller = ref.read(summaryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: state.isLoading && state.summary == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primarySage,
                ),
              )
            : RefreshIndicator(
                color: AppColors.primarySage,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  await controller.fetchSummary();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: AppBackButton + "Your day, in balance"
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 24,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Row(
                          children: [
                            AppBackButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/today');
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Your day, in balance',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content Body
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Date Header: "WEDNESDAY, 14 OCTOBER"
                            Text(
                              DateFormat('EEEE, d MMMM')
                                  .format(state.date)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),

                            if (!state.hasPlan)
                              _buildNoPlanState(context)
                            else ...[
                              // Headline: "You made room." / "Your day unfolded."
                              Text(
                                state.summary!.isOverBudget
                                    ? 'Your day unfolded.'
                                    : 'You made room.',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Big Stats Row
                              _buildBigStatsRow(state.summary!),

                              const SizedBox(height: 20),

                              // Legend Row: Planned vs Actual
                              _buildLegendRow(),

                              const SizedBox(height: 16),

                              // Category Paired Bars
                              _buildCategoryPairedBars(state.summary!),

                              const SizedBox(height: 16),

                              // Insight Line Card
                              _buildInsightCard(state.insightLine),

                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  /// Big Stats Row matching Figma 13:
  /// Left: actual "14h 00m" of "14h 30m planned"
  /// Right: breathing room "30m" "left as breathing room" (or overtime)
  Widget _buildBigStatsRow(PlanSummaryModel summary) {
    final actualStr = SummaryState.formatDuration(summary.totalActualSeconds);
    final plannedStr =
        SummaryState.formatDuration(summary.totalPlannedSeconds);

    final isOver = summary.isOverBudget;
    final diffSeconds = isOver
        ? summary.overBudgetSeconds
        : summary.breathingRoomSeconds;
    final diffStr = SummaryState.formatShort(diffSeconds);
    final diffSubtitle = isOver ? 'over planned time' : 'left as breathing room';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                actualStr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.primarySage,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of $plannedStr planned',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                diffStr,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: isOver ? AppColors.error : AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                diffSubtitle,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Legend indicators for Planned and Actual
  Widget _buildLegendRow() {
    return Row(
      children: [
        Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFDEDED8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Planned',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primarySage,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Actual',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.secondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Per-category paired horizontal bars
  Widget _buildCategoryPairedBars(PlanSummaryModel summary) {
    // Find the max duration among all planned and actual category values to scale bars
    int maxDuration = 1;
    for (final cat in summary.categories) {
      if (cat.plannedSeconds > maxDuration) maxDuration = cat.plannedSeconds;
      if (cat.actualSeconds > maxDuration) maxDuration = cat.actualSeconds;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summary.categories.map((cat) {
        final plannedStr = SummaryState.formatDuration(cat.plannedSeconds);
        final actualStr = SummaryState.formatDuration(cat.actualSeconds);

        final plannedFraction = (cat.plannedSeconds / maxDuration).clamp(0.0, 1.0);
        final actualFraction = (cat.actualSeconds / maxDuration).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category name & "actual / planned" duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cat.categoryName,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '$actualStr / $plannedStr',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Paired Bars
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final plannedWidth = max(4.0, totalWidth * plannedFraction);
                  final actualWidth = max(4.0, totalWidth * actualFraction);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Planned
                      Container(
                        width: plannedWidth,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Bottom Bar: Actual
                      Container(
                        width: actualWidth,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cat.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Insight Card matching Figma 13
  Widget _buildInsightCard(String insightText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E8DB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.info,
            size: 20,
            color: AppColors.primarySage,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insightText,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.primarySage,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when no plan exists for today
  Widget _buildNoPlanState(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No plan for today yet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan your day to track your categories and view your summary.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Plan my day',
            onPressed: () => context.go('/plan'),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar matching Today and Summary screens
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      color: const Color(0xFFEEE8DC),
      padding: const EdgeInsets.only(top: 8, bottom: 20, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Today Tab (Inactive)
          Semantics(
            button: true,
            label: 'Today tab',
            child: InkWell(
              onTap: () => context.go('/today'),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History / Summary Tab (Active)
          Semantics(
            button: true,
            label: 'History tab',
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.primarySage,
                    size: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'History',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.primarySage,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Profile Tab (Inactive)
          Semantics(
            button: true,
            label: 'Profile tab',
            child: InkWell(
              onTap: () {
                // Profile placeholder
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
