import 'package:isar/isar.dart';

import '../models/product_return.dart';
import '../models/product.dart';
import '../models/sync_queue.dart';

class ReturnRepository {
  final Isar _isar;

  ReturnRepository(this._isar);

  /// Save a new return and optionally restock the product
  Future<int> save(ProductReturn productReturn, {bool restock = false}) async {
    productReturn.syncStatus = SyncStatus.pending;

    return await _isar.writeTxn(() async {
      // Save the return
      final id = await _isar.productReturns.put(productReturn);

      // Queue for sync
      await _queueForSync(SyncOperation.create, id);

      // Restock if condition allows
      if (restock && productReturn.condition.canRestock) {
        final product = await _isar.products.get(productReturn.productId);
        if (product != null) {
          product.stockQuantity += productReturn.quantity;
          product.syncStatus = SyncStatus.pending;
          await _isar.products.put(product);

          // Queue product update for sync
          final productSyncQueue = SyncQueue()
            ..operation = SyncOperation.update
            ..collectionName = 'products'
            ..localId = productReturn.productId
            ..status = SyncQueueStatus.pending
            ..createdAt = DateTime.now();
          await _isar.syncQueues.put(productSyncQueue);
        }
        productReturn.isRestocked = true;
        await _isar.productReturns.put(productReturn);
      }

      return id;
    });
  }

  /// Get return by ID
  Future<ProductReturn?> getById(int id) async {
    return await _isar.productReturns.get(id);
  }

  /// Get all returns
  Future<List<ProductReturn>> getAll() async {
    return await _isar.productReturns
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get returns for a specific sale
  Future<List<ProductReturn>> getBySale(int saleId) async {
    return await _isar.productReturns
        .filter()
        .saleIdEqualTo(saleId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get returns for a specific product
  Future<List<ProductReturn>> getByProduct(int productId) async {
    return await _isar.productReturns
        .filter()
        .productIdEqualTo(productId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get returns for today
  Future<List<ProductReturn>> getToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _isar.productReturns
        .filter()
        .createdAtBetween(startOfDay, endOfDay)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get total refund amount for today
  Future<double> getTodayRefundTotal() async {
    final returns = await getToday();
    double total = 0.0;
    for (final r in returns) {
      total += r.refundAmount;
    }
    return total;
  }

  /// Check if an item from a sale has already been returned
  Future<double> getReturnedQuantity(int saleId, int productId) async {
    final returns = await _isar.productReturns
        .filter()
        .saleIdEqualTo(saleId)
        .productIdEqualTo(productId)
        .findAll();
    
    double total = 0.0;
    for (final r in returns) {
      total += r.quantity;
    }
    return total;
  }

  /// Delete a return
  Future<bool> delete(int id) async {
    return await _isar.writeTxn(() async {
      await _queueForSync(SyncOperation.delete, id);
      return await _isar.productReturns.delete(id);
    });
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'product_returns'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}
