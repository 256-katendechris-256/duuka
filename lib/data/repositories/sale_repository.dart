import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class SaleRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get all sales sorted by date (newest first)
  Future<List<Sale>> getAll() async {
    try {
      return await _isar.sales
          .where()
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch sales: $e');
    }
  }

  /// Get sale by ID
  Future<Sale?> getById(int id) async {
    try {
      return await _isar.sales.get(id);
    } catch (e) {
      throw Exception('Failed to fetch sale: $e');
    }
  }

  /// Get today's sales
  Future<List<Sale>> getToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return await _isar.sales
          .filter()
          .createdAtBetween(startOfDay, endOfDay)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch today\'s sales: $e');
    }
  }

  /// Get sales by date range
  Future<List<Sale>> getByDateRange(DateTime start, DateTime end) async {
    try {
      return await _isar.sales
          .filter()
          .createdAtBetween(start, end)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch sales by date range: $e');
    }
  }

  /// Get sales by customer
  Future<List<Sale>> getByCustomer(int customerId) async {
    try {
      return await _isar.sales
          .filter()
          .customerIdEqualTo(customerId)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch sales by customer: $e');
    }
  }

  /// Get today's total sales
  Future<double> getTodayTotal() async {
    try {
      final sales = await getToday();
      return sales.fold<double>(0.0, (double sum, sale) => sum + sale.total);
    } catch (e) {
      throw Exception('Failed to get today\'s total: $e');
    }
  }

  /// Get today's sales count
  Future<int> getTodayCount() async {
    try {
      final sales = await getToday();
      return sales.length;
    } catch (e) {
      throw Exception('Failed to get today\'s count: $e');
    }
  }

  /// Get today's profit
  Future<double> getTodayProfit() async {
    try {
      final sales = await getToday();
      return sales.fold<double>(0.0, (double sum, sale) => sum + sale.totalProfit);
    } catch (e) {
      throw Exception('Failed to get today\'s profit: $e');
    }
  }

  /// Get week sales (daily totals for the last 7 days)
  Future<List<DailySales>> getWeekSales() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));
      final startOfWeek = DateTime(weekAgo.year, weekAgo.month, weekAgo.day);

      final sales = await getByDateRange(startOfWeek, now);

      // Group by day
      final Map<String, double> dailyTotals = {};
      for (var i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final key = '${date.year}-${date.month}-${date.day}';
        dailyTotals[key] = 0.0;
      }

      for (var sale in sales) {
        final date = sale.createdAt;
        final key = '${date.year}-${date.month}-${date.day}';
        dailyTotals[key] = (dailyTotals[key] ?? 0.0) + sale.total;
      }

      return dailyTotals.entries
          .map((e) {
            final parts = e.key.split('-');
            return DailySales(
              date: DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              ),
              total: e.value,
            );
          })
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      throw Exception('Failed to get week sales: $e');
    }
  }

  /// Get recent sales (limited)
  Future<List<Sale>> getRecentSales(int limit) async {
    try {
      return await _isar.sales
          .where()
          .sortByCreatedAtDesc()
          .limit(limit)
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch recent sales: $e');
    }
  }

  /// Save sale and update product quantities
  Future<int> save(Sale sale) async {
    try {
      return await _isar.writeTxn(() async {
        // Set timestamps and sync status
        sale.createdAt = DateTime.now();
        sale.syncStatus = SyncStatus.pending;

        // Save sale
        final id = await _isar.sales.put(sale);

        // Update product quantities
        for (var item in sale.items) {
          final product = await _isar.products.get(item.productId);
          if (product != null) {
            product.quantity -= item.quantity;
            product.updatedAt = DateTime.now();
            product.syncStatus = SyncStatus.pending;
            await _isar.products.put(product);
          }
        }

        // Queue for sync
        await _queueForSync(SyncOperation.create, id);

        return id;
      });
    } catch (e) {
      throw Exception('Failed to save sale: $e');
    }
  }

  /// Generate receipt number
  Future<String> generateReceiptNumber() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Count today's sales
      final count = await _isar.sales
          .filter()
          .createdAtBetween(today, tomorrow)
          .count();

      final sequence = count + 1;
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      return 'DK-$dateStr-${sequence.toString().padLeft(4, '0')}';
    } catch (e) {
      throw Exception('Failed to generate receipt number: $e');
    }
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'sales'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}

/// Helper class for daily sales
class DailySales {
  final DateTime date;
  final double total;

  DailySales({required this.date, required this.total});
}
