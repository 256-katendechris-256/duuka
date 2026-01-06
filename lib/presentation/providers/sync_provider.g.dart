// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncHash() => r'42e35f560c2fe37d1c30f6c9eb96888ae32e15b8';

/// See also [Sync].
@ProviderFor(Sync)
final syncProvider = AutoDisposeNotifierProvider<Sync, SyncState>.internal(
  Sync.new,
  name: r'syncProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Sync = AutoDisposeNotifier<SyncState>;
String _$networkStatusHash() => r'5f425f3bf0a829679c926d78f5a920db9676c94a';

/// See also [NetworkStatus].
@ProviderFor(NetworkStatus)
final networkStatusProvider =
    AutoDisposeNotifierProvider<NetworkStatus, bool>.internal(
  NetworkStatus.new,
  name: r'networkStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NetworkStatus = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
