// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$saleRepositoryHash() => r'd22c67a62b230395e1ec9508d57abcd4e0806e32';

/// See also [saleRepository].
@ProviderFor(saleRepository)
final saleRepositoryProvider = AutoDisposeProvider<SaleRepository>.internal(
  saleRepository,
  name: r'saleRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$saleRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SaleRepositoryRef = AutoDisposeProviderRef<SaleRepository>;
String _$todaySalesHash() => r'eaa3ce6d8c6490a4c4c159e270ed03c0ae2d02f4';

/// See also [todaySales].
@ProviderFor(todaySales)
final todaySalesProvider = AutoDisposeFutureProvider<List<Sale>>.internal(
  todaySales,
  name: r'todaySalesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todaySalesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodaySalesRef = AutoDisposeFutureProviderRef<List<Sale>>;
String _$recentSalesHash() => r'b8928f13d145817a2e649088c2eb79fe3c10920f';

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

/// See also [recentSales].
@ProviderFor(recentSales)
const recentSalesProvider = RecentSalesFamily();

/// See also [recentSales].
class RecentSalesFamily extends Family<AsyncValue<List<Sale>>> {
  /// See also [recentSales].
  const RecentSalesFamily();

  /// See also [recentSales].
  RecentSalesProvider call({
    int limit = 10,
  }) {
    return RecentSalesProvider(
      limit: limit,
    );
  }

  @override
  RecentSalesProvider getProviderOverride(
    covariant RecentSalesProvider provider,
  ) {
    return call(
      limit: provider.limit,
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
  String? get name => r'recentSalesProvider';
}

/// See also [recentSales].
class RecentSalesProvider extends AutoDisposeFutureProvider<List<Sale>> {
  /// See also [recentSales].
  RecentSalesProvider({
    int limit = 10,
  }) : this._internal(
          (ref) => recentSales(
            ref as RecentSalesRef,
            limit: limit,
          ),
          from: recentSalesProvider,
          name: r'recentSalesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recentSalesHash,
          dependencies: RecentSalesFamily._dependencies,
          allTransitiveDependencies:
              RecentSalesFamily._allTransitiveDependencies,
          limit: limit,
        );

  RecentSalesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<Sale>> Function(RecentSalesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentSalesProvider._internal(
        (ref) => create(ref as RecentSalesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Sale>> createElement() {
    return _RecentSalesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentSalesProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecentSalesRef on AutoDisposeFutureProviderRef<List<Sale>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _RecentSalesProviderElement
    extends AutoDisposeFutureProviderElement<List<Sale>> with RecentSalesRef {
  _RecentSalesProviderElement(super.provider);

  @override
  int get limit => (origin as RecentSalesProvider).limit;
}

String _$saleByIdHash() => r'129bef53e47daca13001b2072a4553260803eabd';

/// See also [saleById].
@ProviderFor(saleById)
const saleByIdProvider = SaleByIdFamily();

/// See also [saleById].
class SaleByIdFamily extends Family<AsyncValue<Sale?>> {
  /// See also [saleById].
  const SaleByIdFamily();

  /// See also [saleById].
  SaleByIdProvider call(
    int id,
  ) {
    return SaleByIdProvider(
      id,
    );
  }

  @override
  SaleByIdProvider getProviderOverride(
    covariant SaleByIdProvider provider,
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
  String? get name => r'saleByIdProvider';
}

/// See also [saleById].
class SaleByIdProvider extends AutoDisposeFutureProvider<Sale?> {
  /// See also [saleById].
  SaleByIdProvider(
    int id,
  ) : this._internal(
          (ref) => saleById(
            ref as SaleByIdRef,
            id,
          ),
          from: saleByIdProvider,
          name: r'saleByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$saleByIdHash,
          dependencies: SaleByIdFamily._dependencies,
          allTransitiveDependencies: SaleByIdFamily._allTransitiveDependencies,
          id: id,
        );

  SaleByIdProvider._internal(
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
    FutureOr<Sale?> Function(SaleByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SaleByIdProvider._internal(
        (ref) => create(ref as SaleByIdRef),
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
  AutoDisposeFutureProviderElement<Sale?> createElement() {
    return _SaleByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaleByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SaleByIdRef on AutoDisposeFutureProviderRef<Sale?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _SaleByIdProviderElement extends AutoDisposeFutureProviderElement<Sale?>
    with SaleByIdRef {
  _SaleByIdProviderElement(super.provider);

  @override
  int get id => (origin as SaleByIdProvider).id;
}

String _$todayStatsHash() => r'ec0c98908a5436f29bf70012da9462ea81189ad6';

/// See also [todayStats].
@ProviderFor(todayStats)
final todayStatsProvider = AutoDisposeFutureProvider<TodayStats>.internal(
  todayStats,
  name: r'todayStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodayStatsRef = AutoDisposeFutureProviderRef<TodayStats>;
String _$weeklySalesHash() => r'd9fa1a1120886144b5357d9603af7a4e2f3a9e44';

/// See also [weeklySales].
@ProviderFor(weeklySales)
final weeklySalesProvider =
    AutoDisposeFutureProvider<List<DailySales>>.internal(
  weeklySales,
  name: r'weeklySalesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$weeklySalesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WeeklySalesRef = AutoDisposeFutureProviderRef<List<DailySales>>;
String _$salesHash() => r'3b0146b9c873095d4790b67e84939b9888a4a519';

/// See also [Sales].
@ProviderFor(Sales)
final salesProvider =
    AutoDisposeAsyncNotifierProvider<Sales, List<Sale>>.internal(
  Sales.new,
  name: r'salesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$salesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Sales = AutoDisposeAsyncNotifier<List<Sale>>;
String _$cartHash() => r'b0602e11456b988e09d7c20a6a736d82e78a6415';

/// See also [Cart].
@ProviderFor(Cart)
final cartProvider = AutoDisposeNotifierProvider<Cart, CartState>.internal(
  Cart.new,
  name: r'cartProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Cart = AutoDisposeNotifier<CartState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
