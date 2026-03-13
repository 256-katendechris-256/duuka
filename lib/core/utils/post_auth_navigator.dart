import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/local/preferences_service.dart';
import '../../presentation/providers/auth_provider.dart';

/// Centralized post-authentication navigation.
///
/// Every screen that finishes an auth step (login, OTP, PIN setup, PIN login)
/// should call this instead of navigating directly to '/home'.
/// It enforces the correct order:
///   1. Onboarding (create business) if not done
///   2. Approval check before entering dashboard
///   3. Home
void navigateAfterAuth(BuildContext context, WidgetRef ref) {
  final authState = ref.read(authProvider);
  final isOnboardingComplete = PreferencesService.isOnboardingComplete;
  final user = authState.user;

  if (!isOnboardingComplete) {
    // New user or switched account — must create a business first
    context.go('/onboarding/welcome');
  } else if (user != null && !user.isApproved) {
    // Business exists but user hasn't been approved by admin yet
    context.go('/pending-approval');
  } else {
    // All good — go to dashboard
    context.go('/home');
  }
}
