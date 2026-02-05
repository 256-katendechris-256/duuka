// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pinValidationHash() => r'd25a3f51261398ad2b9496b7d4120eeb6947204e';

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

/// See also [pinValidation].
@ProviderFor(pinValidation)
const pinValidationProvider = PinValidationFamily();

/// See also [pinValidation].
class PinValidationFamily extends Family<String?> {
  /// See also [pinValidation].
  const PinValidationFamily();

  /// See also [pinValidation].
  PinValidationProvider call(
    String pin,
  ) {
    return PinValidationProvider(
      pin,
    );
  }

  @override
  PinValidationProvider getProviderOverride(
    covariant PinValidationProvider provider,
  ) {
    return call(
      provider.pin,
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
  String? get name => r'pinValidationProvider';
}

/// See also [pinValidation].
class PinValidationProvider extends AutoDisposeProvider<String?> {
  /// See also [pinValidation].
  PinValidationProvider(
    String pin,
  ) : this._internal(
          (ref) => pinValidation(
            ref as PinValidationRef,
            pin,
          ),
          from: pinValidationProvider,
          name: r'pinValidationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pinValidationHash,
          dependencies: PinValidationFamily._dependencies,
          allTransitiveDependencies:
              PinValidationFamily._allTransitiveDependencies,
          pin: pin,
        );

  PinValidationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pin,
  }) : super.internal();

  final String pin;

  @override
  Override overrideWith(
    String? Function(PinValidationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PinValidationProvider._internal(
        (ref) => create(ref as PinValidationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pin: pin,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String?> createElement() {
    return _PinValidationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PinValidationProvider && other.pin == pin;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pin.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PinValidationRef on AutoDisposeProviderRef<String?> {
  /// The parameter `pin` of this provider.
  String get pin;
}

class _PinValidationProviderElement extends AutoDisposeProviderElement<String?>
    with PinValidationRef {
  _PinValidationProviderElement(super.provider);

  @override
  String get pin => (origin as PinValidationProvider).pin;
}

String _$hasPinSetupHash() => r'4d7522db7a1e177e3983edb413b55f9dc6357857';

/// See also [hasPinSetup].
@ProviderFor(hasPinSetup)
final hasPinSetupProvider = AutoDisposeFutureProvider<bool>.internal(
  hasPinSetup,
  name: r'hasPinSetupProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$hasPinSetupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasPinSetupRef = AutoDisposeFutureProviderRef<bool>;
String _$isBiometricAvailableHash() =>
    r'17ff3584b84251cc4a82ecc11fe2fa380a91463a';

/// See also [isBiometricAvailable].
@ProviderFor(isBiometricAvailable)
final isBiometricAvailableProvider = AutoDisposeFutureProvider<bool>.internal(
  isBiometricAvailable,
  name: r'isBiometricAvailableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isBiometricAvailableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsBiometricAvailableRef = AutoDisposeFutureProviderRef<bool>;
String _$pinHash() => r'40a830b36d544eb4332a22f4a30d0e7b1b16e8b9';

/// See also [Pin].
@ProviderFor(Pin)
final pinProvider = NotifierProvider<Pin, PinState>.internal(
  Pin.new,
  name: r'pinProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pinHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Pin = Notifier<PinState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
