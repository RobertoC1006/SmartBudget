import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/expense.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpensesController extends AsyncNotifier<List<Expense>> {
  ExpenseCategory? _filter;
  late final ExpenseRepository _repository;

  ExpenseCategory? get filter => _filter;

  @override
  FutureOr<List<Expense>> build() async {
    _repository = ref.read(expenseRepositoryProvider);
    return _repository.fetchExpenses();
  }

  Future<void> load({ExpenseCategory? category}) async {
    _filter = category;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchExpenses(category: _filter));
  }

  Future<void> createExpense(ExpenseDraft draft) async {
    await _repository.createExpense(draft);
    await load(category: _filter);
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(ExpensesController.new);

final expensesFilterProvider = Provider<ExpenseCategory?>((ref) {
  return ref.watch(expensesControllerProvider.notifier).filter;
});
