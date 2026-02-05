// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teamRepositoryHash() => r'8b32cec5d4e341b79beed37410e68b65f92dd199';

/// See also [teamRepository].
@ProviderFor(teamRepository)
final teamRepositoryProvider = AutoDisposeProvider<TeamRepository>.internal(
  teamRepository,
  name: r'teamRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teamRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeamRepositoryRef = AutoDisposeProviderRef<TeamRepository>;
String _$currentTeamMemberHash() => r'ac4b782c5892111b4b4b280b05e2f56425a0b587';

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

/// See also [currentTeamMember].
@ProviderFor(currentTeamMember)
const currentTeamMemberProvider = CurrentTeamMemberFamily();

/// See also [currentTeamMember].
class CurrentTeamMemberFamily extends Family<AsyncValue<TeamMember?>> {
  /// See also [currentTeamMember].
  const CurrentTeamMemberFamily();

  /// See also [currentTeamMember].
  CurrentTeamMemberProvider call(
    int userId,
    int businessId,
  ) {
    return CurrentTeamMemberProvider(
      userId,
      businessId,
    );
  }

  @override
  CurrentTeamMemberProvider getProviderOverride(
    covariant CurrentTeamMemberProvider provider,
  ) {
    return call(
      provider.userId,
      provider.businessId,
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
  String? get name => r'currentTeamMemberProvider';
}

/// See also [currentTeamMember].
class CurrentTeamMemberProvider extends AutoDisposeFutureProvider<TeamMember?> {
  /// See also [currentTeamMember].
  CurrentTeamMemberProvider(
    int userId,
    int businessId,
  ) : this._internal(
          (ref) => currentTeamMember(
            ref as CurrentTeamMemberRef,
            userId,
            businessId,
          ),
          from: currentTeamMemberProvider,
          name: r'currentTeamMemberProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentTeamMemberHash,
          dependencies: CurrentTeamMemberFamily._dependencies,
          allTransitiveDependencies:
              CurrentTeamMemberFamily._allTransitiveDependencies,
          userId: userId,
          businessId: businessId,
        );

  CurrentTeamMemberProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.businessId,
  }) : super.internal();

  final int userId;
  final int businessId;

  @override
  Override overrideWith(
    FutureOr<TeamMember?> Function(CurrentTeamMemberRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentTeamMemberProvider._internal(
        (ref) => create(ref as CurrentTeamMemberRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        businessId: businessId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TeamMember?> createElement() {
    return _CurrentTeamMemberProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentTeamMemberProvider &&
        other.userId == userId &&
        other.businessId == businessId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, businessId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CurrentTeamMemberRef on AutoDisposeFutureProviderRef<TeamMember?> {
  /// The parameter `userId` of this provider.
  int get userId;

  /// The parameter `businessId` of this provider.
  int get businessId;
}

class _CurrentTeamMemberProviderElement
    extends AutoDisposeFutureProviderElement<TeamMember?>
    with CurrentTeamMemberRef {
  _CurrentTeamMemberProviderElement(super.provider);

  @override
  int get userId => (origin as CurrentTeamMemberProvider).userId;
  @override
  int get businessId => (origin as CurrentTeamMemberProvider).businessId;
}

String _$checkPermissionHash() => r'f7b1c2783ea95456dc3a66f7b93dfc7cabef8014';

/// See also [checkPermission].
@ProviderFor(checkPermission)
const checkPermissionProvider = CheckPermissionFamily();

/// See also [checkPermission].
class CheckPermissionFamily extends Family<AsyncValue<bool>> {
  /// See also [checkPermission].
  const CheckPermissionFamily();

  /// See also [checkPermission].
  CheckPermissionProvider call(
    int userId,
    int businessId,
    String permission,
  ) {
    return CheckPermissionProvider(
      userId,
      businessId,
      permission,
    );
  }

  @override
  CheckPermissionProvider getProviderOverride(
    covariant CheckPermissionProvider provider,
  ) {
    return call(
      provider.userId,
      provider.businessId,
      provider.permission,
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
  String? get name => r'checkPermissionProvider';
}

/// See also [checkPermission].
class CheckPermissionProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [checkPermission].
  CheckPermissionProvider(
    int userId,
    int businessId,
    String permission,
  ) : this._internal(
          (ref) => checkPermission(
            ref as CheckPermissionRef,
            userId,
            businessId,
            permission,
          ),
          from: checkPermissionProvider,
          name: r'checkPermissionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$checkPermissionHash,
          dependencies: CheckPermissionFamily._dependencies,
          allTransitiveDependencies:
              CheckPermissionFamily._allTransitiveDependencies,
          userId: userId,
          businessId: businessId,
          permission: permission,
        );

  CheckPermissionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.businessId,
    required this.permission,
  }) : super.internal();

  final int userId;
  final int businessId;
  final String permission;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CheckPermissionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CheckPermissionProvider._internal(
        (ref) => create(ref as CheckPermissionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        businessId: businessId,
        permission: permission,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CheckPermissionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckPermissionProvider &&
        other.userId == userId &&
        other.businessId == businessId &&
        other.permission == permission;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, businessId.hashCode);
    hash = _SystemHash.combine(hash, permission.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CheckPermissionRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `userId` of this provider.
  int get userId;

  /// The parameter `businessId` of this provider.
  int get businessId;

  /// The parameter `permission` of this provider.
  String get permission;
}

class _CheckPermissionProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CheckPermissionRef {
  _CheckPermissionProviderElement(super.provider);

  @override
  int get userId => (origin as CheckPermissionProvider).userId;
  @override
  int get businessId => (origin as CheckPermissionProvider).businessId;
  @override
  String get permission => (origin as CheckPermissionProvider).permission;
}

String _$teamMemberCountHash() => r'9233f57e9a811334fcc5a8e90f5db417160065c3';

/// See also [teamMemberCount].
@ProviderFor(teamMemberCount)
const teamMemberCountProvider = TeamMemberCountFamily();

/// See also [teamMemberCount].
class TeamMemberCountFamily extends Family<AsyncValue<int>> {
  /// See also [teamMemberCount].
  const TeamMemberCountFamily();

  /// See also [teamMemberCount].
  TeamMemberCountProvider call(
    int businessId,
  ) {
    return TeamMemberCountProvider(
      businessId,
    );
  }

  @override
  TeamMemberCountProvider getProviderOverride(
    covariant TeamMemberCountProvider provider,
  ) {
    return call(
      provider.businessId,
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
  String? get name => r'teamMemberCountProvider';
}

/// See also [teamMemberCount].
class TeamMemberCountProvider extends AutoDisposeFutureProvider<int> {
  /// See also [teamMemberCount].
  TeamMemberCountProvider(
    int businessId,
  ) : this._internal(
          (ref) => teamMemberCount(
            ref as TeamMemberCountRef,
            businessId,
          ),
          from: teamMemberCountProvider,
          name: r'teamMemberCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teamMemberCountHash,
          dependencies: TeamMemberCountFamily._dependencies,
          allTransitiveDependencies:
              TeamMemberCountFamily._allTransitiveDependencies,
          businessId: businessId,
        );

  TeamMemberCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.businessId,
  }) : super.internal();

  final int businessId;

  @override
  Override overrideWith(
    FutureOr<int> Function(TeamMemberCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeamMemberCountProvider._internal(
        (ref) => create(ref as TeamMemberCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        businessId: businessId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _TeamMemberCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamMemberCountProvider && other.businessId == businessId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, businessId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeamMemberCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `businessId` of this provider.
  int get businessId;
}

class _TeamMemberCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with TeamMemberCountRef {
  _TeamMemberCountProviderElement(super.provider);

  @override
  int get businessId => (origin as TeamMemberCountProvider).businessId;
}

String _$teamHash() => r'b6d5b9cc72efe72f5c159742a202ce65538249b3';

/// See also [Team].
@ProviderFor(Team)
final teamProvider = AutoDisposeNotifierProvider<Team, TeamState>.internal(
  Team.new,
  name: r'teamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$teamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Team = AutoDisposeNotifier<TeamState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
