import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/goal.dart';
import '../../../data/repositories/goal_repository.dart';

class GoalsController extends AsyncNotifier<List<Goal>> {
  late final GoalRepository _repository;

  @override
  FutureOr<List<Goal>> build() async {
    _repository = ref.read(goalRepositoryProvider);
    return _repository.fetchGoals();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchGoals());
  }

  Future<void> createGoal({
    required String name,
    required double amount,
    String? description,
    DateTime? targetDate,
  }) async {
    await _repository.createGoal(
      name: name,
      targetAmount: amount,
      description: description,
      targetDate: targetDate,
    );
    await refresh();
  }

  Future<void> updateProgress(String goalId, double amount) async {
    await _repository.updateProgress(goalId, amount);
    await refresh();
  }
}

final goalsControllerProvider =
    AsyncNotifierProvider<GoalsController, List<Goal>>(GoalsController.new);
