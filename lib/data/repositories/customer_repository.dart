import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class CustomerRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get all customers
  Future<List<Customer>> getAll() async {
    return await _isar.customers.where().sortByNameDesc().findAll();
  }

  /// Get customer by ID
  Future<Customer?> getById(int id) async {
    return await _isar.customers.get(id);
  }

  /// Get customer by phone number
  Future<Customer?> getByPhone(String phone) async {
    return await _isar.customers.filter().phoneEqualTo(phone).findFirst();
  }

  /// Search customers by name or phone
  Future<List<Customer>> search(String query) async {
    if (query.isEmpty) return getAll();

    final lowerQuery = query.toLowerCase();
    return await _isar.customers
        .filter()
        .nameContains(lowerQuery, caseSensitive: false)
        .or()
        .phoneContains(query)
        .sortByName()
        .findAll();
  }

  /// Save customer (create or update)
  Future<int> save(Customer customer) async {
    final isNew = customer.id == Isar.autoIncrement;

    if (isNew) {
      customer.createdAt = DateTime.now();
    }
    customer.syncStatus = SyncStatus.pending;

    return await _isar.writeTxn(() async {
      final savedId = await _isar.customers.put(customer);

      // Queue for sync
      await _queueForSync(
        isNew ? SyncOperation.create : SyncOperation.update,
        savedId,
      );

      return savedId;
    });
  }

  /// Delete customer (soft delete)
  Future<bool> delete(int id) async {
    return await _isar.writeTxn(() async {
      final customer = await _isar.customers.get(id);
      if (customer != null) {
        // Queue for sync before deleting
        await _queueForSync(SyncOperation.delete, id);
      }
      return await _isar.customers.delete(id);
    });
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

  /// Update customer stats after a purchase
  Future<void> updatePurchaseStats(int customerId, double amount) async {
    final customer = await getById(customerId);
    if (customer != null) {
      customer.totalPurchases++;
      customer.totalSpent += amount;
      customer.lastPurchaseAt = DateTime.now();
      await save(customer);
    }
  }

  /// Get customers with outstanding credit
  Future<List<Customer>> getCustomersWithCredit() async {
    // Get all credit transactions that are not cleared
    final transactions = await _isar.creditTransactions
        .filter()
        .not()
        .statusEqualTo(CreditStatus.cleared)
        .findAll();
    
    // Get unique customer IDs
    final customerIds = transactions.map((t) => t.customerId).toSet();
    
    // Fetch customers
    final customers = <Customer>[];
    for (final id in customerIds) {
      final customer = await getById(id);
      if (customer != null) {
        customers.add(customer);
      }
    }
    
    return customers;
  }

  /// Get total count
  Future<int> getCount() async {
    return await _isar.customers.count();
  }
}
