import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class ProductRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get all active products sorted by name
  Future<List<Product>> getAll() async {
    try {
      return await _isar.products
          .filter()
          .isActiveEqualTo(true)
          .sortByName()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get product by ID
  Future<Product?> getById(int id) async {
    try {
      return await _isar.products.get(id);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Get product by barcode
  Future<Product?> getByBarcode(String barcode) async {
    try {
      return await _isar.products
          .filter()
          .barcodeEqualTo(barcode)
          .and()
          .isActiveEqualTo(true)
          .findFirst();
    } catch (e) {
      throw Exception('Failed to fetch product by barcode: $e');
    }
  }

  /// Get low stock products
  Future<List<Product>> getLowStock() async {
    try {
      final products = await _isar.products
          .filter()
          .isActiveEqualTo(true)
          .findAll();

      return products.where((p) => p.isLowStock).toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock products: $e');
    }
  }

  /// Get products by category
  Future<List<Product>> getByCategory(String category) async {
    try {
      return await _isar.products
          .filter()
          .categoryEqualTo(category)
          .and()
          .isActiveEqualTo(true)
          .sortByName()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  /// Search products by name
  Future<List<Product>> search(String query) async {
    try {
      if (query.isEmpty) {
        return await getAll();
      }

      return await _isar.products
          .filter()
          .isActiveEqualTo(true)
          .and()
          .nameContains(query, caseSensitive: false)
          .sortByName()
          .findAll();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Save product (insert or update)
  Future<int> save(Product product) async {
    try {
      final now = DateTime.now();

      if (product.id == Isar.autoIncrement) {
        // New product
        product.createdAt = now;
      }

      product.updatedAt = now;
      product.syncStatus = SyncStatus.pending;

      return await _isar.writeTxn(() async {
        final id = await _isar.products.put(product);

        // Queue for sync
        await _queueForSync(
          product.id == Isar.autoIncrement ? SyncOperation.create : SyncOperation.update,
          id,
        );

        return id;
      });
    } catch (e) {
      throw Exception('Failed to save product: $e');
    }
  }

  /// Soft delete product
  Future<void> delete(int id) async {
    try {
      await _isar.writeTxn(() async {
        final product = await _isar.products.get(id);
        if (product != null) {
          product.isActive = false;
          product.updatedAt = DateTime.now();
          product.syncStatus = SyncStatus.pending;
          await _isar.products.put(product);

          // Queue for sync
          await _queueForSync(SyncOperation.delete, id);
        }
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Update product quantity (add or subtract)
  Future<void> updateQuantity(int id, int change) async {
    try {
      await _isar.writeTxn(() async {
        final product = await _isar.products.get(id);
        if (product != null) {
          product.quantity += change;
          product.updatedAt = DateTime.now();
          product.syncStatus = SyncStatus.pending;
          await _isar.products.put(product);

          // Queue for sync
          await _queueForSync(SyncOperation.update, id);
        }
      });
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  /// Get total count of active products
  Future<int> getTotalCount() async {
    try {
      return await _isar.products
          .filter()
          .isActiveEqualTo(true)
          .count();
    } catch (e) {
      throw Exception('Failed to get product count: $e');
    }
  }

  /// Get total stock value
  Future<double> getTotalValue() async {
    try {
      final products = await _isar.products
          .filter()
          .isActiveEqualTo(true)
          .findAll();

      return products.fold<double>(0.0, (double sum, product) => sum + product.stockValue);
    } catch (e) {
      throw Exception('Failed to get total value: $e');
    }
  }

  /// Get distinct categories
  Future<List<String>> getCategories() async {
    try {
      final products = await _isar.products
          .filter()
          .isActiveEqualTo(true)
          .findAll();

      final categories = products
          .where((p) => p.category != null && p.category!.isNotEmpty)
          .map((p) => p.category!)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'products'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}
