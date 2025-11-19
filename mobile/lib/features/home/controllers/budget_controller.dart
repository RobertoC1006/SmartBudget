import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/budget.dart';
import '../../../data/repositories/budget_repository.dart';

class BudgetController extends AsyncNotifier<Budget?> {
  BudgetRepository get _repository => ref.read(budgetRepositoryProvider);

  @override
  FutureOr<Budget?> build() async {
    return _repository.currentBudget();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.currentBudget());
  }

  Future<void> save({
    required double amount,
    required int month,
    required int year,
    String? name,
    double? alertThreshold,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.saveBudget(
          amount: amount,
          month: month,
          year: year,
          name: name,
          alertThreshold: alertThreshold,
        ));
  }
}

final budgetControllerProvider =
    AsyncNotifierProvider<BudgetController, Budget?>(BudgetController.new);
