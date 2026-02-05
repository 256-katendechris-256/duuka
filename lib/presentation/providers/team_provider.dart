import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';

import '../../data/datasources/local/database_service.dart';
import '../../data/models/models.dart';
import '../../data/repositories/team_repository.dart';
import 'sync_provider.dart';

part 'team_provider.g.dart';

// Repository Provider
@riverpod
TeamRepository teamRepository(TeamRepositoryRef ref) {
  return TeamRepository();
}

// Team State
class TeamState {
  final List<TeamMember> members;
  final List<Invitation> invitations;
  final bool isLoading;
  final String? error;
  final Invitation? lastCreatedInvitation;

  const TeamState({
    this.members = const [],
    this.invitations = const [],
    this.isLoading = false,
    this.error,
    this.lastCreatedInvitation,
  });

  TeamState copyWith({
    List<TeamMember>? members,
    List<Invitation>? invitations,
    bool? isLoading,
    String? error,
    Invitation? lastCreatedInvitation,
    bool clearError = false,
    bool clearLastInvitation = false,
  }) {
    return TeamState(
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastCreatedInvitation: clearLastInvitation ? null : (lastCreatedInvitation ?? this.lastCreatedInvitation),
    );
  }
}

// Team Provider
@riverpod
class Team extends _$Team {
  @override
  TeamState build() {
    return const TeamState();
  }

  /// Load team members and invitations for a business
  /// For owners, this also pulls the latest data from Supabase
  Future<void> loadTeam(int businessId, {bool isOwner = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // If owner, first pull the latest team data from Supabase
      if (isOwner) {
        try {
          await ref.read(syncProvider.notifier).pullTeamData();
          print('✅ Pulled team data from Supabase');
        } catch (e) {
          print('⚠️ Could not pull team data: $e');
        }
      }

      final repository = ref.read(teamRepositoryProvider);

      final members = await repository.getTeamMembersByBusiness(businessId);
      final invitations = await repository.getInvitationsByBusiness(businessId);

      // Clean up expired invitations
      await repository.cleanupExpiredInvitations();

      state = state.copyWith(
        members: members,
        invitations: invitations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create an invitation for a new team member
  Future<Invitation?> createInvitation({
    required int businessId,
    required int invitedByUserId,
    required String memberName,
    required String phone,
    required UserRole role,
    Gender? gender,
    int? age,
    Map<String, bool>? customPermissions,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      // Check if there's already a pending invitation for this phone
      final existing = await repository.getInvitationByPhone(phone);
      if (existing != null && existing.businessId == businessId) {
        state = state.copyWith(
          isLoading: false,
          error: 'An invitation already exists for this phone number',
        );
        return null;
      }

      final invitation = await repository.createInvitation(
        businessId: businessId,
        invitedByUserId: invitedByUserId,
        memberName: memberName,
        phone: phone,
        role: role,
        gender: gender,
        age: age,
        customPermissions: customPermissions,
      );

      // Refresh invitations list
      final invitations = await repository.getInvitationsByBusiness(businessId);

      state = state.copyWith(
        invitations: invitations,
        lastCreatedInvitation: invitation,
        isLoading: false,
      );

      // Trigger sync
      ref.read(syncProvider.notifier).sync();

      return invitation;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Accept an invitation (for invited users joining)
  Future<TeamMember?> acceptInvitation({
    required String phone,
    required String code,
    required int userId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      // Validate the invitation
      final invitation = await repository.validateInvitationCode(phone, code);
      if (invitation == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid or expired invitation code',
        );
        return null;
      }

      // Accept the invitation
      await repository.acceptInvitation(invitation);

      // Create the team member
      final teamMember = await repository.createTeamMemberFromInvitation(
        userId: userId,
        userPhone: phone,
        invitation: invitation,
      );

      state = state.copyWith(isLoading: false);

      // Trigger sync
      ref.read(syncProvider.notifier).sync();

      return teamMember;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update team member permissions
  Future<void> updatePermissions({
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
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      await repository.updateTeamMemberPermissions(
        teamMember: teamMember,
        canMakeSales: canMakeSales,
        canViewProducts: canViewProducts,
        canEditProducts: canEditProducts,
        canManageCredit: canManageCredit,
        canViewReports: canViewReports,
        canAddTeam: canAddTeam,
        canManageDevices: canManageDevices,
        canDelete: canDelete,
      );

      // Refresh team members
      final members = await repository.getTeamMembersByBusiness(teamMember.businessId);

      state = state.copyWith(
        members: members,
        isLoading: false,
      );

      // Trigger sync
      ref.read(syncProvider.notifier).sync();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update team member role
  Future<void> updateRole({
    required TeamMember teamMember,
    required UserRole role,
    bool resetPermissions = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      await repository.updateTeamMemberRole(
        teamMember: teamMember,
        role: role,
        resetPermissions: resetPermissions,
      );

      // Refresh team members
      final members = await repository.getTeamMembersByBusiness(teamMember.businessId);

      state = state.copyWith(
        members: members,
        isLoading: false,
      );

      // Trigger sync
      ref.read(syncProvider.notifier).sync();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Remove a team member
  Future<void> removeTeamMember(TeamMember teamMember) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      await repository.removeTeamMember(teamMember);

      // Refresh team members
      final members = await repository.getTeamMembersByBusiness(teamMember.businessId);

      state = state.copyWith(
        members: members,
        isLoading: false,
      );

      // Trigger sync
      ref.read(syncProvider.notifier).sync();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Cancel a pending invitation
  Future<void> cancelInvitation(Invitation invitation) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(teamRepositoryProvider);

      await repository.rejectInvitation(invitation);

      // Refresh invitations
      final invitations = await repository.getInvitationsByBusiness(invitation.businessId);

      state = state.copyWith(
        invitations: invitations,
        isLoading: false,
      );

      // Trigger sync
      ref.read(syncProvider.notifier).sync();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear the last created invitation (after user has seen/shared it)
  void clearLastInvitation() {
    state = state.copyWith(clearLastInvitation: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Current user's team membership provider
@riverpod
Future<TeamMember?> currentTeamMember(CurrentTeamMemberRef ref, int userId, int businessId) async {
  final repository = ref.read(teamRepositoryProvider);
  return repository.getTeamMemberByUserAndBusiness(userId, businessId);
}

// Permission check provider
@riverpod
Future<bool> checkPermission(
  CheckPermissionRef ref,
  int userId,
  int businessId,
  String permission,
) async {
  final repository = ref.read(teamRepositoryProvider);
  return repository.checkPermission(
    userId: userId,
    businessId: businessId,
    permission: permission,
  );
}

// Team member count provider
@riverpod
Future<int> teamMemberCount(TeamMemberCountRef ref, int businessId) async {
  final repository = ref.read(teamRepositoryProvider);
  return repository.getTeamMemberCount(businessId);
}
