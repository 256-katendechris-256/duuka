import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/local/preferences_service.dart';
import '../../data/services/pin_service.dart';

part 'pin_provider.g.dart';

class PinState {
  final bool isLoading;
  final bool hasPin;
  final bool isVerified;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final String? error;

  const PinState({
    this.isLoading = false,
    this.hasPin = false,
    this.isVerified = false,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.error,
  });

  PinState copyWith({
    bool? isLoading,
    bool? hasPin,
    bool? isVerified,
    int? failedAttempts,
    DateTime? lockedUntil,
    String? error,
    bool clearError = false,
    bool clearLockout = false,
  }) {
    return PinState(
      isLoading: isLoading ?? this.isLoading,
      hasPin: hasPin ?? this.hasPin,
      isVerified: isVerified ?? this.isVerified,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLocked =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  Duration? get remainingLockTime {
    if (lockedUntil == null) return null;
    final remaining = lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

@Riverpod(keepAlive: true)
class Pin extends _$Pin {
  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 15);

  @override
  PinState build() {
    _checkPinStatus();
    return const PinState();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await PinService.hasPin();
    final failedAttempts = PreferencesService.pinFailedAttempts;
    final lockedUntilMs = PreferencesService.pinLockedUntil;
    final isVerified = PreferencesService.pinVerifiedThisSession;

    DateTime? lockedUntil;
    if (lockedUntilMs != null) {
      lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
      // Clear lockout if it has expired
      if (DateTime.now().isAfter(lockedUntil)) {
        lockedUntil = null;
        await PreferencesService.setPinLockedUntil(null);
        await PreferencesService.setPinFailedAttempts(0);
      }
    }

    state = state.copyWith(
      hasPin: hasPin,
      isVerified: isVerified,
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
    );
  }

  Future<bool> setupPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Validate PIN
      final validation = PinService.validatePin(pin);
      if (validation != null) {
        state = state.copyWith(isLoading: false, error: validation);
        return false;
      }

      final success = await PinService.setupPin(pin);

      if (success) {
        await PreferencesService.setHasPin(true);
        await PreferencesService.setPinVerifiedThisSession(true);
        state = state.copyWith(
          isLoading: false,
          hasPin: true,
          isVerified: true,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set up PIN',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    // Check if locked
    if (state.isLocked) {
      final remaining = state.remainingLockTime;
      if (remaining != null) {
        final minutes = remaining.inMinutes + 1;
        state = state.copyWith(
          error: 'Account locked. Try again in $minutes minute${minutes > 1 ? 's' : ''}.',
        );
      }
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isValid = await PinService.verifyPin(pin);

      if (isValid) {
        // Reset failed attempts and mark as verified
        await PreferencesService.setPinFailedAttempts(0);
        await PreferencesService.setPinLockedUntil(null);
        await PreferencesService.setPinVerifiedThisSession(true);

        state = state.copyWith(
          isLoading: false,
          isVerified: true,
          failedAttempts: 0,
          clearLockout: true,
        );
        return true;
      }

      // Handle failed attempt
      final newAttempts = state.failedAttempts + 1;
      await PreferencesService.setPinFailedAttempts(newAttempts);

      if (newAttempts >= maxAttempts) {
        final lockUntil = DateTime.now().add(lockDuration);
        await PreferencesService.setPinLockedUntil(
          lockUntil.millisecondsSinceEpoch,
        );

        state = state.copyWith(
          isLoading: false,
          failedAttempts: newAttempts,
          lockedUntil: lockUntil,
          error: 'Too many attempts. Try again in 15 minutes.',
        );
      } else {
        final remaining = maxAttempts - newAttempts;
        state = state.copyWith(
          isLoading: false,
          failedAttempts: newAttempts,
          error: 'Incorrect PIN. $remaining attempt${remaining > 1 ? 's' : ''} remaining.',
        );
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Validate new PIN
      final validation = PinService.validatePin(newPin);
      if (validation != null) {
        state = state.copyWith(isLoading: false, error: validation);
        return false;
      }

      final success = await PinService.changePin(oldPin, newPin);

      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Current PIN is incorrect',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> resetPin() async {
    await PinService.resetPin();
    await PreferencesService.setHasPin(false);
    await PreferencesService.setPinFailedAttempts(0);
    await PreferencesService.setPinLockedUntil(null);
    await PreferencesService.setPinVerifiedThisSession(false);

    state = const PinState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> clearSession() async {
    await PreferencesService.setPinVerifiedThisSession(false);
    state = state.copyWith(isVerified: false);
  }

  Future<void> refresh() async {
    await _checkPinStatus();
  }
}

@riverpod
String? pinValidation(PinValidationRef ref, String pin) {
  return PinService.validatePin(pin);
}

@riverpod
Future<bool> hasPinSetup(HasPinSetupRef ref) async {
  return await PinService.hasPin();
}

@riverpod
Future<bool> isBiometricAvailable(IsBiometricAvailableRef ref) async {
  return await PinService.isBiometricEnabled();
}
