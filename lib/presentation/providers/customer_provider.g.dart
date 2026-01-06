// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customerRepositoryHash() =>
    r'27437bcaa5af35d61a6ea8adef78edc8272bffa8';

/// See also [customerRepository].
@ProviderFor(customerRepository)
final customerRepositoryProvider =
    AutoDisposeProvider<CustomerRepository>.internal(
  customerRepository,
  name: r'customerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CustomerRepositoryRef = AutoDisposeProviderRef<CustomerRepository>;
String _$customerHash() => r'b74e9f26e59571800f72e709bdcd33c6df7456b4';

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

/// See also [customer].
@ProviderFor(customer)
const customerProvider = CustomerFamily();

/// See also [customer].
class CustomerFamily extends Family<AsyncValue<Customer?>> {
  /// See also [customer].
  const CustomerFamily();

  /// See also [customer].
  CustomerProvider call(
    int id,
  ) {
    return CustomerProvider(
      id,
    );
  }

  @override
  CustomerProvider getProviderOverride(
    covariant CustomerProvider provider,
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
  String? get name => r'customerProvider';
}

/// See also [customer].
class CustomerProvider extends AutoDisposeFutureProvider<Customer?> {
  /// See also [customer].
  CustomerProvider(
    int id,
  ) : this._internal(
          (ref) => customer(
            ref as CustomerRef,
            id,
          ),
          from: customerProvider,
          name: r'customerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$customerHash,
          dependencies: CustomerFamily._dependencies,
          allTransitiveDependencies: CustomerFamily._allTransitiveDependencies,
          id: id,
        );

  CustomerProvider._internal(
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
    FutureOr<Customer?> Function(CustomerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomerProvider._internal(
        (ref) => create(ref as CustomerRef),
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
  AutoDisposeFutureProviderElement<Customer?> createElement() {
    return _CustomerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CustomerRef on AutoDisposeFutureProviderRef<Customer?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _CustomerProviderElement
    extends AutoDisposeFutureProviderElement<Customer?> with CustomerRef {
  _CustomerProviderElement(super.provider);

  @override
  int get id => (origin as CustomerProvider).id;
}

String _$customersWithDebtHash() => r'6dd016b2871880115d606a41a05707e5021fd849';

/// See also [customersWithDebt].
@ProviderFor(customersWithDebt)
final customersWithDebtProvider =
    AutoDisposeFutureProvider<List<Customer>>.internal(
  customersWithDebt,
  name: r'customersWithDebtProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customersWithDebtHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CustomersWithDebtRef = AutoDisposeFutureProviderRef<List<Customer>>;
String _$debtStatsHash() => r'fbc5c947a42e83df9d6fd229d6075332a3863656';

/// See also [debtStats].
@ProviderFor(debtStats)
final debtStatsProvider = AutoDisposeFutureProvider<DebtStats>.internal(
  debtStats,
  name: r'debtStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$debtStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DebtStatsRef = AutoDisposeFutureProviderRef<DebtStats>;
String _$customersHash() => r'ea6b8644970d498cc74f635a6f5f142412fa956d';

/// See also [Customers].
@ProviderFor(Customers)
final customersProvider =
    AutoDisposeAsyncNotifierProvider<Customers, List<Customer>>.internal(
  Customers.new,
  name: r'customersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$customersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Customers = AutoDisposeAsyncNotifier<List<Customer>>;
String _$customerSearchHash() => r'c1a3a83fdbce247f713f16f1f33edd3232917016';

abstract class _$CustomerSearch
    extends BuildlessAutoDisposeAsyncNotifier<List<Customer>> {
  late final String query;

  FutureOr<List<Customer>> build(
    String query,
  );
}

/// See also [CustomerSearch].
@ProviderFor(CustomerSearch)
const customerSearchProvider = CustomerSearchFamily();

/// See also [CustomerSearch].
class CustomerSearchFamily extends Family<AsyncValue<List<Customer>>> {
  /// See also [CustomerSearch].
  const CustomerSearchFamily();

  /// See also [CustomerSearch].
  CustomerSearchProvider call(
    String query,
  ) {
    return CustomerSearchProvider(
      query,
    );
  }

  @override
  CustomerSearchProvider getProviderOverride(
    covariant CustomerSearchProvider provider,
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
  String? get name => r'customerSearchProvider';
}

/// See also [CustomerSearch].
class CustomerSearchProvider extends AutoDisposeAsyncNotifierProviderImpl<
    CustomerSearch, List<Customer>> {
  /// See also [CustomerSearch].
  CustomerSearchProvider(
    String query,
  ) : this._internal(
          () => CustomerSearch()..query = query,
          from: customerSearchProvider,
          name: r'customerSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$customerSearchHash,
          dependencies: CustomerSearchFamily._dependencies,
          allTransitiveDependencies:
              CustomerSearchFamily._allTransitiveDependencies,
          query: query,
        );

  CustomerSearchProvider._internal(
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
  FutureOr<List<Customer>> runNotifierBuild(
    covariant CustomerSearch notifier,
  ) {
    return notifier.build(
      query,
    );
  }

  @override
  Override overrideWith(CustomerSearch Function() create) {
    return ProviderOverride(
      origin: this,
      override: CustomerSearchProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<CustomerSearch, List<Customer>>
      createElement() {
    return _CustomerSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CustomerSearchRef on AutoDisposeAsyncNotifierProviderRef<List<Customer>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _CustomerSearchProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CustomerSearch,
        List<Customer>> with CustomerSearchRef {
  _CustomerSearchProviderElement(super.provider);

  @override
  String get query => (origin as CustomerSearchProvider).query;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
