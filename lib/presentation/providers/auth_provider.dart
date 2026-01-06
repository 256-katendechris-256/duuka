import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/local/preferences_service.dart';

part 'auth_provider.g.dart';

// Repository Provider
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}

// Auth State
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final String? verificationId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.verificationId,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    String? verificationId,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      verificationId: verificationId ?? this.verificationId,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    _checkAuthStatus();
    return const AuthState();
  }

  Future<void> _checkAuthStatus() async {
    final userId = PreferencesService.userId;
    if (userId != null) {
      try {
        final user = await ref.read(authRepositoryProvider).getCurrentUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } catch (e) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      // TODO: Implement Firebase Phone Auth
      // For now, simulate OTP sent
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        verificationId: 'mock_verification_id',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      // TODO: Implement Firebase OTP verification
      // For now, accept any 6-digit OTP
      await Future.delayed(const Duration(seconds: 2));

      if (otp.length == 6) {
        // Create mock user
        final user = AppUser()
          ..uid = 'mock_user_${DateTime.now().millisecondsSinceEpoch}'
          ..phone = '256700000000'
          ..role = UserRole.owner
          ..isActive = true
          ..createdAt = DateTime.now();

        // Save user
        await ref.read(authRepositoryProvider).saveUser(user);

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return true;
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      // TODO: Implement Google Sign In
      await Future.delayed(const Duration(seconds: 2));

      final user = AppUser()
        ..uid = 'google_user_${DateTime.now().millisecondsSinceEpoch}'
        ..phone = '256700000000'
        ..name = 'Google User'
        ..role = UserRole.owner
        ..isActive = true
        ..createdAt = DateTime.now();

      await ref.read(authRepositoryProvider).saveUser(user);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateUserProfile(String name, String? email) async {
    if (state.user == null) return;

    try {
      final updatedUser = state.user!
        ..name = name
        ..email = email;

      await ref.read(authRepositoryProvider).saveUser(updatedUser);

      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Convenience provider to check if onboarding is complete
@riverpod
bool isOnboardingComplete(IsOnboardingCompleteRef ref) {
  return PreferencesService.isOnboardingComplete;
}
