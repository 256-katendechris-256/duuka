import 'dart:math';
import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../datasources/remote/supabase_service.dart';
import '../models/models.dart';
import '../models/business.dart';

class TeamRepository {
  final Isar _isar = DatabaseService.instance;

  // ==========================================
  // INVITATION METHODS
  // ==========================================

  /// Generate a random 6-digit invitation code
  String generateInvitationCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Create a new invitation
  Future<Invitation> createInvitation({
    required int businessId,
    required int invitedByUserId,
    required String memberName,
    required String phone,
    required UserRole role,
    Gender? gender,
    int? age,
    Map<String, bool>? customPermissions,
    int expiryDays = 7,
  }) async {
    // Generate unique code
    String code;
    Invitation? existing;
    do {
      code = generateInvitationCode();
      existing = await getInvitationByCode(code);
    } while (existing != null);

    final invitation = Invitation.create(
      businessId: businessId,
      invitedByUserId: invitedByUserId,
      memberName: memberName,
      phone: phone,
      code: code,
      role: role,
      gender: gender,
      age: age,
      expiryDays: expiryDays,
    );

    // Apply custom permissions if provided
    if (customPermissions != null) {
      if (customPermissions.containsKey('canMakeSales')) {
        invitation.canMakeSales = customPermissions['canMakeSales']!;
      }
      if (customPermissions.containsKey('canViewProducts')) {
        invitation.canViewProducts = customPermissions['canViewProducts']!;
      }
      if (customPermissions.containsKey('canEditProducts')) {
        invitation.canEditProducts = customPermissions['canEditProducts']!;
      }
      if (customPermissions.containsKey('canManageCredit')) {
        invitation.canManageCredit = customPermissions['canManageCredit']!;
      }
      if (customPermissions.containsKey('canViewReports')) {
        invitation.canViewReports = customPermissions['canViewReports']!;
      }
      if (customPermissions.containsKey('canAddTeam')) {
        invitation.canAddTeam = customPermissions['canAddTeam']!;
      }
    }

    await _isar.writeTxn(() async {
      await _isar.invitations.put(invitation);
      await _queueInvitationForSync(SyncOperation.create, invitation.id);
    });

    return invitation;
  }

  /// Get invitation by code
  /// Checks local database first, then Supabase if not found
  Future<Invitation?> getInvitationByCode(String code) async {
    // First check local database
    final localInvitation = await _isar.invitations
        .filter()
        .codeEqualTo(code)
        .findFirst();

    if (localInvitation != null) {
      return localInvitation;
    }

    // If not found locally, check Supabase
    print('🔵 Invitation not found locally, checking Supabase...');
    try {
      final remoteData = await SupabaseService.selectSingle(
        'invitations',
        matchColumn: 'code',
        matchValue: code,
      );

      if (remoteData == null) {
        print('🔴 Invitation not found in Supabase');
        return null;
      }

      print('🟢 Found invitation in Supabase: ${remoteData['member_name']}');

      // Convert remote data to local Invitation and save locally
      final invitation = await _convertAndSaveRemoteInvitation(remoteData);
      return invitation;
    } catch (e) {
      print('🔴 Error fetching invitation from Supabase: $e');
      return null;
    }
  }

  /// Convert remote invitation data to local Invitation model
  Future<Invitation> _convertAndSaveRemoteInvitation(Map<String, dynamic> data) async {
    // Parse the invitation status
    InvitationStatus status = InvitationStatus.pending;
    final statusStr = data['status'] as String?;
    if (statusStr != null) {
      status = InvitationStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
        orElse: () => InvitationStatus.pending,
      );
    }

