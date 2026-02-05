import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/team_provider.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeam();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTeam() {
    final businessAsync = ref.read(businessNotifierProvider);
    final authState = ref.read(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    businessAsync.whenData((business) {
      if (business != null) {
        // Pass isOwner flag so owner can pull latest data from Supabase
        ref.read(teamProvider.notifier).loadTeam(business.id, isOwner: isOwner);
      }
    });
  }

  /// Calculate total member count including accepted invitations (minus duplicates)
  int _getMemberCount(TeamState state) {
    final acceptedInvitations = state.invitations
        .where((i) => i.status == InvitationStatus.accepted)
        .toList();

    // Count accepted invitations that don't have a corresponding TeamMember
    int additionalFromInvitations = 0;
    for (final invitation in acceptedInvitations) {
      final hasMatchingMember = state.members.any((m) =>
          m.userPhone == invitation.phone ||
          m.userPhone == '+256${invitation.phone.replaceAll(RegExp(r'^\+?256'), '')}'
      );
      if (!hasMatchingMember) {
        additionalFromInvitations++;
      }
    }

    return state.members.length + additionalFromInvitations;
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final businessAsync = ref.watch(businessNotifierProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: AppBar(
        title: Text(
          'Team Management',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.textPrimary,
          ),
        ),
        backgroundColor: DuukaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DuukaColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DuukaColors.primary,
          unselectedLabelColor: DuukaColors.textSecondary,
          indicatorColor: DuukaColors.primary,
          tabs: [
            // Count includes actual members + accepted invitations (minus duplicates)
            Tab(text: 'Members (${_getMemberCount(teamState)})'),
            Tab(text: 'Invitations (${teamState.invitations.where((i) => i.status == InvitationStatus.pending).length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(teamState),
          _buildInvitationsTab(teamState),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(),
        backgroundColor: DuukaColors.primary,
        icon: Icon(Icons.person_add, color: Colors.white, size: 20.sp),
        label: Text(
          'Invite',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab(TeamState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get accepted invitations (these are team members who joined)
    final acceptedInvitations = state.invitations
        .where((i) => i.status == InvitationStatus.accepted)
        .toList();

    // Combine actual team members with accepted invitations
    final hasMembers = state.members.isNotEmpty || acceptedInvitations.isNotEmpty;

    if (!hasMembers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64.sp,
              color: DuukaColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              'No team members yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Invite staff to help manage your business',
              style: TextStyle(
                fontSize: 14.sp,
                color: DuukaColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Show actual team members first
        ...state.members.map((member) => _TeamMemberCard(
          member: member,
          onTap: () => _showMemberDetails(member),
        )),

        // Show accepted invitations as team members (in case TeamMember not synced yet)
        ...acceptedInvitations.map((invitation) {
          // Check if there's already a TeamMember with this phone
          final existingMember = state.members.any((m) =>
              m.userPhone == invitation.phone ||
              m.userPhone == '+256${invitation.phone.replaceAll(RegExp(r'^\+?256'), '')}'
          );

          // Only show if no TeamMember exists for this invitation
          if (existingMember) return const SizedBox.shrink();

          return _AcceptedInvitationCard(
            invitation: invitation,
            onTap: () => _showInvitationMemberDetails(invitation),
          );
        }),
      ],
    );
  }

  Widget _buildInvitationsTab(TeamState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingInvitations = state.invitations
        .where((i) => i.status == InvitationStatus.pending)
        .toList();

    if (pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64.sp,
              color: DuukaColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              'No pending invitations',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Invite team members using the button below',
              style: TextStyle(
                fontSize: 14.sp,
                color: DuukaColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: pendingInvitations.length,
      itemBuilder: (context, index) {
        final invitation = pendingInvitations[index];
        return _InvitationCard(
          invitation: invitation,
          onShare: () => _shareInvitation(invitation),
          onCancel: () => _cancelInvitation(invitation),
        );
      },
    );
  }

  void _showInviteDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final ageController = TextEditingController();
    UserRole selectedRole = UserRole.cashier;
    Gender? selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: DuukaColors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Add Team Member',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter the details of the team member you want to add',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
                SizedBox(height: 20.h),

                // Name field
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. John Doe',
                    prefixIcon: Icon(Icons.person, size: 20.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Phone field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '7XX XXX XXX',
                    prefixIcon: Icon(Icons.phone, size: 20.sp),
                    prefixText: '+256 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Gender and Age row
                Row(
                  children: [
                    // Gender dropdown
                    Expanded(
                      child: DropdownButtonFormField<Gender>(
                        value: selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc, size: 20.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                        ),
                        items: Gender.values.map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.label),
                        )).toList(),
                        onChanged: (value) {
                          setModalState(() => selectedGender = value);
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Age field
                    SizedBox(
                      width: 100.w,
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          hintText: 'e.g. 25',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                Text(
                  'Select Role',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                _RoleSelector(
                  selectedRole: selectedRole,
                  onRoleSelected: (role) {
                    setModalState(() => selectedRole = role);
                  },
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final ageText = ageController.text.trim();

                      if (name.isEmpty) {
                        context.showErrorSnackBar('Please enter the member\'s name');
                        return;
                      }
                      if (phone.isEmpty) {
                        context.showErrorSnackBar('Please enter a phone number');
                        return;
                      }

                      final age = ageText.isNotEmpty ? int.tryParse(ageText) : null;

                      Navigator.pop(context);
                      await _createInvitation(
                        name: name,
                        phone: phone,
                        role: selectedRole,
                        gender: selectedGender,
                        age: age,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuukaColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Generate Invitation Code',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createInvitation({
    required String name,
    required String phone,
    required UserRole role,
    Gender? gender,
    int? age,
  }) async {
    final businessAsync = ref.read(businessNotifierProvider);
    final authState = ref.read(authProvider);

    await businessAsync.whenData((business) async {
      if (business == null || authState.user == null) return;

      final invitation = await ref.read(teamProvider.notifier).createInvitation(
        businessId: business.id,
        invitedByUserId: authState.user!.id,
        memberName: name,
        phone: phone,
        role: role,
        gender: gender,
        age: age,
      );

      if (invitation != null && mounted) {
        _showInvitationCodeDialog(invitation);
      }
    });
  }

  void _showInvitationCodeDialog(Invitation invitation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: DuukaColors.success, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Invitation Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with ${invitation.phone}',
              style: TextStyle(
                fontSize: 14.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: DuukaColors.primaryBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: DuukaColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    invitation.code,
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invitation.code));
                      context.showSuccessSnackBar('Code copied to clipboard');
                    },
                    icon: Icon(Icons.copy, size: 20.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Valid for ${invitation.daysUntilExpiry} days',
              style: TextStyle(
                fontSize: 12.sp,
                color: DuukaColors.textHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(teamProvider.notifier).clearLastInvitation();
            },
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareInvitation(invitation);
            },
            icon: Icon(Icons.share, size: 18.sp),
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.primary,
            ),
            label: Text(
              'Share',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _shareInvitation(Invitation invitation) {
    final businessAsync = ref.read(businessNotifierProvider);
    final businessName = businessAsync.valueOrNull?.name ?? 'our business';

    final message = '''
You've been invited to join $businessName on Duuka!

Your invitation code: ${invitation.code}
Role: ${invitation.role.name.toUpperCase()}

To join:
1. Download the Duuka app
2. Enter your phone number: ${invitation.phone}
3. Enter the invitation code when prompted

This code expires in ${invitation.daysUntilExpiry} days.
''';

    Share.share(message, subject: 'Join $businessName on Duuka');
  }

  void _cancelInvitation(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text(
          'Are you sure you want to cancel the invitation for ${invitation.phone}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(teamProvider.notifier).cancelInvitation(invitation);
              context.showSuccessSnackBar('Invitation cancelled');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.error,
            ),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(TeamMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemberDetailsSheet(
        member: member,
        onUpdateRole: (role) async {
          Navigator.pop(context);
          await ref.read(teamProvider.notifier).updateRole(
            teamMember: member,
            role: role,
          );
          context.showSuccessSnackBar('Role updated');
        },
        onRemove: () async {
          Navigator.pop(context);
          await ref.read(teamProvider.notifier).removeTeamMember(member);
          context.showSuccessSnackBar('Team member removed');
        },
      ),
    );
  }

  void _showInvitationMemberDetails(Invitation invitation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InvitationMemberDetailsSheet(
        invitation: invitation,
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onTap;

  const _TeamMemberCard({
    required this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: _getRoleColor(member.role),
          ),
        ),
        title: Text(
          member.userName ?? member.userPhone,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.userName != null)
              Text(
                member.userPhone,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: DuukaColors.textSecondary,
                ),
              ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                member.role.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(member.role),
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: DuukaColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return DuukaColors.primary;
      case UserRole.manager:
        return DuukaColors.info;
      case UserRole.cashier:
        return DuukaColors.success;
      case UserRole.viewer:
        return DuukaColors.textSecondary;
    }
  }
}

class _InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  const _InvitationCard({
    required this.invitation,
    required this.onShare,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Role
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: DuukaColors.primaryBg,
                  child: Icon(Icons.person, size: 20.sp, color: DuukaColors.primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.memberName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14.sp, color: DuukaColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            invitation.phone,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                          if (invitation.gender != null) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '${invitation.gender!.label}${invitation.age != null ? ', ${invitation.age}y' : ''}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: DuukaColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: DuukaColors.warningBg,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    invitation.role.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.key, size: 16.sp, color: DuukaColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'Code: ${invitation.code}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  'Expires in ${invitation.daysUntilExpiry} days',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: DuukaColors.textHint,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(Icons.close, size: 18.sp),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DuukaColors.error,
                      side: BorderSide(color: DuukaColors.error),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: Icon(Icons.share, size: 18.sp, color: Colors.white),
                    label: Text(
                      'Share',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuukaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final Function(UserRole) onRoleSelected;

  const _RoleSelector({
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoleOption(
          role: UserRole.manager,
          isSelected: selectedRole == UserRole.manager,
          onTap: () => onRoleSelected(UserRole.manager),
          description: 'Can edit products, manage credit, view reports',
        ),
        SizedBox(height: 8.h),
        _RoleOption(
          role: UserRole.cashier,
          isSelected: selectedRole == UserRole.cashier,
          onTap: () => onRoleSelected(UserRole.cashier),
          description: 'Can make sales and view products',
        ),
        SizedBox(height: 8.h),
        _RoleOption(
          role: UserRole.viewer,
          isSelected: selectedRole == UserRole.viewer,
          onTap: () => onRoleSelected(UserRole.viewer),
          description: 'Can only view products and inventory',
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;
  final String description;

  const _RoleOption({
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? DuukaColors.primaryBg : DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? DuukaColors.primary : DuukaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<UserRole>(
              value: role,
              groupValue: isSelected ? role : null,
              onChanged: (_) => onTap(),
              activeColor: DuukaColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name[0].toUpperCase() + role.name.substring(1),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberDetailsSheet extends StatelessWidget {
  final TeamMember member;
  final Function(UserRole) onUpdateRole;
  final VoidCallback onRemove;

  const _MemberDetailsSheet({
    required this.member,
    required this.onUpdateRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: DuukaColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              CircleAvatar(
                radius: 30.r,
                backgroundColor: DuukaColors.primaryBg,
                child: Icon(
                  Icons.person,
                  size: 32.sp,
                  color: DuukaColors.primary,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.userName ?? 'Team Member',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    Text(
                      member.userPhone,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Current Role',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: DuukaColors.primaryBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              member.role.name.toUpperCase(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.primary,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Permissions',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (member.canMakeSales) _PermissionChip('Make Sales'),
              if (member.canViewProducts) _PermissionChip('View Products'),
              if (member.canEditProducts) _PermissionChip('Edit Products'),
              if (member.canManageCredit) _PermissionChip('Manage Credit'),
              if (member.canViewReports) _PermissionChip('View Reports'),
              if (member.canAddTeam) _PermissionChip('Add Team'),
            ],
          ),
          SizedBox(height: 24.h),
          if (member.role != UserRole.owner) ...[
            Text(
              'Change Role',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (member.role != UserRole.manager)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onUpdateRole(UserRole.manager),
                      child: const Text('Make Manager'),
                    ),
                  ),
                if (member.role != UserRole.manager &&
                    member.role != UserRole.cashier)
                  SizedBox(width: 8.w),
                if (member.role != UserRole.cashier)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onUpdateRole(UserRole.cashier),
                      child: const Text('Make Cashier'),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove Team Member'),
                      content: Text(
                        'Are you sure you want to remove ${member.userName ?? member.userPhone} from the team?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onRemove();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DuukaColors.error,
                          ),
                          child: Text(
                            'Remove',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.person_remove, color: DuukaColors.error),
                label: Text(
                  'Remove from Team',
                  style: TextStyle(color: DuukaColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: DuukaColors.error),
                ),
              ),
            ),
          ],
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;

  const _PermissionChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: DuukaColors.successBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14.sp,
            color: DuukaColors.success,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: DuukaColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card to display accepted invitations as team members
class _AcceptedInvitationCard extends StatelessWidget {
  final Invitation invitation;
  final VoidCallback onTap;

  const _AcceptedInvitationCard({
    required this.invitation,
    required this.onTap,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return DuukaColors.primary;
      case UserRole.manager:
        return DuukaColors.info;
      case UserRole.cashier:
        return DuukaColors.success;
      case UserRole.viewer:
        return DuukaColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(invitation.role).withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: _getRoleColor(invitation.role),
          ),
        ),
        title: Text(
          invitation.memberName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitation.phone,
              style: TextStyle(
                fontSize: 12.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getRoleColor(invitation.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    invitation.role.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(invitation.role),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: DuukaColors.successBg,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 10.sp, color: DuukaColors.success),
                      SizedBox(width: 4.w),
                      Text(
                        'JOINED',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: DuukaColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

/// Details sheet for team members from accepted invitations
class _InvitationMemberDetailsSheet extends StatelessWidget {
  final Invitation invitation;

  const _InvitationMemberDetailsSheet({
    required this.invitation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: DuukaColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              CircleAvatar(
                radius: 30.r,
                backgroundColor: DuukaColors.primaryBg,
                child: Icon(
                  Icons.person,
                  size: 32.sp,
                  color: DuukaColors.primary,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.memberName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    Text(
                      invitation.phone,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                    if (invitation.gender != null || invitation.age != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          '${invitation.gender?.label ?? ''}${invitation.gender != null && invitation.age != null ? ', ' : ''}${invitation.age != null ? '${invitation.age} years old' : ''}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: DuukaColors.textHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Role',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: DuukaColors.primaryBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              invitation.role.name.toUpperCase(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.primary,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Permissions',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (invitation.canMakeSales) _PermissionChip('Make Sales'),
              if (invitation.canViewProducts) _PermissionChip('View Products'),
              if (invitation.canEditProducts) _PermissionChip('Edit Products'),
              if (invitation.canManageCredit) _PermissionChip('Manage Credit'),
              if (invitation.canViewReports) _PermissionChip('View Reports'),
              if (invitation.canAddTeam) _PermissionChip('Add Team'),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 16.sp, color: DuukaColors.textHint),
              SizedBox(width: 8.w),
              Text(
                'Joined ${invitation.acceptedAt != null ? _formatDate(invitation.acceptedAt!) : 'recently'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: DuukaColors.textHint,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
