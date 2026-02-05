// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceRepositoryHash() => r'd15a5fff4d9b384295a3cda16ae2d556e46d8f2c';

/// See also [deviceRepository].
@ProviderFor(deviceRepository)
final deviceRepositoryProvider = AutoDisposeProvider<DeviceRepository>.internal(
  deviceRepository,
  name: r'deviceRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DeviceRepositoryRef = AutoDisposeProviderRef<DeviceRepository>;
String _$currentDeviceIdHash() => r'5557d56289cef91b70a8872c7b8b7ed9cec4316a';

/// See also [currentDeviceId].
@ProviderFor(currentDeviceId)
final currentDeviceIdProvider = AutoDisposeFutureProvider<String>.internal(
  currentDeviceId,
  name: r'currentDeviceIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDeviceIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentDeviceIdRef = AutoDisposeFutureProviderRef<String>;
String _$currentDeviceInfoHash() => r'b95a97152742c439325c00b2ad3cd16b8b4ad6c7';

/// See also [currentDeviceInfo].
@ProviderFor(currentDeviceInfo)
final currentDeviceInfoProvider =
    AutoDisposeFutureProvider<DeviceRegistrationInfo>.internal(
  currentDeviceInfo,
  name: r'currentDeviceInfoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDeviceInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentDeviceInfoRef
    = AutoDisposeFutureProviderRef<DeviceRegistrationInfo>;
String _$deviceNotifierHash() => r'cb460db9bb3677c286873af8e1e3cc42e202168a';

/// See also [DeviceNotifier].
@ProviderFor(DeviceNotifier)
final deviceNotifierProvider =
    NotifierProvider<DeviceNotifier, DeviceState>.internal(
  DeviceNotifier.new,
  name: r'deviceNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DeviceNotifier = Notifier<DeviceState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