    // Parse the role
    UserRole role = UserRole.cashier;
    final roleStr = data['role'] as String?;
    if (roleStr != null) {
      role = UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == roleStr.toLowerCase(),
        orElse: () => UserRole.cashier,
      );
    }

    // Get business ID from remote - we need to find the local business
    final businessRemoteId = data['business_id'] as String?;
    int localBusinessId = 0;

    if (businessRemoteId != null) {
      // Try to find business by remote ID
      final business = await _isar.business
          .filter()
          .remoteIdEqualTo(businessRemoteId)
          .findFirst();

      if (business != null) {
        localBusinessId = business.id;
      } else {
        // Business not found locally - need to fetch and create it
        final businessData = await SupabaseService.selectSingle(
          'businesses',
          matchColumn: 'id',
          matchValue: businessRemoteId,
        );

        if (businessData != null) {
          final newBusiness = Business()
            ..remoteId = businessRemoteId
            ..name = businessData['name'] as String? ?? ''
            ..ownerName = ''
            ..phone = businessData['phone'] as String?
            ..email = businessData['email'] as String?
            ..address = businessData['address'] as String?
            ..createdAt = DateTime.tryParse(businessData['created_at'] as String? ?? '') ?? DateTime.now()
            ..updatedAt = DateTime.now();

          await _isar.writeTxn(() async {
            await _isar.business.put(newBusiness);
          });
          localBusinessId = newBusiness.id;
          print('🟢 Created local business: ${newBusiness.name} (ID: $localBusinessId)');
        }
      }
    }

    final invitation = Invitation()
      ..remoteId = data['id'] as String?
      ..businessId = localBusinessId
      ..invitedByUserId = 0 // Can't easily map this
      ..memberName = data['member_name'] as String? ?? ''
      ..phone = data['phone'] as String? ?? ''
      ..code = data['code'] as String? ?? ''
      ..role = role
      ..status = status
      ..canMakeSales = data['can_make_sales'] as bool? ?? true
      ..canViewProducts = data['can_view_products'] as bool? ?? true
      ..canEditProducts = data['can_edit_products'] as bool? ?? false
      ..canManageCredit = data['can_manage_credit'] as bool? ?? false
      ..canViewReports = data['can_view_reports'] as bool? ?? false
      ..canAddTeam = data['can_add_team'] as bool? ?? false
      ..syncStatus = SyncStatus.synced
      ..createdAt = DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()
      ..expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 7));

    // Save locally
    await _isar.writeTxn(() async {
      await _isar.invitations.put(invitation);
    });

    print('🟢 Saved invitation locally with ID: ${invitation.id}');
    return invitation;
  }

  /// Get invitation by phone number
  Future<Invitation?> getInvitationByPhone(String phone) async {
    return await _isar.invitations
        .filter()
        .phoneEqualTo(phone)
        .statusEqualTo(InvitationStatus.pending)
        .findFirst();
  }

  /// Get all invitations for a business
  Future<List<Invitation>> getInvitationsByBusiness(int businessId) async {
    return await _isar.invitations
        .filter()
        .businessIdEqualTo(businessId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get pending invitations for a business
  Future<List<Invitation>> getPendingInvitations(int businessId) async {
    return await _isar.invitations
        .filter()
        .businessIdEqualTo(businessId)
        .statusEqualTo(InvitationStatus.pending)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Validate an invitation code
  /// Returns the invitation if valid, null otherwise
  Future<Invitation?> validateInvitationCode(String phone, String code) async {
    final invitation = await getInvitationByCode(code);

    if (invitation == null) return null;
    if (invitation.phone != phone) return null;
    if (invitation.status != InvitationStatus.pending) return null;
    if (invitation.isExpired) return null;

    return invitation;
  }

  /// Accept an invitation
  Future<bool> acceptInvitation(Invitation invitation) async {
    if (!invitation.isValid) return false;

    invitation.accept();
    invitation.syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.invitations.put(invitation);
      await _queueInvitationForSync(SyncOperation.update, invitation.id);
    });

    return true;
  }

  /// Reject an invitation
  Future<void> rejectInvitation(Invitation invitation) async {
    invitation.reject();
    invitation.syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.invitations.put(invitation);
      await _queueInvitationForSync(SyncOperation.update, invitation.id);
    });
  }

  /// Mark expired invitations as expired
  Future<void> cleanupExpiredInvitations() async {
    final expired = await _isar.invitations
        .filter()
        .statusEqualTo(InvitationStatus.pending)
        .expiresAtLessThan(DateTime.now())
        .findAll();

    await _isar.writeTxn(() async {
      for (final invitation in expired) {
        invitation.markExpired();
        invitation.syncStatus = SyncStatus.pending;
        await _isar.invitations.put(invitation);
        await _queueInvitationForSync(SyncOperation.update, invitation.id);
      }
    });
  }

  /// Queue invitation for sync
  Future<void> _queueInvitationForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'invitations'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }

  // ==========================================
  // TEAM MEMBER METHODS
  // ==========================================

  /// Create a team member from an accepted invitation
  Future<TeamMember> createTeamMemberFromInvitation({
    required int userId,
    required String userPhone,
    required Invitation invitation,
  }) async {
    final teamMember = TeamMember.create(
      userId: userId,
      userPhone: userPhone,
      userName: invitation.memberName,  // Use name from invitation
      gender: invitation.gender,
      age: invitation.age,
      businessId: invitation.businessId,
      role: invitation.role,
    );

    // Copy permissions from invitation
    teamMember.canMakeSales = invitation.canMakeSales;
    teamMember.canViewProducts = invitation.canViewProducts;
    teamMember.canEditProducts = invitation.canEditProducts;
    teamMember.canManageCredit = invitation.canManageCredit;
    teamMember.canViewReports = invitation.canViewReports;
    teamMember.canAddTeam = invitation.canAddTeam;

    await _isar.writeTxn(() async {
      await _isar.teamMembers.put(teamMember);
      await _queueTeamMemberForSync(SyncOperation.create, teamMember.id);
    });

    return teamMember;
  }

  /// Create a team member directly (e.g., for owner)
  Future<TeamMember> createTeamMember({
    required int userId,
    required String userPhone,
    String? userName,
    required int businessId,
    required UserRole role,
  }) async {
    final teamMember = TeamMember.create(
      userId: userId,
      userPhone: userPhone,
      userName: userName,
      businessId: businessId,
      role: role,
    );

    await _isar.writeTxn(() async {
      await _isar.teamMembers.put(teamMember);
      await _queueTeamMemberForSync(SyncOperation.create, teamMember.id);
    });

    return teamMember;
  }

  /// Get team member by ID
  Future<TeamMember?> getTeamMemberById(int id) async {
    return await _isar.teamMembers.get(id);
  }

  /// Get team member by user ID and business ID
  Future<TeamMember?> getTeamMemberByUserAndBusiness(int userId, int businessId) async {
    return await _isar.teamMembers
        .filter()
        .userIdEqualTo(userId)
        .businessIdEqualTo(businessId)
        .isActiveEqualTo(true)
        .findFirst();
  }

  /// Get all team members for a business
  Future<List<TeamMember>> getTeamMembersByBusiness(int businessId) async {
    return await _isar.teamMembers
        .filter()
        .businessIdEqualTo(businessId)
        .isActiveEqualTo(true)
        .sortByJoinedAtDesc()
        .findAll();
  }

  /// Get all team members for a user (across all businesses)
  Future<List<TeamMember>> getTeamMembershipsByUser(int userId) async {
    return await _isar.teamMembers
        .filter()
        .userIdEqualTo(userId)
        .isActiveEqualTo(true)
        .findAll();
  }

  /// Update team member permissions
  Future<TeamMember> updateTeamMemberPermissions({
    required TeamMember teamMember,
    bool? canMakeSales,
    bool? canViewProducts,
    bool? canEditProducts,
    bool? canManageCredit,
    bool? canViewReports,
    bool? canAddTeam,
    bool? canManageDevices,
    bool? canDelete,
  }) async {
    if (canMakeSales != null) teamMember.canMakeSales = canMakeSales;
    if (canViewProducts != null) teamMember.canViewProducts = canViewProducts;
    if (canEditProducts != null) teamMember.canEditProducts = canEditProducts;
    if (canManageCredit != null) teamMember.canManageCredit = canManageCredit;
    if (canViewReports != null) teamMember.canViewReports = canViewReports;
    if (canAddTeam != null) teamMember.canAddTeam = canAddTeam;
    if (canManageDevices != null) teamMember.canManageDevices = canManageDevices;
    if (canDelete != null) teamMember.canDelete = canDelete;

    teamMember.syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.teamMembers.put(teamMember);
      await _queueTeamMemberForSync(SyncOperation.update, teamMember.id);
    });

    return teamMember;
  }

  /// Update team member role
  Future<TeamMember> updateTeamMemberRole({
    required TeamMember teamMember,
    required UserRole role,
    bool resetPermissions = true,
  }) async {
    teamMember.role = role;

    if (resetPermissions) {
      // Set default permissions for new role
      switch (role) {
        case UserRole.owner:
          teamMember.canMakeSales = true;
          teamMember.canViewProducts = true;
          teamMember.canEditProducts = true;
          teamMember.canManageCredit = true;
          teamMember.canViewReports = true;
          teamMember.canAddTeam = true;
          teamMember.canManageDevices = true;
          teamMember.canDelete = true;
          break;
        case UserRole.manager:
          teamMember.canMakeSales = true;
          teamMember.canViewProducts = true;
          teamMember.canEditProducts = true;
          teamMember.canManageCredit = true;
          teamMember.canViewReports = true;
          teamMember.canAddTeam = false;
          teamMember.canManageDevices = false;
          teamMember.canDelete = false;
          break;
        case UserRole.cashier:
          teamMember.canMakeSales = true;
          teamMember.canViewProducts = true;
          teamMember.canEditProducts = false;
          teamMember.canManageCredit = false;
          teamMember.canViewReports = false;
          teamMember.canAddTeam = false;
          teamMember.canManageDevices = false;
          teamMember.canDelete = false;
          break;
        case UserRole.viewer:
          teamMember.canMakeSales = false;
          teamMember.canViewProducts = true;
          teamMember.canEditProducts = false;
          teamMember.canManageCredit = false;
          teamMember.canViewReports = false;
          teamMember.canAddTeam = false;
          teamMember.canManageDevices = false;
          teamMember.canDelete = false;
          break;
      }
    }

    teamMember.syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.teamMembers.put(teamMember);
      await _queueTeamMemberForSync(SyncOperation.update, teamMember.id);
    });

    return teamMember;
  }

  /// Remove a team member (soft delete - set isActive to false)
  Future<void> removeTeamMember(TeamMember teamMember) async {
    teamMember.isActive = false;
    teamMember.syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.teamMembers.put(teamMember);
      await _queueTeamMemberForSync(SyncOperation.update, teamMember.id);
    });
  }

  /// Reactivate a team member
  Future<void> reactivateTeamMember(TeamMember teamMember) async {
    teamMember.isActive = true;
    teamMember.syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.teamMembers.put(teamMember);
      await _queueTeamMemberForSync(SyncOperation.update, teamMember.id);
    });
  }

  /// Get team member count for a business
  Future<int> getTeamMemberCount(int businessId) async {
    return await _isar.teamMembers
        .filter()
        .businessIdEqualTo(businessId)
        .isActiveEqualTo(true)
        .count();
  }

  /// Queue team member for sync
  Future<void> _queueTeamMemberForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'team_members'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }

  // ==========================================
  // PERMISSION CHECK HELPERS
  // ==========================================

  /// Check if a user can perform an action in a business
  Future<bool> checkPermission({
    required int userId,
    required int businessId,
    required String permission,
  }) async {
    final teamMember = await getTeamMemberByUserAndBusiness(userId, businessId);
    if (teamMember == null) return false;

    switch (permission) {
      case 'canMakeSales':
        return teamMember.canMakeSales;
      case 'canViewProducts':
        return teamMember.canViewProducts;
      case 'canEditProducts':
        return teamMember.canEditProducts;
      case 'canManageCredit':
        return teamMember.canManageCredit;
      case 'canViewReports':
        return teamMember.canViewReports;
      case 'canAddTeam':
        return teamMember.canAddTeam;
      case 'canManageDevices':
        return teamMember.canManageDevices;
      case 'canDelete':
        return teamMember.canDelete;
      default:
        return false;
    }
  }
}
