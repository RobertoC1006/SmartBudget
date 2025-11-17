import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/smart_score.dart';

class SmartScoreRepository {
  SmartScoreRepository(this._dio);

  final Dio _dio;

  Future<List<SmartScoreSnapshot>> history() async {
    try {
      final response = await _dio.get('/smartscore/history');
      final data = response.data as List<dynamic>;
      return data.map((json) => SmartScoreSnapshot.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener el SmartScore');
    }
  }
}

final smartScoreRepositoryProvider = Provider<SmartScoreRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SmartScoreRepository(dio);
});
