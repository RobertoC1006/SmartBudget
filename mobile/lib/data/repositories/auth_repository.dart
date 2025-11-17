import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
        },
        options: Options(extra: {'auth': false}),
      );
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible registrarse');
    }
  }

  Future<AuthTokens> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: {'auth': false}),
      );
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens;
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible iniciar sesión');
    }
  }

  Future<User> fetchProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener el perfil');
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthRepository(dio, storage);
});
