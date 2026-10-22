import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/summary_model.dart';

class SummaryRepository {
  final Dio _dio;

  SummaryRepository(this._dio);

  Future<PlanSummaryModel> getSummary(String dateStr) async {
    try {
      final response = await _dio.get(
        '/api/plans/summary',
        queryParameters: {'date': dateStr},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final summaryJson = data['summary'] as Map<String, dynamic>;
      final serverTime = (response.data['serverTime'] ?? data['serverTime']) as String?;

      return PlanSummaryModel.fromJson(summaryJson, serverTime);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ??
          e.message ??
          'Failed to load daily summary';
      throw Exception(msg);
    }
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SummaryRepository(dio);
});
