import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';

/// Selectable evening card with a category-colored icon and sage checkbox.
class CategoryTile extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onToggle;

  const CategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${category.name}, ${isSelected ? "selected" : "not selected"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.alphaBlend(
                  category.color.withValues(alpha: .09),
                  AppColors.surface,
                )
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: AppColors.outline.withValues(alpha: .35),
                  width: 1,
                )
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Category Icon (22x22)
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(right: 12),
                    alignment: Alignment.center,
                    child: Icon(category.icon, size: 20, color: category.color),
                  ),

                  // Title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Custom Square Checkbox (18x18, 3dp radius)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySage
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primarySage
                            : AppColors.outline,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? const Icon(
                            AppIcons.check,
                            size: 13,
                            color: AppColors.textOnPrimary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
