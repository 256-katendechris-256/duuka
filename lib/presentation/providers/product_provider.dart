import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/product_repository.dart';

part 'product_provider.g.dart';

// Repository Provider
@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository();
}

// Products Provider
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    return await _loadProducts();
  }

  Future<List<Product>> _loadProducts() async {
    try {
      return await ref.read(productRepositoryProvider).getAll();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProducts());
  }

  Future<bool> addProduct(Product product) async {
    try {
      await ref.read(productRepositoryProvider).save(product);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await ref.read(productRepositoryProvider).save(product);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await ref.read(productRepositoryProvider).delete(id);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> adjustStock(int id, int change, String reason) async {
    try {
      await ref.read(productRepositoryProvider).updateQuantity(id, change);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Single Product Provider
@riverpod
Future<Product?> product(ProductRef ref, int id) async {
  try {
    return await ref.read(productRepositoryProvider).getById(id);
  } catch (e) {
    return null;
  }
}

// Low Stock Products Provider
@riverpod
Future<List<Product>> lowStockProducts(LowStockProductsRef ref) async {
  try {
    return await ref.read(productRepositoryProvider).getLowStock();
  } catch (e) {
    return [];
  }
}

// Product Search Provider
@riverpod
class ProductSearch extends _$ProductSearch {
  @override
  Future<List<Product>> build(String query) async {
    if (query.isEmpty) {
      return await ref.read(productRepositoryProvider).getAll();
    }
    return await ref.read(productRepositoryProvider).search(query);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Products by Category Provider
@riverpod
Future<List<Product>> productsByCategory(
  ProductsByCategoryRef ref,
  String category,
) async {
  try {
    if (category.isEmpty || category == 'All') {
      return await ref.read(productRepositoryProvider).getAll();
    }
    return await ref.read(productRepositoryProvider).getByCategory(category);
  } catch (e) {
    return [];
  }
}

// Categories Provider
@riverpod
Future<List<String>> productCategories(ProductCategoriesRef ref) async {
  try {
    final categories = await ref.read(productRepositoryProvider).getCategories();
    return ['All', ...categories];
  } catch (e) {
    return ['All'];
  }
}

// Inventory Stats Class
class InventoryStats {
  final int totalItems;
  final int lowStockCount;
  final double totalValue;

  const InventoryStats({
    required this.totalItems,
    required this.lowStockCount,
    required this.totalValue,
  });

  InventoryStats copyWith({
    int? totalItems,
    int? lowStockCount,
    double? totalValue,
  }) {
    return InventoryStats(
      totalItems: totalItems ?? this.totalItems,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      totalValue: totalValue ?? this.totalValue,
    );
  }
}

// Inventory Stats Provider
@riverpod
Future<InventoryStats> inventoryStats(InventoryStatsRef ref) async {
  try {
    final repository = ref.read(productRepositoryProvider);

    final totalItems = await repository.getTotalCount();
    final lowStockProducts = await repository.getLowStock();
    final totalValue = await repository.getTotalValue();

    return InventoryStats(
      totalItems: totalItems,
      lowStockCount: lowStockProducts.length,
      totalValue: totalValue,
    );
  } catch (e) {
    return const InventoryStats(
      totalItems: 0,
      lowStockCount: 0,
      totalValue: 0,
    );
  }
}

// Selected Category Provider (for filtering)
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String build() => 'All';

  void select(String category) {
    state = category;
  }

  void clear() {
    state = 'All';
  }
}
