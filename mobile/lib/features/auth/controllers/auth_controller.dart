import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/token_storage.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../expenses/controllers/expenses_controller.dart';
import '../../goals/controllers/goals_controller.dart';
import '../../goals/providers.dart';
import '../../home/controllers/budget_controller.dart';
import '../../home/providers.dart';

class AuthController extends AsyncNotifier<User?> {
  late final AuthRepository _repository;
  late final TokenStorage _storage;

  @override
  FutureOr<User?> build() async {
    _repository = ref.read(authRepositoryProvider);
    _storage = ref.read(tokenStorageProvider);
    final token = await _storage.readAccessToken();
    if (token == null) {
      return null;
    }
    try {
      final user = await _repository.fetchProfile();
      return user;
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _repository.register(fullName: fullName, email: email, password: password);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.login(email, password);
      final user = await _repository.fetchProfile();
      _invalidateUserScopedProviders();
      return user;
    });
  }

  Future<void> logout() async {
    await _repository.logout();
    _invalidateUserScopedProviders();
    state = const AsyncData(null);
  }

  void _invalidateUserScopedProviders() {
    ref.invalidate(budgetControllerProvider);
    ref.invalidate(expensesControllerProvider);
    ref.invalidate(goalsControllerProvider);
    ref.invalidate(alertsProvider);
    ref.invalidate(smartScoreProvider);
    ref.invalidate(goalSuggestionsProvider);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);
