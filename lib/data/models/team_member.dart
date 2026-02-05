import 'package:isar/isar.dart';

import 'product.dart' show SyncStatus;
import 'app_user.dart' show UserRole;
import 'invitation.dart' show Gender;

part 'team_member.g.dart';

/// Team member - Staff assignments with roles and permissions
@collection
class TeamMember {
  Id id = Isar.autoIncrement;

  /// Link to local AppUser
  @Index()
  late int userId;

  /// User's phone (denormalized for display)
  late String userPhone;

  /// User's name (denormalized for display)
  String? userName;

  /// User's gender
  @Enumerated(EnumType.name)
  Gender? gender;

  /// User's age
  int? age;

  /// Link to local Business
  @Index()
  late int businessId;

  /// Role in the business
  @Enumerated(EnumType.name)
  late UserRole role;

  // Granular permissions
  bool canMakeSales = true;
  bool canViewProducts = true;
  bool canEditProducts = false;
  bool canManageCredit = false;
  bool canViewReports = false;
  bool canAddTeam = false;
  bool canManageDevices = false;
  bool canDelete = false;

  /// Whether this team member is active
  bool isActive = true;

  /// When the member joined
  late DateTime joinedAt;

  /// When this record was created
  late DateTime createdAt;

  /// Remote ID in Supabase
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  TeamMember();

  /// Create a team member with default permissions based on role
  TeamMember.create({
    required this.userId,
    required this.userPhone,
    this.userName,
    this.gender,
    this.age,
    required this.businessId,
    required this.role,
  }) : createdAt = DateTime.now(),
       joinedAt = DateTime.now() {
    _setDefaultPermissions();
  }

  /// Set default permissions based on role
  void _setDefaultPermissions() {
    switch (role) {
      case UserRole.owner:
        canMakeSales = true;
        canViewProducts = true;
        canEditProducts = true;
        canManageCredit = true;
        canViewReports = true;
        canAddTeam = true;
        canManageDevices = true;
        canDelete = true;
        break;
      case UserRole.manager:
        canMakeSales = true;
        canViewProducts = true;
        canEditProducts = true;
        canManageCredit = true;
        canViewReports = true;
        canAddTeam = false;
        canManageDevices = false;
        canDelete = false;
        break;
      case UserRole.cashier:
        canMakeSales = true;
        canViewProducts = true;
        canEditProducts = false;
        canManageCredit = false;
        canViewReports = false;
        canAddTeam = false;
        canManageDevices = false;
        canDelete = false;
        break;
      case UserRole.viewer:
        canMakeSales = false;
        canViewProducts = true;
        canEditProducts = false;
        canManageCredit = false;
        canViewReports = false;
        canAddTeam = false;
        canManageDevices = false;
        canDelete = false;
        break;
    }
  }

  /// Copy permissions from an invitation
  void copyPermissionsFromInvitation(dynamic invitation) {
    canMakeSales = invitation.canMakeSales;
    canViewProducts = invitation.canViewProducts;
    canEditProducts = invitation.canEditProducts;
    canManageCredit = invitation.canManageCredit;
    canViewReports = invitation.canViewReports;
    canAddTeam = invitation.canAddTeam;
  }

  @override
  String toString() =>
      'TeamMember(id: $id, userId: $userId, role: $role, isActive: $isActive)';
}
