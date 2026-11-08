import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// The 7 fixed Day-Balance categories, matching the backend seed data.
class Category {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final known = kCategories.where((c) => c.id == id);
    return Category(
      id: id,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      color: Color(
        int.parse(
          'FF${(json['color'] as String).replaceAll('#', '')}',
          radix: 16,
        ),
      ),
      icon: known.isEmpty ? Icons.category_outlined : known.first.icon,
      sortOrder: json['sortOrder'] as int? ?? 100,
    );
  }
}

const List<Category> kCategories = [
  Category(
    id: 'academic',
    name: 'Academic',
    description: 'assignments, projects, tutorials, lab sheets',
    color: AppColors.academic,
    icon: AppIcons.categoryAcademic,
    sortOrder: 1,
  ),
  Category(
    id: 'life_family',
    name: 'Life/Family',
    description: 'chores, errands, family time',
    color: AppColors.lifeFamily,
    icon: AppIcons.categoryLifeFamily,
    sortOrder: 2,
  ),
  Category(
    id: 'entertainment',
    name: 'Entertainment',
    description: 'videos, games, social media',
    color: AppColors.entertainment,
    icon: AppIcons.categoryEntertainment,
    sortOrder: 3,
  ),
  Category(
    id: 'personal_reading',
    name: 'Personal/Reading',
    description: 'reading, hobbies, exercise',
    color: AppColors.personalReading,
    icon: AppIcons.categoryPersonalReading,
    sortOrder: 4,
  ),
  Category(
    id: 'career',
    name: 'Career',
    description: 'freelancing, portfolio, job applications',
    color: AppColors.career,
    icon: AppIcons.categoryCareer,
    sortOrder: 5,
  ),
  Category(
    id: 'unplanned',
    name: 'Unplanned/Extra capacity',
    description: 'buffer for surprises',
    color: AppColors.unplanned,
    icon: AppIcons.categoryUnplanned,
    sortOrder: 6,
  ),
  Category(
    id: 'rest',
    name: 'Rest/Recovery',
    description: 'naps, breaks, screen-free relaxing',
    color: AppColors.rest,
    icon: AppIcons.categoryRest,
    sortOrder: 7,
  ),
];
