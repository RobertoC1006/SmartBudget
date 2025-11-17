import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/goal.dart';

class GoalRepository {
  GoalRepository(this._dio);

  final Dio _dio;

  Future<List<Goal>> fetchGoals() async {
    try {
      final response = await _dio.get('/goals/');
      final data = response.data as List<dynamic>;
      return data.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible cargar las metas');
    }
  }

  Future<void> createGoal({
    required String name,
    required double targetAmount,
    String? description,
    DateTime? targetDate,
  }) async {
    try {
      await _dio.post(
        '/goals/',
        data: {
          'name': name,
          'target_amount': targetAmount,
          'description': description,
          'target_date': targetDate?.toIso8601String().substring(0, 10),
        },
      );
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible crear la meta');
    }
  }

  Future<void> updateProgress(String goalId, double amount) async {
    try {
      await _dio.post('/goals/$goalId/progress', queryParameters: {'amount': amount});
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible actualizar la meta');
    }
  }

  Future<List<String>> suggestions() async {
    try {
      final response = await _dio.get('/goals/suggestions');
      final data = response.data as List<dynamic>;
      return data.cast<String>();
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener sugerencias');
    }
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GoalRepository(dio);
});
