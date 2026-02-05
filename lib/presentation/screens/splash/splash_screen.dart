import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/local/preferences_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pin_provider.dart';

/// Splash screen with logo and auth check
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Clear PIN session on app start (user needs to verify PIN each session)
    await PreferencesService.clearPinSession();

    // Wait a moment for auth state to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check auth status
    final authState = ref.read(authProvider);
    final pinState = ref.read(pinProvider);
    final isOnboardingComplete = ref.read(isOnboardingCompleteProvider);

    // Route based on auth and PIN status
    switch (authState.status) {
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        context.go('/login');
        break;

      case AuthStatus.pinRequired:
        context.go('/pin/login');
        break;

      case AuthStatus.pinSetupRequired:
        context.go('/pin/setup');
        break;

      case AuthStatus.authenticated:
        // Check PIN status
        if (!pinState.hasPin) {
          context.go('/pin/setup');
        } else if (!pinState.isVerified) {
          context.go('/pin/login');
        } else if (!isOnboardingComplete) {
          context.go('/onboarding/welcome');
        } else {
          context.go('/home');
        }
        break;

      case AuthStatus.initial:
      case AuthStatus.loading:
      case AuthStatus.otpSent:
      case AuthStatus.otpVerifying:
        // Still initializing, wait and retry
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _checkAuthAndNavigate();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: DuukaColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo Container
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Icon(
                  Icons.store,
                  size: 60.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24.h),

              // App Name
              Text(
                DuukaStrings.appName,
                style: TextStyle(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8.h),

              // Tagline
              Text(
                DuukaStrings.appTagline,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const Spacer(),

              // Loading Spinner
              SizedBox(
                width: 32.w,
                height: 32.h,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}
