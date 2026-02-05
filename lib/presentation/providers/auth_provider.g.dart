// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'e3b22fd7863ea1be0b322870da43112c60f80087';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$isOnboardingCompleteHash() =>
    r'b2b337471c45b87084d1d882a8dfbda9ba737b61';

/// See also [isOnboardingComplete].
@ProviderFor(isOnboardingComplete)
final isOnboardingCompleteProvider = AutoDisposeProvider<bool>.internal(
  isOnboardingComplete,
  name: r'isOnboardingCompleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOnboardingCompleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsOnboardingCompleteRef = AutoDisposeProviderRef<bool>;
String _$isFullyAuthenticatedHash() =>
    r'63f98230e3f5b85d856b6b99e920e200456ca78f';

/// See also [isFullyAuthenticated].
@ProviderFor(isFullyAuthenticated)
final isFullyAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isFullyAuthenticated,
  name: r'isFullyAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isFullyAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsFullyAuthenticatedRef = AutoDisposeProviderRef<bool>;
String _$authHash() => r'bc09527c737851a240939a51e8d19141f5b7bcca';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider = NotifierProvider<Auth, AuthState>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = Notifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
