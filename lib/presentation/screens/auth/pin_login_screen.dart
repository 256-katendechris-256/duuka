import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/post_auth_navigator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pin_provider.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _localAuth = LocalAuthentication();

  bool _canUseBiometric = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuthenticate && isDeviceSupported) {
        final isBiometricEnabled = await ref.read(isBiometricAvailableProvider.future);
        setState(() {
          _canUseBiometric = true;
          _isBiometricEnabled = isBiometricEnabled;
        });

        // Auto-trigger biometric if enabled
        if (_isBiometricEnabled) {
          _authenticateWithBiometric();
        }
      }
    } catch (e) {
      // Biometric not available
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Duuka',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        await ref.read(pinProvider.notifier).refresh();
        ref.read(authProvider.notifier).onPinVerified();
        navigateAfterAuth(context, ref);
      }
    } catch (e) {
      // Biometric failed, user will enter PIN
    }
  }

  Future<void> _verifyPin(String pin) async {
    final success = await ref.read(pinProvider.notifier).verifyPin(pin);

    if (success && mounted) {
      ref.read(authProvider.notifier).onPinVerified();
      navigateAfterAuth(context, ref);
    } else {
      _pinController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),

              // User avatar/greeting
              if (authState.user != null) ...[
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: DuukaColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(authState.user!.name ?? authState.user!.phone),
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: DuukaColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Welcome back${authState.user!.name != null ? ', ${authState.user!.name!.split(' ').first}' : ''}!',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: DuukaColors.textPrimary,
                  ),
                ),
              ] else ...[
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: DuukaColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 40.sp,
                    color: DuukaColors.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Enter Your PIN',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: DuukaColors.textPrimary,
                  ),
                ),
              ],

              SizedBox(height: 8.h),

              Text(
                'Enter your PIN to continue',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: DuukaColors.textSecondary,
                ),
              ),

              SizedBox(height: 48.h),

              // PIN Input
              _buildPinInput(pinState),

              if (pinState.error != null) ...[
                SizedBox(height: 16.h),
                Text(
                  pinState.error!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Lockout timer
              if (pinState.isLocked) ...[
                SizedBox(height: 24.h),
                _buildLockoutTimer(pinState),
              ],

              const Spacer(),

              // Biometric button
              if (_canUseBiometric && _isBiometricEnabled && !pinState.isLocked) ...[
                GestureDetector(
                  onTap: _authenticateWithBiometric,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 40.sp,
                      color: DuukaColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Use Fingerprint',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
              ],

              // Forgot PIN / Use different account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _showForgotPinDialog,
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: DuukaColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    ' | ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Use Different Account',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput(PinState pinState) {
    return Column(
      children: [
        // PIN dots display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final filled = index < _pinController.text.length;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? DuukaColors.primary : Colors.transparent,
                border: Border.all(
                  color: filled ? DuukaColors.primary : DuukaColors.border,
                  width: 2,
                ),
              ),
            );
          }),
        ),

        SizedBox(height: 24.h),

        // Hidden text field for PIN input
        if (!pinState.isLocked)
          SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: _pinController,
              focusNode: _pinFocusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              obscureText: true,
              onChanged: (value) {
                setState(() {});
                if (value.length >= 4) {
                  _verifyPin(value);
                }
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),

        // Tap to focus hint
        GestureDetector(
          onTap: pinState.isLocked ? null : () => _pinFocusNode.requestFocus(),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
            child: Text(
              pinState.isLocked ? 'Account temporarily locked' : 'Tap here to enter PIN',
              style: TextStyle(
                fontSize: 14.sp,
                color: pinState.isLocked ? Colors.red : DuukaColors.textSecondary,
              ),
            ),
          ),
        ),

        // Loading indicator
        if (pinState.isLoading)
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildLockoutTimer(PinState pinState) {
    final remaining = pinState.remainingLockTime;
    if (remaining == null) return const SizedBox.shrink();

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_clock,
            color: Colors.red.shade700,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'Account Locked',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Try again in ${minutes}m ${seconds}s',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'To reset your PIN, you\'ll need to verify your phone number again. '
          'This will sign you out of your current session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPinAndSignOut();
            },
            child: const Text(
              'Reset PIN',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPinAndSignOut() async {
    await ref.read(pinProvider.notifier).resetPin();
    await ref.read(authProvider.notifier).signOut(clearLocalAuth: true);
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut(clearLocalAuth: true);
    if (mounted) {
      context.go('/login');
    }
  }
}
