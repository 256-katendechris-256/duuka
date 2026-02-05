import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class ExpenseRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get all expenses
  Future<List<Expense>> getAll() async {
    return await _isar.expenses.where().sortByDateDesc().findAll();
  }

  /// Get expense by ID
  Future<Expense?> getById(int id) async {
    return await _isar.expenses.get(id);
  }

  /// Get expenses for a date range
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    return await _isar.expenses
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Get expenses for today
  Future<List<Expense>> getToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return await getByDateRange(start, end);
  }

  /// Get expenses for this week
  Future<List<Expense>> getThisWeek() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    return await getByDateRange(weekStart, now);
  }

  /// Get expenses for this month
  Future<List<Expense>> getThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return await getByDateRange(start, now);
  }

  /// Get expenses by category
  Future<List<Expense>> getByCategory(ExpenseCategory category) async {
    return await _isar.expenses
        .filter()
        .categoryEqualTo(category)
        .sortByDateDesc()
        .findAll();
  }

  /// Save expense (create or update)
  Future<int> save(Expense expense) async {
    final isNew = expense.id == Isar.autoIncrement;

    if (isNew) {
      expense.createdAt = DateTime.now();
    }
    expense.syncStatus = SyncStatus.pending;

    return await _isar.writeTxn(() async {
      final savedId = await _isar.expenses.put(expense);

      // Queue for sync
      await _queueForSync(
        isNew ? SyncOperation.create : SyncOperation.update,
        savedId,
      );

      return savedId;
    });
  }

  /// Delete expense
  Future<bool> delete(int id) async {
    return await _isar.writeTxn(() async {
      // Queue for sync before deleting
      await _queueForSync(SyncOperation.delete, id);
      return await _isar.expenses.delete(id);
    });
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'expenses'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }

  /// Get total expenses for a date range
  Future<double> getTotalForDateRange(DateTime start, DateTime end) async {
    final expenses = await getByDateRange(start, end);
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Get total expenses for today
  Future<double> getTodayTotal() async {
    final expenses = await getToday();
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Get total expenses for this month
  Future<double> getMonthTotal() async {
    final expenses = await getThisMonth();
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Get expenses grouped by category for a date range
  Future<Map<ExpenseCategory, double>> getCategoryTotals(DateTime start, DateTime end) async {
    final expenses = await getByDateRange(start, end);
    final Map<ExpenseCategory, double> totals = {};
    
    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    
    return totals;
  }

  /// Get expense count
  Future<int> getCount() async {
    return await _isar.expenses.count();
  }
}
