import 'package:hive_flutter/hive_flutter.dart';

class PreferencesService {
  static const String _settingsBox = 'settings';
  static const String _authBox = 'auth';

  static late Box _settings;
  static late Box _auth;

  // Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyIsOnboardingComplete = 'is_onboarding_complete';
  static const String keyUserId = 'user_id';
  static const String keyBusinessId = 'business_id';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyLastPullTime = 'last_pull_time';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';

  // PIN related keys
  static const String keyHasPin = 'has_pin';
  static const String keyPinFailedAttempts = 'pin_failed_attempts';
  static const String keyPinLockedUntil = 'pin_locked_until';
  static const String keyPinVerifiedThisSession = 'pin_verified_this_session';
  static const String keyCurrentDeviceId = 'current_device_id';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox(_settingsBox);
    _auth = await Hive.openBox(_authBox);
  }

  // First Launch
  static bool get isFirstLaunch => _settings.get(keyIsFirstLaunch, defaultValue: true);
  static Future<void> setFirstLaunch(bool value) => _settings.put(keyIsFirstLaunch, value);

  // Onboarding
  static bool get isOnboardingComplete => _settings.get(keyIsOnboardingComplete, defaultValue: false);
  static Future<void> setOnboardingComplete(bool value) => _settings.put(keyIsOnboardingComplete, value);

  // User & Business
  static String? get userId => _auth.get(keyUserId);
  static Future<void> setUserId(String? value) => _auth.put(keyUserId, value);

  static int? get businessId => _auth.get(keyBusinessId);
  static Future<void> setBusinessId(int? value) => _auth.put(keyBusinessId, value);

  // Sync
  static DateTime? get lastSyncTime {
    final timestamp = _settings.get(keyLastSyncTime);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  static Future<void> setLastSyncTime(DateTime value) =>
      _settings.put(keyLastSyncTime, value.millisecondsSinceEpoch);

  // Pull (for bidirectional sync)
  static DateTime? get lastPullTime {
    final timestamp = _settings.get(keyLastPullTime);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  static Future<void> setLastPullTime(DateTime value) =>
      _settings.put(keyLastPullTime, value.millisecondsSinceEpoch);

  // Settings
  static bool get notificationsEnabled => _settings.get(keyNotificationsEnabled, defaultValue: true);
  static Future<void> setNotificationsEnabled(bool value) => _settings.put(keyNotificationsEnabled, value);

  static bool get biometricEnabled => _settings.get(keyBiometricEnabled, defaultValue: false);
  static Future<void> setBiometricEnabled(bool value) => _settings.put(keyBiometricEnabled, value);

  static bool get autoBackupEnabled => _settings.get(keyAutoBackupEnabled, defaultValue: true);
  static Future<void> setAutoBackupEnabled(bool value) => _settings.put(keyAutoBackupEnabled, value);

  // PIN
  static bool get hasPin => _auth.get(keyHasPin, defaultValue: false);
  static Future<void> setHasPin(bool value) => _auth.put(keyHasPin, value);

  static int get pinFailedAttempts => _auth.get(keyPinFailedAttempts, defaultValue: 0);
  static Future<void> setPinFailedAttempts(int value) => _auth.put(keyPinFailedAttempts, value);

  static int? get pinLockedUntil => _auth.get(keyPinLockedUntil);
  static Future<void> setPinLockedUntil(int? value) {
    if (value == null) {
      return _auth.delete(keyPinLockedUntil);
    }
    return _auth.put(keyPinLockedUntil, value);
  }

  static bool get pinVerifiedThisSession => _auth.get(keyPinVerifiedThisSession, defaultValue: false);
  static Future<void> setPinVerifiedThisSession(bool value) => _auth.put(keyPinVerifiedThisSession, value);

  static String? get currentDeviceId => _auth.get(keyCurrentDeviceId);
  static Future<void> setCurrentDeviceId(String? value) => _auth.put(keyCurrentDeviceId, value);

  // Clear PIN session data (called on app start)
  static Future<void> clearPinSession() async {
    await setPinVerifiedThisSession(false);
  }

  // Clear auth data (for logout)
  static Future<void> clearAuth() async {
    await _auth.clear();
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _settings.clear();
    await _auth.clear();
  }
}
