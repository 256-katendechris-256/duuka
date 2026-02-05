import 'package:isar/isar.dart';

import 'product.dart' show SyncStatus;
import 'app_user.dart' show UserRole;

part 'invitation.g.dart';

/// Status of an invitation
enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired;

  String get label {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
      case InvitationStatus.expired:
        return 'Expired';
    }
  }
}

/// Gender enum for team members
enum Gender {
  male,
  female,
  other;

  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

/// Invitation - Team member invitations with 6-digit codes
@collection
class Invitation {
  Id id = Isar.autoIncrement;

  /// Link to local Business
  @Index()
  late int businessId;

  /// User who created the invitation
  late int invitedByUserId;

  /// Team member details (set by owner when creating invitation)
  late String memberName;

  @Enumerated(EnumType.name)
  Gender? gender;

  int? age;

  /// Phone number of invited person
  @Index()
  late String phone;

  /// 6-digit invitation code
  @Index(unique: true)
  late String code;

  /// Role to assign when accepted
  @Enumerated(EnumType.name)
  late UserRole role;

  // Permissions to grant when accepted
  bool canMakeSales = true;
  bool canViewProducts = true;
  bool canEditProducts = false;
  bool canManageCredit = false;
  bool canViewReports = false;
  bool canAddTeam = false;

  /// Current status of the invitation
  @Enumerated(EnumType.name)
  late InvitationStatus status;

  /// When this invitation expires (default: 7 days from creation)
  late DateTime expiresAt;

  /// When this invitation was accepted
  DateTime? acceptedAt;

  /// When this record was created
  late DateTime createdAt;

  /// Remote ID in Supabase
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  Invitation();

  /// Create an invitation with default permissions based on role
  Invitation.create({
    required this.businessId,
    required this.invitedByUserId,
    required this.memberName,
    required this.phone,
    required this.code,
    required this.role,
    this.gender,
    this.age,
    int expiryDays = 7,
  }) : status = InvitationStatus.pending,
       createdAt = DateTime.now(),
       expiresAt = DateTime.now().add(Duration(days: expiryDays)) {
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
        break;
      case UserRole.manager:
        canMakeSales = true;
        canViewProducts = true;
        canEditProducts = true;
        canManageCredit = true;
        canViewReports = true;
        canAddTeam = false;
        break;
      case UserRole.cashier:
        canMakeSales = true;
        canViewProducts = true;
        canEditProducts = false;
        canManageCredit = false;
        canViewReports = false;
        canAddTeam = false;
        break;
      case UserRole.viewer:
        canMakeSales = false;
        canViewProducts = true;
        canEditProducts = false;
        canManageCredit = false;
        canViewReports = false;
        canAddTeam = false;
        break;
    }
  }

  /// Check if invitation is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invitation is valid (pending and not expired)
  bool get isValid => status == InvitationStatus.pending && !isExpired;

  /// Days until expiry (negative if expired)
  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;

  /// Accept the invitation
  void accept() {
    status = InvitationStatus.accepted;
    acceptedAt = DateTime.now();
  }

  /// Reject the invitation
  void reject() {
    status = InvitationStatus.rejected;
  }

  /// Mark as expired
  void markExpired() {
    status = InvitationStatus.expired;
  }

  @override
  String toString() =>
      'Invitation(id: $id, phone: $phone, code: $code, role: $role, status: $status)';
}
