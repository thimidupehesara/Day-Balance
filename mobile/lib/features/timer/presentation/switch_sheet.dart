import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Modal bottom sheet confirming a switch between the currently running
/// category timer and another planned category.
/// Strictly follows Figma 11_switch_sheet.png and _11_switch_sheet.dart.
class SwitchSheet extends StatelessWidget {
  final String activeCategoryName;
  final String activeRemainingText;
  final String targetCategoryName;
  final String targetRemainingText;
  final Color targetCategoryColor;
  final IconData targetCategoryIcon;
  final VoidCallback onConfirm;

  const SwitchSheet({
    super.key,
    required this.activeCategoryName,
    required this.activeRemainingText,
    required this.targetCategoryName,
    required this.targetRemainingText,
    required this.targetCategoryColor,
    required this.targetCategoryIcon,
    required this.onConfirm,
  });

  /// Displays the switch sheet as a modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String activeCategoryName,
    required String activeRemainingText,
    required String targetCategoryName,
    required String targetRemainingText,
    required Color targetCategoryColor,
    required IconData targetCategoryIcon,
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SwitchSheet(
        activeCategoryName: activeCategoryName,
        activeRemainingText: activeRemainingText,
        targetCategoryName: targetCategoryName,
        targetRemainingText: targetRemainingText,
        targetCategoryColor: targetCategoryColor,
        targetCategoryIcon: targetCategoryIcon,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 0,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: AppColors.outline,
              ),
            ),
          ),

          // Title: "Pause [Active] and start [Target]?"
          Text(
            'Pause $activeCategoryName and start $targetCategoryName?',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle: "Your [Xh Ym] in [Active] will be waiting when you come back."
          Text(
            'Your $activeRemainingText in $activeCategoryName will be waiting when you come back.',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.secondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Target Category Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: targetCategoryColor,
            ),
            child: Row(
              children: [
                Icon(
                  targetCategoryIcon,
                  size: 24,
                  color: AppColors.text,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$targetCategoryName · $targetRemainingText remaining',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions Row: Cancel / Confirm
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Cancel switch',
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.primarySage,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Confirm Button
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Confirm switch',
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySage,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer Footnote: "Only one timer runs at a time."
          const Text(
            'Only one timer runs at a time.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.secondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
