import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/post_auth_navigator.dart';
import '../../../data/datasources/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';

/// Screen shown when a user has registered but is awaiting admin approval.
/// Auto-checks approval status every 30 seconds. User can also pull to refresh.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  Timer? _autoCheckTimer;
  bool _isChecking = false;
  String _statusMessage = 'Your account is being reviewed';
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    // Auto-check every 30 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkApprovalStatus();
    });
    // Check immediately on load
    _checkApprovalStatus();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApprovalStatus() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null || user.uid.isEmpty) {
        setState(() {
          _statusMessage = 'Unable to check status';
          _isChecking = false;
        });
        return;
      }

      // Query Supabase for current approval status
      final data = await SupabaseService.selectSingle(
        'users',
        matchColumn: 'auth_id',
        matchValue: user.uid,
      );

      if (!mounted) return;

      if (data != null) {
        final isApproved = data['is_approved'] == true;
        setState(() {
          _lastChecked = DateTime.now();
          _isChecking = false;
        });

        if (isApproved) {
          // Update local user
          user.isApproved = true;
          await ref.read(authRepositoryProvider).saveUser(user);

          // Update auth state
          ref.read(authProvider.notifier).onApproved(user);

          if (mounted) {
            setState(() => _statusMessage = 'Approved! Redirecting...');
            // Short delay so user sees the success message
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) {
              navigateAfterAuth(context, ref);
            }
          }
        } else {
          setState(() => _statusMessage = 'Still pending review');
        }
      } else {
        setState(() {
          _statusMessage = 'Account not found on server';
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Could not check status';
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (next.status == AuthStatus.unauthenticated && context.mounted) {
        context.go('/login');
      }
    });
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: DuukaColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkApprovalStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    const Spacer(),

                    // Status icon
                    Container(
                      width: 90.w,
                      height: 90.h,
                      decoration: BoxDecoration(
                        color: DuukaColors.warningBg,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        size: 48.sp,
                        color: DuukaColors.warning,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Title
                    Text(
                      'Waiting for Approval',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),

                    // Description
                    Text(
                      'Your account has been created and is being reviewed. '
                      'Once approved, you\'ll have full access to the app.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: DuukaColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),

                    // Status card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: DuukaColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: DuukaColors.border),
                      ),
                      child: Column(
                        children: [
                          // User info
                          if (user != null) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: DuukaColors.primaryBg,
                                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                                      ? Text(
                                          (user.name ?? user.email ?? '?')
                                              .isNotEmpty
                                              ? (user.name ?? user.email ?? '?')[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: DuukaColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name ?? 'User',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: DuukaColors.textPrimary,
                                        ),
                                      ),
                                      if (user.email != null && user.email!.isNotEmpty)
                                        Text(
                                          user.email!,
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
                            Divider(height: 24.h, color: DuukaColors.border),
                          ],

                          // Approval status row
                          Row(
                            children: [
                              Container(
                                width: 10.w,
                                height: 10.h,
                                decoration: BoxDecoration(
                                  color: _statusMessage.contains('Approved')
                                      ? DuukaColors.success
                                      : DuukaColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: _statusMessage.contains('Approved')
                                        ? DuukaColors.success
                                        : DuukaColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (_isChecking)
                                SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DuukaColors.primary,
                                  ),
                                ),
                            ],
                          ),

                          // Last checked time
                          if (_lastChecked != null) ...[
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12.sp, color: DuukaColors.textHint),
                                SizedBox(width: 4.w),
                                Text(
                                  'Last checked: ${_formatTime(_lastChecked!)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: DuukaColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Refresh button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isChecking ? null : _checkApprovalStatus,
                        icon: Icon(Icons.refresh, size: 18.sp),
                        label: Text(_isChecking ? 'Checking...' : 'Check Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DuukaColors.primary,
                          side: BorderSide(color: DuukaColors.primary),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    Text(
                      'Auto-checking every 30 seconds',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: DuukaColors.textHint,
                      ),
                    ),

                    const Spacer(),

                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).signOut(clearLocalAuth: true);
                        },
                        icon: Icon(Icons.logout, size: 18.sp, color: DuukaColors.error),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: DuukaColors.error,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
