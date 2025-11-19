import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/expense.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpensesController extends AsyncNotifier<List<Expense>> {
  ExpenseCategory? _filter;
  String? _budgetId;
  ExpenseRepository get _repository => ref.read(expenseRepositoryProvider);

  ExpenseCategory? get filter => _filter;
  String? get budgetId => _budgetId;

  @override
  FutureOr<List<Expense>> build() async {
    return _repository.fetchExpenses(budgetId: _budgetId);
  }

  Future<void> load({ExpenseCategory? category}) async {
    _filter = category ?? _filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.fetchExpenses(category: _filter, budgetId: _budgetId),
    );
  }

  Future<void> createExpense(ExpenseDraft draft) async {
    await _repository.createExpense(draft);
    await load();
  }

  Future<void> setBudgetFilter(String? budgetId) async {
    if (_budgetId == budgetId) return;
    _budgetId = budgetId;
    await load();
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(ExpensesController.new);

final expensesFilterProvider = Provider<ExpenseCategory?>((ref) {
  return ref.watch(expensesControllerProvider.notifier).filter;
});
