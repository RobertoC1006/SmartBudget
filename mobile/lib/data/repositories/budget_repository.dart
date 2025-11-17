import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/budget.dart';

class BudgetRepository {
  BudgetRepository(this._dio);

  final Dio _dio;

  Future<Budget> saveBudget({
    required double amount,
    required int month,
    required int year,
    String? name,
    double? alertThreshold,
  }) async {
    try {
      final response = await _dio.post(
        '/budgets/',
        data: {
          'amount': amount,
          'month': month,
          'year': year,
          'name': name,
          'alert_threshold': alertThreshold,
        },
      );
      return Budget.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible guardar el presupuesto');
    }
  }

  Future<Budget?> currentBudget() async {
    try {
      final response = await _dio.get('/budgets/current');
      return Budget.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener el presupuesto');
    }
  }

  Future<List<Budget>> history() async {
    try {
      final response = await _dio.get('/budgets/history');
      final data = response.data as List<dynamic>;
      return data.map((json) => Budget.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener el historial');
    }
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BudgetRepository(dio);
});
