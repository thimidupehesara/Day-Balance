import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/constants/categories.dart';

class OnboardingRepository {
  final Dio _dio;

  OnboardingRepository(this._dio);

  Future<List<Category>> getAvailableCategories() async {
    final response = await _dio.get('/api/categories/available');
    return (response.data['data']['categories'] as List)
        .map(
          (json) => Category.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  Future<Category> createCustomCategory({
    required String name,
    required String description,
    required String color,
  }) async {
    try {
      final response = await _dio.post(
        '/api/categories/custom',
        data: {'name': name, 'description': description, 'color': color},
      );
      return Category.fromJson(
        Map<String, dynamic>.from(response.data['data']['category'] as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error'] ??
            'Could not save this category. Please try again.',
      );
    }
  }

  Future<UserModel> updateProfile({
    String? wakeTime,
    String? bedtime,
    int? routineMinutes,
    bool? onboardingDone,
    String? displayName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (wakeTime != null) data['wakeTime'] = wakeTime;
      if (bedtime != null) data['bedtime'] = bedtime;
      if (routineMinutes != null) data['routineMinutes'] = routineMinutes;
      if (onboardingDone != null) data['onboardingDone'] = onboardingDone;
      if (displayName != null) data['displayName'] = displayName;

      final response = await _dio.patch('/api/users/me', data: data);

      final userJson = response.data['data']['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] ?? e.message ?? 'Failed to update profile';
      throw Exception(msg);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/api/users/me');
      final userJson = response.data['data']['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] ?? e.message ?? 'Failed to get profile';
      throw Exception(msg);
    }
  }

  Future<List<String>> updateUserCategories(List<String> categoryIds) async {
    try {
      final response = await _dio.put(
        '/api/categories/mine',
        data: {'categoryIds': categoryIds},
      );
      final rawList = response.data['data']['categories'] as List<dynamic>;
      return rawList.map((item) => item['id'] as String).toList();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] ??
          e.message ??
          'Failed to update categories';
      throw Exception(msg);
    }
  }

  Future<List<String>> getUserCategories() async {
    try {
      final response = await _dio.get('/api/categories/mine');
      final rawList = response.data['data']['categories'] as List<dynamic>;
      return rawList.map((item) => item['id'] as String).toList();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] ??
          e.message ??
          'Failed to fetch user categories';
      throw Exception(msg);
    }
  }

  /// Fetches aggregate similar routines statistics.
  /// Enforces <= 1500ms timeout.
  /// Never throws: returns { 'showable': false, 'similarCount': null } on any error or timeout.
  Future<Map<String, dynamic>> getSimilarRoutines({
    String? wakeTime,
    String? bedtime,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (wakeTime != null) queryParams['wakeTime'] = wakeTime;
      if (bedtime != null) queryParams['bedtime'] = bedtime;

      final response = await _dio.get(
        '/api/stats/similar-routines',
        queryParameters: queryParams,
        options: Options(
          receiveTimeout: const Duration(milliseconds: 1500),
          sendTimeout: const Duration(milliseconds: 1500),
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {'showable': false, 'similarCount': null, 'totalUsers': 0};
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OnboardingRepository(dio);
});
