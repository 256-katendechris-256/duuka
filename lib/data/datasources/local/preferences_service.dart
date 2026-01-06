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
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';

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

  // Settings
  static bool get notificationsEnabled => _settings.get(keyNotificationsEnabled, defaultValue: true);
  static Future<void> setNotificationsEnabled(bool value) => _settings.put(keyNotificationsEnabled, value);

  static bool get biometricEnabled => _settings.get(keyBiometricEnabled, defaultValue: false);
  static Future<void> setBiometricEnabled(bool value) => _settings.put(keyBiometricEnabled, value);

  static bool get autoBackupEnabled => _settings.get(keyAutoBackupEnabled, defaultValue: true);
  static Future<void> setAutoBackupEnabled(bool value) => _settings.put(keyAutoBackupEnabled, value);

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
