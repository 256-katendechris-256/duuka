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

  /// Get today's total sales (all sales regardless of payment method)
  Future<double> getTodayTotal() async {
    try {
      final sales = await getToday();
      return sales.fold<double>(0.0, (double sum, sale) => sum + sale.total);
    } catch (e) {
      throw Exception('Failed to get today\'s total: $e');
    }
  }

  /// Get today's cash at hand (actual money in the register)
  /// - Cash/Mobile Money sales: full amount
  /// - Credit sales: only if fully paid (cleared)
  Future<double> getTodayCashAtHand() async {
    try {
      final sales = await getToday();
      return sales.fold<double>(0.0, (double sum, sale) {
        if (sale.paymentMethod == PaymentMethod.credit) {
          // Only count credit sales that are fully paid
          if (sale.paymentStatus == PaymentStatus.paid) {
            return sum + sale.total;
          }
          // Don't count partial or unpaid credit sales
          return sum;
        } else {
          // For cash/mobile money, count the full amount
          return sum + sale.total;
        }
      });
    } catch (e) {
      throw Exception('Failed to get today\'s cash at hand: $e');
    }
  }

  /// Get today's credit sales total (outstanding/unpaid amount)
  Future<double> getTodayCreditTotal() async {
    try {
      final sales = await getToday();
      return sales.fold<double>(0.0, (double sum, sale) {
        if (sale.paymentMethod == PaymentMethod.credit &&
            sale.paymentStatus != PaymentStatus.paid) {
          // Return the full amount for unpaid/partial credit sales
          return sum + sale.total;
        }
        return sum;
      });
    } catch (e) {
      throw Exception('Failed to get today\'s credit total: $e');
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
      print('💾 SaleRepository.save() - Starting transaction');
      print('   Items count: ${sale.items.length}');
      
      return await _isar.writeTxn(() async {
        // Set timestamps and sync status
        sale.createdAt = DateTime.now();
        sale.syncStatus = SyncStatus.pending;

        // Save sale
        final id = await _isar.sales.put(sale);
        print('   ✅ Sale saved with ID: $id');

        // Update product quantities for ALL items
        print('   📦 Updating stock for ${sale.items.length} products...');
        for (var i = 0; i < sale.items.length; i++) {
          final item = sale.items[i];
          print('   [$i] Product ID: ${item.productId}, Name: ${item.productName}, Qty sold: ${item.quantity}');

          final product = await _isar.products.get(item.productId);
          if (product != null) {
            final oldQty = product.stockQuantity;
            // Validate stock before deducting
            if (product.stockQuantity < item.quantity) {
              print('       ⚠️ Insufficient stock! Available: ${product.stockQuantity}, Requested: ${item.quantity}');
              // Deduct only what's available to prevent negative stock
              product.stockQuantity = 0;
            } else {
              product.stockQuantity -= item.quantity;
            }
            product.updatedAt = DateTime.now();
            product.syncStatus = SyncStatus.pending;
            await _isar.products.put(product);

            // Queue product for sync (stock updated)
            final productSyncQueue = SyncQueue()
              ..operation = SyncOperation.update
              ..collectionName = 'products'
              ..localId = item.productId
              ..status = SyncQueueStatus.pending
              ..createdAt = DateTime.now();
            await _isar.syncQueues.put(productSyncQueue);

            print('       Stock updated: $oldQty → ${product.stockQuantity}');
          } else {
            print('       ⚠️ Product not found in database!');
          }
        }

        // Queue sale for sync
        await _queueForSync(SyncOperation.create, id);
        print('   ✅ All ${sale.items.length} products updated');

        return id;
      });
    } catch (e) {
      print('   💥 Error saving sale: $e');
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
