// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productRepositoryHash() => r'1143e6a957468f07814b030b8e53d8ea1ddb037b';

/// See also [productRepository].
@ProviderFor(productRepository)
final productRepositoryProvider =
    AutoDisposeProvider<ProductRepository>.internal(
  productRepository,
  name: r'productRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProductRepositoryRef = AutoDisposeProviderRef<ProductRepository>;
String _$productHash() => r'85366623f5c48d2b48b7a470f2dc5c34a2cbb669';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [product].
@ProviderFor(product)
const productProvider = ProductFamily();

/// See also [product].
class ProductFamily extends Family<AsyncValue<Product?>> {
  /// See also [product].
  const ProductFamily();

  /// See also [product].
  ProductProvider call(
    int id,
  ) {
    return ProductProvider(
      id,
    );
  }

  @override
  ProductProvider getProviderOverride(
    covariant ProductProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productProvider';
}

/// See also [product].
class ProductProvider extends AutoDisposeFutureProvider<Product?> {
  /// See also [product].
  ProductProvider(
    int id,
  ) : this._internal(
          (ref) => product(
            ref as ProductRef,
            id,
          ),
          from: productProvider,
          name: r'productProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$productHash,
          dependencies: ProductFamily._dependencies,
          allTransitiveDependencies: ProductFamily._allTransitiveDependencies,
          id: id,
        );

  ProductProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<Product?> Function(ProductRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductProvider._internal(
        (ref) => create(ref as ProductRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Product?> createElement() {
    return _ProductProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProductRef on AutoDisposeFutureProviderRef<Product?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _ProductProviderElement extends AutoDisposeFutureProviderElement<Product?>
    with ProductRef {
  _ProductProviderElement(super.provider);

  @override
  int get id => (origin as ProductProvider).id;
}

String _$lowStockProductsHash() => r'54b7adb38dcee73fd0da7fea0e8fe5f647481ce0';

/// See also [lowStockProducts].
@ProviderFor(lowStockProducts)
final lowStockProductsProvider =
    AutoDisposeFutureProvider<List<Product>>.internal(
  lowStockProducts,
  name: r'lowStockProductsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lowStockProductsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LowStockProductsRef = AutoDisposeFutureProviderRef<List<Product>>;
String _$productsByCategoryHash() =>
    r'12912d1b363ba7ad9eae0dbf08618ec52d49fad8';

/// See also [productsByCategory].
@ProviderFor(productsByCategory)
const productsByCategoryProvider = ProductsByCategoryFamily();

/// See also [productsByCategory].
class ProductsByCategoryFamily extends Family<AsyncValue<List<Product>>> {
  /// See also [productsByCategory].
  const ProductsByCategoryFamily();

  /// See also [productsByCategory].
  ProductsByCategoryProvider call(
    String category,
  ) {
    return ProductsByCategoryProvider(
      category,
    );
  }

  @override
  ProductsByCategoryProvider getProviderOverride(
    covariant ProductsByCategoryProvider provider,
  ) {
    return call(
      provider.category,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productsByCategoryProvider';
}

/// See also [productsByCategory].
class ProductsByCategoryProvider
    extends AutoDisposeFutureProvider<List<Product>> {
  /// See also [productsByCategory].
  ProductsByCategoryProvider(
    String category,
  ) : this._internal(
          (ref) => productsByCategory(
            ref as ProductsByCategoryRef,
            category,
          ),
          from: productsByCategoryProvider,
          name: r'productsByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$productsByCategoryHash,
          dependencies: ProductsByCategoryFamily._dependencies,
          allTransitiveDependencies:
              ProductsByCategoryFamily._allTransitiveDependencies,
          category: category,
        );

  ProductsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String category;

  @override
  Override overrideWith(
    FutureOr<List<Product>> Function(ProductsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductsByCategoryProvider._internal(
        (ref) => create(ref as ProductsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Product>> createElement() {
    return _ProductsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductsByCategoryProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProductsByCategoryRef on AutoDisposeFutureProviderRef<List<Product>> {
  /// The parameter `category` of this provider.
  String get category;
}

class _ProductsByCategoryProviderElement
    extends AutoDisposeFutureProviderElement<List<Product>>
    with ProductsByCategoryRef {
  _ProductsByCategoryProviderElement(super.provider);

  @override
  String get category => (origin as ProductsByCategoryProvider).category;
}

String _$productCategoriesHash() => r'e4b1b2beb40b86c9293beff33f62d57666209805';

/// See also [productCategories].
@ProviderFor(productCategories)
final productCategoriesProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  productCategories,
  name: r'productCategoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productCategoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProductCategoriesRef = AutoDisposeFutureProviderRef<List<String>>;
String _$inventoryStatsHash() => r'6183dde53451b624046d01c567502be898c8eab6';

/// See also [inventoryStats].
@ProviderFor(inventoryStats)
final inventoryStatsProvider =
    AutoDisposeFutureProvider<InventoryStats>.internal(
  inventoryStats,
  name: r'inventoryStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inventoryStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InventoryStatsRef = AutoDisposeFutureProviderRef<InventoryStats>;
String _$productsHash() => r'3ae2c171d6f09b42932b571e6d4f9bf3cbcab3d6';

/// See also [Products].
@ProviderFor(Products)
final productsProvider =
    AutoDisposeAsyncNotifierProvider<Products, List<Product>>.internal(
  Products.new,
  name: r'productsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$productsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Products = AutoDisposeAsyncNotifier<List<Product>>;
String _$productSearchHash() => r'76d5ee5b44e1cc87aa44a5b30d0957e5d3bee074';

abstract class _$ProductSearch
    extends BuildlessAutoDisposeAsyncNotifier<List<Product>> {
  late final String query;

  FutureOr<List<Product>> build(
    String query,
  );
}

/// See also [ProductSearch].
@ProviderFor(ProductSearch)
const productSearchProvider = ProductSearchFamily();

/// See also [ProductSearch].
class ProductSearchFamily extends Family<AsyncValue<List<Product>>> {
  /// See also [ProductSearch].
  const ProductSearchFamily();

  /// See also [ProductSearch].
  ProductSearchProvider call(
    String query,
  ) {
    return ProductSearchProvider(
      query,
    );
  }

  @override
  ProductSearchProvider getProviderOverride(
    covariant ProductSearchProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productSearchProvider';
}

/// See also [ProductSearch].
class ProductSearchProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ProductSearch, List<Product>> {
  /// See also [ProductSearch].
  ProductSearchProvider(
    String query,
  ) : this._internal(
          () => ProductSearch()..query = query,
          from: productSearchProvider,
          name: r'productSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$productSearchHash,
          dependencies: ProductSearchFamily._dependencies,
          allTransitiveDependencies:
              ProductSearchFamily._allTransitiveDependencies,
          query: query,
        );

  ProductSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  FutureOr<List<Product>> runNotifierBuild(
    covariant ProductSearch notifier,
  ) {
    return notifier.build(
      query,
    );
  }

  @override
  Override overrideWith(ProductSearch Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProductSearchProvider._internal(
        () => create()..query = query,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ProductSearch, List<Product>>
      createElement() {
    return _ProductSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProductSearchRef on AutoDisposeAsyncNotifierProviderRef<List<Product>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _ProductSearchProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ProductSearch,
        List<Product>> with ProductSearchRef {
  _ProductSearchProviderElement(super.provider);

  @override
  String get query => (origin as ProductSearchProvider).query;
}

String _$selectedCategoryHash() => r'13f917ef45c06e690220383a28f6e59477175081';

/// See also [SelectedCategory].
@ProviderFor(SelectedCategory)
final selectedCategoryProvider =
    AutoDisposeNotifierProvider<SelectedCategory, String>.internal(
  SelectedCategory.new,
  name: r'selectedCategoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCategoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCategory = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
