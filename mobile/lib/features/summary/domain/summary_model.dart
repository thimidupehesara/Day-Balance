import 'package:flutter/material.dart';

class CategorySummaryModel {
  final String categoryId;
  final String categoryName;
  final String categoryDescription;
  final String categoryColorHex;
  final String categoryIcon;
  final int plannedSeconds;
  final int actualSeconds;
  final int remainingSeconds;
  final int overtimeSeconds;
  final bool isRunning;
  final DateTime? startedAt;

  const CategorySummaryModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription = '',
    required this.categoryColorHex,
    this.categoryIcon = '',
    required this.plannedSeconds,
    required this.actualSeconds,
    required this.remainingSeconds,
    required this.overtimeSeconds,
    required this.isRunning,
    this.startedAt,
  });

  Color get color {
    try {
      final hex = categoryColorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF85897D);
    }
  }

  factory CategorySummaryModel.fromJson(Map<String, dynamic> json) {
    return CategorySummaryModel(
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      categoryDescription: json['categoryDescription'] as String? ?? '',
      categoryColorHex: json['categoryColor'] as String? ?? '#85897D',
      categoryIcon: json['categoryIcon'] as String? ?? '',
      plannedSeconds: json['plannedSeconds'] as int? ?? 0,
      actualSeconds: json['actualSeconds'] as int? ?? 0,
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
      overtimeSeconds: json['overtimeSeconds'] as int? ?? 0,
      isRunning: json['isRunning'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
    );
  }
}

class PlanSummaryModel {
  final String? planId;
  final String planDate;
  final int wakingSeconds;
  final int totalPlannedSeconds;
  final int totalActualSeconds;
  final List<CategorySummaryModel> categories;
  final DateTime serverTime;

  const PlanSummaryModel({
    this.planId,
    required this.planDate,
    required this.wakingSeconds,
    required this.totalPlannedSeconds,
    required this.totalActualSeconds,
    required this.categories,
    required this.serverTime,
  });

  bool get hasPlan => planId != null && categories.isNotEmpty;

  int get breathingRoomSeconds {
    final unallocated = wakingSeconds - totalPlannedSeconds;
    return unallocated > 0 ? unallocated : 0;
  }

  bool get isOverBudget => totalActualSeconds > totalPlannedSeconds;

  int get overBudgetSeconds =>
      isOverBudget ? (totalActualSeconds - totalPlannedSeconds) : 0;

  factory PlanSummaryModel.fromJson(
    Map<String, dynamic> json,
    String? serverTimeStr,
  ) {
    final catList = (json['categories'] as List<dynamic>?) ?? [];
    return PlanSummaryModel(
      planId: json['planId'] as String?,
      planDate: json['planDate'] as String? ?? '',
      wakingSeconds: json['wakingSeconds'] as int? ?? 0,
      totalPlannedSeconds: json['totalPlannedSeconds'] as int? ?? 0,
      totalActualSeconds: json['totalActualSeconds'] as int? ?? 0,
      categories: catList
          .map((c) => CategorySummaryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      serverTime: serverTimeStr != null
          ? (DateTime.tryParse(serverTimeStr) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
