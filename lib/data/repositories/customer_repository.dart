import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class CustomerRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get all customers sorted by name
  Future<List<Customer>> getAll() async {
    try {
      return await _isar.customers
          .where()
          .sortByName()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// Get customer by ID
  Future<Customer?> getById(int id) async {
    try {
      return await _isar.customers.get(id);
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  /// Get customer by phone
  Future<Customer?> getByPhone(String phone) async {
    try {
      return await _isar.customers
          .filter()
          .phoneEqualTo(phone)
          .findFirst();
    } catch (e) {
      throw Exception('Failed to fetch customer by phone: $e');
    }
  }

  /// Search customers by name or phone
  Future<List<Customer>> search(String query) async {
    try {
      if (query.isEmpty) {
        return await getAll();
      }

      return await _isar.customers
          .filter()
          .nameContains(query, caseSensitive: false)
          .or()
          .phoneContains(query)
          .sortByName()
          .findAll();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  /// Get customers with debt
  Future<List<Customer>> getWithDebt() async {
    try {
      final customers = await _isar.customers.where().findAll();
      return customers.where((c) => c.hasDebt).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance));
    } catch (e) {
      throw Exception('Failed to fetch customers with debt: $e');
    }
  }

  /// Get total debt across all customers
  Future<double> getTotalDebt() async {
    try {
      final customers = await _isar.customers.where().findAll();
      return customers.fold(0.0, (sum, customer) => sum + customer.balance);
    } catch (e) {
      throw Exception('Failed to get total debt: $e');
    }
  }

  /// Get count of customers over credit limit
  Future<int> getOverdueCount() async {
    try {
      final customers = await _isar.customers.where().findAll();
      return customers.where((c) => c.isOverLimit).length;
    } catch (e) {
      throw Exception('Failed to get overdue count: $e');
    }
  }

  /// Save customer (insert or update)
  Future<int> save(Customer customer) async {
    try {
      final now = DateTime.now();

      if (customer.id == Isar.autoIncrement) {
        // New customer
        customer.createdAt = now;
      }

      customer.updatedAt = now;
      customer.syncStatus = SyncStatus.pending;

      return await _isar.writeTxn(() async {
        final id = await _isar.customers.put(customer);

        // Queue for sync
        await _queueForSync(
          customer.id == Isar.autoIncrement ? SyncOperation.create : SyncOperation.update,
          id,
        );

        return id;
      });
    } catch (e) {
      throw Exception('Failed to save customer: $e');
    }
  }

  /// Delete customer
  Future<void> delete(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.customers.delete(id);

        // Queue for sync
        await _queueForSync(SyncOperation.delete, id);
      });
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  /// Add to customer balance (for credit sales)
  Future<void> addToBalance(int id, double amount) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.customers.get(id);
        if (customer != null) {
          customer.balance += amount;
          customer.updatedAt = DateTime.now();
          customer.syncStatus = SyncStatus.pending;
          await _isar.customers.put(customer);

          // Queue for sync
          await _queueForSync(SyncOperation.update, id);
        }
      });
    } catch (e) {
      throw Exception('Failed to add to balance: $e');
    }
  }

  /// Subtract from customer balance (for payments)
  Future<void> subtractFromBalance(int id, double amount) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.customers.get(id);
        if (customer != null) {
          customer.balance -= amount;
          if (customer.balance < 0) {
            customer.balance = 0; // Don't allow negative balance
          }
          customer.updatedAt = DateTime.now();
          customer.syncStatus = SyncStatus.pending;
          await _isar.customers.put(customer);

          // Queue for sync
          await _queueForSync(SyncOperation.update, id);
        }
      });
    } catch (e) {
      throw Exception('Failed to subtract from balance: $e');
    }
  }

  /// Record purchase (update stats)
  Future<void> recordPurchase(int id, double amount) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.customers.get(id);
        if (customer != null) {
          customer.totalPurchases += amount;
          customer.purchaseCount += 1;
          customer.lastPurchaseDate = DateTime.now();
          customer.updatedAt = DateTime.now();
          customer.syncStatus = SyncStatus.pending;
          await _isar.customers.put(customer);

          // Queue for sync
          await _queueForSync(SyncOperation.update, id);
        }
      });
    } catch (e) {
      throw Exception('Failed to record purchase: $e');
    }
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'customers'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}
