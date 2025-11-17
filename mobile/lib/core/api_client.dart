import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'runtime_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(runtimeConfigProvider);
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final requiresAuth = options.extra['auth'] != false;
        if (requiresAuth) {
          final token = await storage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final message = _resolveMessage(error);
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(message, error.response?.statusCode),
          ),
        );
      },
    ),
  );

  return dio;
});

String _resolveMessage(DioException error) {
  final response = error.response;
  if (response == null) {
    return 'No fue posible conectar con el servidor. Intenta de nuevo.';
  }
  final data = response.data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'] ?? data['message'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }
  return 'Error inesperado (${response.statusCode ?? 'desconocido'})';
}
