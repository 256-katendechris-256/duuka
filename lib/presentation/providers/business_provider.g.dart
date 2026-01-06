// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$businessRepositoryHash() =>
    r'79bc77dc7050139b67dfdef10d6e9de8c8d5f94c';

/// See also [businessRepository].
@ProviderFor(businessRepository)
final businessRepositoryProvider =
    AutoDisposeProvider<BusinessRepository>.internal(
  businessRepository,
  name: r'businessRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$businessRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BusinessRepositoryRef = AutoDisposeProviderRef<BusinessRepository>;
String _$businessNotifierHash() => r'0a4a28157a407c0945410afb4671bcf290f442c7';

/// See also [BusinessNotifier].
@ProviderFor(BusinessNotifier)
final businessNotifierProvider =
    AutoDisposeAsyncNotifierProvider<BusinessNotifier, Business?>.internal(
  BusinessNotifier.new,
  name: r'businessNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$businessNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BusinessNotifier = AutoDisposeAsyncNotifier<Business?>;
String _$businessTypeNotifierHash() =>
    r'3eb0b56aa37f712d77620393ea69744b63e72ad6';

/// See also [BusinessTypeNotifier].
@ProviderFor(BusinessTypeNotifier)
final businessTypeNotifierProvider =
    AutoDisposeNotifierProvider<BusinessTypeNotifier, BusinessType?>.internal(
  BusinessTypeNotifier.new,
  name: r'businessTypeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$businessTypeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BusinessTypeNotifier = AutoDisposeNotifier<BusinessType?>;
String _$businessSizeNotifierHash() =>
    r'266b3eeb94e6d2cdf987c86f699c80cd3fcccff1';

/// See also [BusinessSizeNotifier].
@ProviderFor(BusinessSizeNotifier)
final businessSizeNotifierProvider =
    AutoDisposeNotifierProvider<BusinessSizeNotifier, BusinessSize?>.internal(
  BusinessSizeNotifier.new,
  name: r'businessSizeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$businessSizeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BusinessSizeNotifier = AutoDisposeNotifier<BusinessSize?>;
String _$onboardingDataNotifierHash() =>
    r'4bfed56fdd069fe124845ce7dc3c39b1e42acd45';

/// See also [OnboardingDataNotifier].
@ProviderFor(OnboardingDataNotifier)
final onboardingDataNotifierProvider = AutoDisposeNotifierProvider<
    OnboardingDataNotifier, OnboardingData>.internal(
  OnboardingDataNotifier.new,
  name: r'onboardingDataNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingDataNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingDataNotifier = AutoDisposeNotifier<OnboardingData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
