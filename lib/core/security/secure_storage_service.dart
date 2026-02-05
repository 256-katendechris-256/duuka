import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // PIN related keys
  static const keyPinHash = 'duuka_pin_hash';
  static const keyPinSalt = 'duuka_pin_salt';
  static const keyPinCreatedAt = 'duuka_pin_created_at';
  static const keyBiometricEnabled = 'duuka_biometric_enabled';

  // Auth related keys
  static const keyAuthToken = 'duuka_auth_token';
  static const keyRefreshToken = 'duuka_refresh_token';
  static const keyUserId = 'duuka_user_id';

  /// Write a value to secure storage
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  static Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Delete a value from secure storage
  static Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Check if a key exists
  static Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  /// Delete all values from secure storage
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Read all values from secure storage
  static Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  // Convenience methods for PIN
  static Future<void> savePinHash(String hash) async {
    await write(key: keyPinHash, value: hash);
  }

  static Future<String?> getPinHash() async {
    return await read(key: keyPinHash);
  }

  static Future<void> savePinSalt(String salt) async {
    await write(key: keyPinSalt, value: salt);
  }

  static Future<String?> getPinSalt() async {
    return await read(key: keyPinSalt);
  }

  static Future<void> savePinCreatedAt(DateTime dateTime) async {
    await write(key: keyPinCreatedAt, value: dateTime.toIso8601String());
  }

  static Future<DateTime?> getPinCreatedAt() async {
    final value = await read(key: keyPinCreatedAt);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await write(key: keyBiometricEnabled, value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await read(key: keyBiometricEnabled);
    return value == 'true';
  }

  static Future<bool> hasPinSetup() async {
    final hash = await getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> clearPinData() async {
    await delete(key: keyPinHash);
    await delete(key: keyPinSalt);
    await delete(key: keyPinCreatedAt);
  }

  // Convenience methods for auth tokens
  static Future<void> saveAuthToken(String token) async {
    await write(key: keyAuthToken, value: token);
  }

  static Future<String?> getAuthToken() async {
    return await read(key: keyAuthToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await write(key: keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await read(key: keyRefreshToken);
  }

  static Future<void> saveUserId(String userId) async {
    await write(key: keyUserId, value: userId);
  }

  static Future<String?> getUserId() async {
    return await read(key: keyUserId);
  }

  static Future<void> clearAuthData() async {
    await delete(key: keyAuthToken);
    await delete(key: keyRefreshToken);
    await delete(key: keyUserId);
  }
}
