import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/local/database_service.dart';
import '../../../data/datasources/local/preferences_service.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DuukaColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.primaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group_add,
                      size: 48.sp,
                      color: DuukaColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Center(
                  child: Text(
                    'Join a Team',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    'Enter your phone number and the\ninvitation code from your manager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: DuukaColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),

                // Phone Number Field
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_codeFocusNode);
                  },
                  decoration: InputDecoration(
                    hintText: '771381941',
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Text(
                        '+256',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: DuukaColors.textPrimary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: DuukaColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Validate phone format
                    final error = DuukaValidators.phone(value);
                    if (error != null) return error;
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // Invitation Code Field
                Text(
                  'Invitation Code',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _codeController,
                  focusNode: _codeFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    color: DuukaColors.primary,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 8,
                      color: DuukaColors.textHint,
                    ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: DuukaColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the invitation code';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _joinTeam(),
                ),
                SizedBox(height: 32.h),

                // Join Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _joinTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuukaColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      disabledBackgroundColor: DuukaColors.primary.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Join Team',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Help Text
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.infoBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: DuukaColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: DuukaColors.info,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need an invitation code?',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: DuukaColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Ask the business owner to invite you from Settings > Team Management in the Duuka app.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Back to login
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Back to login',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: DuukaColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _joinTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phoneInput = _phoneController.text.trim();
      final code = _codeController.text.trim();

      // Normalize phone number
      final normalizedPhone = DuukaValidators.normalizePhone(phoneInput);
      final fullPhone = '+256$normalizedPhone';

      print('🔵 Joining team with phone: $fullPhone, code: $code');

      final isar = DatabaseService.instance;
      final teamRepo = TeamRepository();

      // Find invitation by code
      final invitation = await teamRepo.getInvitationByCode(code);

      if (invitation == null) {
        print('🔴 No invitation found with code: $code');
        if (mounted) {
          context.showErrorSnackBar('Invalid invitation code. Please check and try again.');
        }
        return;
      }

      print('🟢 Found invitation for phone: ${invitation.phone}');

      // Normalize the invitation phone for comparison
      final invitationNormalizedPhone = DuukaValidators.normalizePhone(invitation.phone);

      // Validate phone matches
      if (normalizedPhone != invitationNormalizedPhone) {
        print('🔴 Phone mismatch: $normalizedPhone != $invitationNormalizedPhone');
        if (mounted) {
          context.showErrorSnackBar('This code was not sent to this phone number.');
        }
        return;
      }

      // Check if invitation is still valid
      if (!invitation.isValid) {
        print('🔴 Invitation is not valid: status=${invitation.status}, expired=${invitation.isExpired}');
        if (mounted) {
          context.showErrorSnackBar(
            invitation.isExpired
              ? 'This invitation has expired. Ask for a new code.'
              : 'This invitation is no longer valid.',
          );
        }
        return;
      }

      print('🟢 Invitation valid, creating user and team member...');

      // Create or get local user
      AppUser? user = await isar.appUsers
          .filter()
          .phoneEqualTo(fullPhone)
          .findFirst();

      if (user == null) {
        // Generate a local unique ID for invitation-based users (no Supabase auth)
        final localUid = 'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';

        // Create new user with details from invitation
        user = AppUser()
          ..uid = localUid  // Local UID for non-Supabase users
          ..phone = fullPhone
          ..name = invitation.memberName  // Name from invitation
          ..role = invitation.role
          ..businessId = invitation.businessId
          ..isActive = true
          ..createdAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.appUsers.put(user!);
        });
        print('🟢 Created new user with ID: ${user.id}, UID: $localUid, Name: ${invitation.memberName}');
      } else {
        // Update existing user with details from invitation
        user.name = invitation.memberName;
        user.role = invitation.role;
        user.businessId = invitation.businessId;
        await isar.writeTxn(() async {
          await isar.appUsers.put(user!);
        });
        print('🟢 Updated existing user with ID: ${user.id}');
      }

      // Accept the invitation and create team member
      await teamRepo.acceptInvitation(invitation);

      final teamMember = await teamRepo.createTeamMemberFromInvitation(
        userId: user.id,
        userPhone: fullPhone,
        invitation: invitation,
      );
      print('🟢 Created team member with ID: ${teamMember.id}');

      // Directly sync the invitation acceptance to Supabase
      // This bypasses the owner-only sync so the owner can see the new team member
      try {
        await ref.read(syncProvider.notifier).syncInvitationAcceptanceDirectly(
          invitation: invitation,
          memberName: invitation.memberName,
          memberPhone: fullPhone,
        );
        print('🟢 Invitation acceptance synced to Supabase');
      } catch (e) {
        print('⚠️ Could not sync invitation acceptance (will work locally): $e');
      }

      // Save user ID and business ID to preferences
      await PreferencesService.setUserId(user.id.toString());
      await PreferencesService.setBusinessId(invitation.businessId);

      // Update auth state
      ref.read(authProvider.notifier).loginWithInvitation(user);

      if (mounted) {
        _showSuccessDialog(teamMember);
      }
    } catch (e) {
      print('🔴 Error joining team: $e');
      if (mounted) {
        context.showErrorSnackBar('Failed to join team: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(TeamMember teamMember) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: DuukaColors.successBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48.sp,
                color: DuukaColors.success,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Welcome, ${teamMember.userName ?? 'Team Member'}!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You have successfully joined as a ${teamMember.role.name}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Now let\'s set up a PIN for security.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/pin/setup');  // Navigate to PIN setup
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuukaColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Set Up PIN',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
