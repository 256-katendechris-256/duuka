import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import 'report_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// All expenses provider
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getAll();
});

/// Today's expenses provider
final todayExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getToday();
});

/// This month's expenses provider
final monthExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getThisMonth();
});

/// Today's expense total provider
final todayExpenseTotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getTodayTotal();
});

/// This month's expense total provider
final monthExpenseTotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getMonthTotal();
});

/// Expense notifier for CRUD operations
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getAll();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Expense?> addExpense({
    required String description,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    String? notes,
    String? vendor,
    String paymentMethod = 'Cash',
    bool isRecurring = false,
  }) async {
    try {
      final expense = Expense.create(
        description: description,
        amount: amount,
        category: category,
        date: date,
        notes: notes,
        vendor: vendor,
        paymentMethod: paymentMethod,
        isRecurring: isRecurring,
      );

      final id = await _repository.save(expense);
      expense.id = id;

      await loadExpenses();
      _invalidateProviders();

      return expense;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      await _repository.save(expense);
      await loadExpenses();
      _invalidateProviders();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      final result = await _repository.delete(id);
      if (result) {
        await loadExpenses();
        _invalidateProviders();
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  void _invalidateProviders() {
    // Expenses
    _ref.invalidate(todayExpensesProvider);
    _ref.invalidate(monthExpensesProvider);
    _ref.invalidate(todayExpenseTotalProvider);
    _ref.invalidate(monthExpenseTotalProvider);
    
    // Reports
    _ref.invalidate(reportSummaryProvider);
    _ref.invalidate(periodTotalsProvider);
    _ref.invalidate(expensesByCategoryProvider);
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repository, ref);
});
