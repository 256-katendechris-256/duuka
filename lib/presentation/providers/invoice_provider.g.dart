// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$invoiceRepositoryHash() => r'411dfa3a20ac12caa6cd4dc8b4a2a4e1629ed9c5';

/// See also [invoiceRepository].
@ProviderFor(invoiceRepository)
final invoiceRepositoryProvider =
    AutoDisposeProvider<InvoiceRepository>.internal(
  invoiceRepository,
  name: r'invoiceRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$invoiceRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InvoiceRepositoryRef = AutoDisposeProviderRef<InvoiceRepository>;
String _$invoiceToSaleServiceHash() =>
    r'9d326b88923b4d242a43664b799effc2f2980a14';

/// See also [invoiceToSaleService].
@ProviderFor(invoiceToSaleService)
final invoiceToSaleServiceProvider =
    AutoDisposeProvider<InvoiceToSaleService>.internal(
  invoiceToSaleService,
  name: r'invoiceToSaleServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$invoiceToSaleServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InvoiceToSaleServiceRef = AutoDisposeProviderRef<InvoiceToSaleService>;
String _$draftInvoicesHash() => r'469e3ce6cdf72f1cbc9a15523422b26289fa2030';

/// See also [draftInvoices].
@ProviderFor(draftInvoices)
final draftInvoicesProvider = AutoDisposeFutureProvider<List<Invoice>>.internal(
  draftInvoices,
  name: r'draftInvoicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$draftInvoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DraftInvoicesRef = AutoDisposeFutureProviderRef<List<Invoice>>;
String _$pendingInvoicesHash() => r'76158ebdfa80d883fa5a27be73197e71a64daef6';

/// See also [pendingInvoices].
@ProviderFor(pendingInvoices)
final pendingInvoicesProvider =
    AutoDisposeFutureProvider<List<Invoice>>.internal(
  pendingInvoices,
  name: r'pendingInvoicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingInvoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingInvoicesRef = AutoDisposeFutureProviderRef<List<Invoice>>;
String _$paidInvoicesHash() => r'4d79c9cc7baaa355955fea2c4891890a351bd8e7';

/// See also [paidInvoices].
@ProviderFor(paidInvoices)
final paidInvoicesProvider = AutoDisposeFutureProvider<List<Invoice>>.internal(
  paidInvoices,
  name: r'paidInvoicesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$paidInvoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PaidInvoicesRef = AutoDisposeFutureProviderRef<List<Invoice>>;
String _$overdueInvoicesHash() => r'e0c205574d079a1efa852c87784ec1f99b39f01c';

/// See also [overdueInvoices].
@ProviderFor(overdueInvoices)
final overdueInvoicesProvider =
    AutoDisposeFutureProvider<List<Invoice>>.internal(
  overdueInvoices,
  name: r'overdueInvoicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$overdueInvoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OverdueInvoicesRef = AutoDisposeFutureProviderRef<List<Invoice>>;
String _$invoicesByCustomerHash() =>
    r'4753af4f4946d0a9359c0156719d9586d10d47f2';

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

/// See also [invoicesByCustomer].
@ProviderFor(invoicesByCustomer)
const invoicesByCustomerProvider = InvoicesByCustomerFamily();

/// See also [invoicesByCustomer].
class InvoicesByCustomerFamily extends Family<AsyncValue<List<Invoice>>> {
  /// See also [invoicesByCustomer].
  const InvoicesByCustomerFamily();

  /// See also [invoicesByCustomer].
  InvoicesByCustomerProvider call({
    required int customerId,
  }) {
    return InvoicesByCustomerProvider(
      customerId: customerId,
    );
  }

  @override
  InvoicesByCustomerProvider getProviderOverride(
    covariant InvoicesByCustomerProvider provider,
  ) {
    return call(
      customerId: provider.customerId,
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
  String? get name => r'invoicesByCustomerProvider';
}

/// See also [invoicesByCustomer].
class InvoicesByCustomerProvider
    extends AutoDisposeFutureProvider<List<Invoice>> {
  /// See also [invoicesByCustomer].
  InvoicesByCustomerProvider({
    required int customerId,
  }) : this._internal(
          (ref) => invoicesByCustomer(
            ref as InvoicesByCustomerRef,
            customerId: customerId,
          ),
          from: invoicesByCustomerProvider,
          name: r'invoicesByCustomerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$invoicesByCustomerHash,
          dependencies: InvoicesByCustomerFamily._dependencies,
          allTransitiveDependencies:
              InvoicesByCustomerFamily._allTransitiveDependencies,
          customerId: customerId,
        );

  InvoicesByCustomerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.customerId,
  }) : super.internal();

  final int customerId;

  @override
  Override overrideWith(
    FutureOr<List<Invoice>> Function(InvoicesByCustomerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvoicesByCustomerProvider._internal(
        (ref) => create(ref as InvoicesByCustomerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        customerId: customerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Invoice>> createElement() {
    return _InvoicesByCustomerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoicesByCustomerProvider &&
        other.customerId == customerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, customerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InvoicesByCustomerRef on AutoDisposeFutureProviderRef<List<Invoice>> {
  /// The parameter `customerId` of this provider.
  int get customerId;
}

class _InvoicesByCustomerProviderElement
    extends AutoDisposeFutureProviderElement<List<Invoice>>
    with InvoicesByCustomerRef {
  _InvoicesByCustomerProviderElement(super.provider);

  @override
  int get customerId => (origin as InvoicesByCustomerProvider).customerId;
}

String _$todayInvoicesHash() => r'ef7a1f37b2404ee18e5cc49776729b9566ebbc96';

/// See also [todayInvoices].
@ProviderFor(todayInvoices)
final todayInvoicesProvider = AutoDisposeFutureProvider<List<Invoice>>.internal(
  todayInvoices,
  name: r'todayInvoicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayInvoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodayInvoicesRef = AutoDisposeFutureProviderRef<List<Invoice>>;
String _$invoiceStatsHash() => r'04925c4af83adc45fe85fa4b49c2779ab7a9ed13';

/// See also [invoiceStats].
@ProviderFor(invoiceStats)
final invoiceStatsProvider = AutoDisposeFutureProvider<InvoiceStats>.internal(
  invoiceStats,
  name: r'invoiceStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$invoiceStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InvoiceStatsRef = AutoDisposeFutureProviderRef<InvoiceStats>;
String _$invoiceByIdHash() => r'3afdabe8c180697b8ce6b7c2eddd06a260d896a8';

/// See also [invoiceById].
@ProviderFor(invoiceById)
const invoiceByIdProvider = InvoiceByIdFamily();

/// See also [invoiceById].
class InvoiceByIdFamily extends Family<AsyncValue<Invoice?>> {
  /// See also [invoiceById].
  const InvoiceByIdFamily();

  /// See also [invoiceById].
  InvoiceByIdProvider call({
    required int id,
  }) {
    return InvoiceByIdProvider(
      id: id,
    );
  }

  @override
  InvoiceByIdProvider getProviderOverride(
    covariant InvoiceByIdProvider provider,
  ) {
    return call(
      id: provider.id,
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
  String? get name => r'invoiceByIdProvider';
}

/// See also [invoiceById].
class InvoiceByIdProvider extends AutoDisposeFutureProvider<Invoice?> {
  /// See also [invoiceById].
  InvoiceByIdProvider({
    required int id,
  }) : this._internal(
          (ref) => invoiceById(
            ref as InvoiceByIdRef,
            id: id,
          ),
          from: invoiceByIdProvider,
          name: r'invoiceByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$invoiceByIdHash,
          dependencies: InvoiceByIdFamily._dependencies,
          allTransitiveDependencies:
              InvoiceByIdFamily._allTransitiveDependencies,
          id: id,
        );

  InvoiceByIdProvider._internal(
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
    FutureOr<Invoice?> Function(InvoiceByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvoiceByIdProvider._internal(
        (ref) => create(ref as InvoiceByIdRef),
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
  AutoDisposeFutureProviderElement<Invoice?> createElement() {
    return _InvoiceByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InvoiceByIdRef on AutoDisposeFutureProviderRef<Invoice?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _InvoiceByIdProviderElement
    extends AutoDisposeFutureProviderElement<Invoice?> with InvoiceByIdRef {
  _InvoiceByIdProviderElement(super.provider);

  @override
  int get id => (origin as InvoiceByIdProvider).id;
}

String _$nextInvoiceNumberHash() => r'3cf445cfba04809b77a2c120968b966743c59746';

/// See also [nextInvoiceNumber].
@ProviderFor(nextInvoiceNumber)
final nextInvoiceNumberProvider = AutoDisposeFutureProvider<String>.internal(
  nextInvoiceNumber,
  name: r'nextInvoiceNumberProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nextInvoiceNumberHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NextInvoiceNumberRef = AutoDisposeFutureProviderRef<String>;
String _$searchInvoicesHash() => r'669ab104bde254e04bb2bf3be9815e33e8cde7d4';

/// See also [searchInvoices].
@ProviderFor(searchInvoices)
const searchInvoicesProvider = SearchInvoicesFamily();

/// See also [searchInvoices].
class SearchInvoicesFamily extends Family<AsyncValue<List<Invoice>>> {
  /// See also [searchInvoices].
  const SearchInvoicesFamily();

  /// See also [searchInvoices].
  SearchInvoicesProvider call({
    required String query,
  }) {
    return SearchInvoicesProvider(
      query: query,
    );
  }

  @override
  SearchInvoicesProvider getProviderOverride(
    covariant SearchInvoicesProvider provider,
  ) {
    return call(
      query: provider.query,
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
  String? get name => r'searchInvoicesProvider';
}

/// See also [searchInvoices].
class SearchInvoicesProvider extends AutoDisposeFutureProvider<List<Invoice>> {
  /// See also [searchInvoices].
  SearchInvoicesProvider({
    required String query,
  }) : this._internal(
          (ref) => searchInvoices(
            ref as SearchInvoicesRef,
            query: query,
          ),
          from: searchInvoicesProvider,
          name: r'searchInvoicesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchInvoicesHash,
          dependencies: SearchInvoicesFamily._dependencies,
          allTransitiveDependencies:
              SearchInvoicesFamily._allTransitiveDependencies,
          query: query,
        );

  SearchInvoicesProvider._internal(
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
  Override overrideWith(
    FutureOr<List<Invoice>> Function(SearchInvoicesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchInvoicesProvider._internal(
        (ref) => create(ref as SearchInvoicesRef),
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
  AutoDisposeFutureProviderElement<List<Invoice>> createElement() {
    return _SearchInvoicesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchInvoicesProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SearchInvoicesRef on AutoDisposeFutureProviderRef<List<Invoice>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchInvoicesProviderElement
    extends AutoDisposeFutureProviderElement<List<Invoice>>
    with SearchInvoicesRef {
  _SearchInvoicesProviderElement(super.provider);

  @override
  String get query => (origin as SearchInvoicesProvider).query;
}

String _$invoicesHash() => r'884622ec81f2e13bab512d41cb0b1f2fa6e3ca7a';

/// See also [Invoices].
@ProviderFor(Invoices)
final invoicesProvider =
    AutoDisposeAsyncNotifierProvider<Invoices, List<Invoice>>.internal(
  Invoices.new,
  name: r'invoicesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$invoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Invoices = AutoDisposeAsyncNotifier<List<Invoice>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
