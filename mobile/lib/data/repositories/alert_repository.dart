import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/alert.dart';

class AlertRepository {
  AlertRepository(this._dio);

  final Dio _dio;

  Future<List<AlertMessage>> fetchAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      final data = response.data as List<dynamic>;
      return data.map((json) => AlertMessage.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener las alertas');
    }
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AlertRepository(dio);
});
