import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/security/secure_storage_service.dart';

class PinService {
  static const int _iterations = 100000;
  static const int _saltLength = 32;

  /// Generate a cryptographically secure salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  /// Hash PIN using PBKDF2 with HMAC-SHA256
  static String _hashPin(String pin, String salt) {
    final pinBytes = utf8.encode(pin);
    final saltBytes = base64Decode(salt);

    // PBKDF2 implementation using HMAC-SHA256
    Uint8List result = Uint8List.fromList(saltBytes);

    for (int i = 0; i < _iterations; i++) {
      final hmac = Hmac(sha256, pinBytes);
      final digest = hmac.convert(result);
      result = Uint8List.fromList(digest.bytes);
    }

    return base64Encode(result);
  }

  /// Set up a new PIN
  static Future<bool> setupPin(String pin) async {
    try {
      // Validate PIN
      final validation = validatePin(pin);
      if (validation != null) {
        return false;
      }

      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);

      await SecureStorageService.savePinSalt(salt);
      await SecureStorageService.savePinHash(hash);
      await SecureStorageService.savePinCreatedAt(DateTime.now());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify entered PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final storedSalt = await SecureStorageService.getPinSalt();
      final storedHash = await SecureStorageService.getPinHash();

      if (storedSalt == null || storedHash == null) {
        return false;
      }

      final hash = _hashPin(pin, storedSalt);
      return hash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Check if PIN is set up
  static Future<bool> hasPin() async {
    return await SecureStorageService.hasPinSetup();
  }

  /// Change PIN (requires old PIN verification)
  static Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;

    return await setupPin(newPin);
  }

  /// Reset PIN (clears all PIN data - use after re-authentication)
  static Future<void> resetPin() async {
    await SecureStorageService.clearPinData();
  }

  /// Enable/disable biometric authentication
  static Future<void> setBiometricEnabled(bool enabled) async {
    await SecureStorageService.setBiometricEnabled(enabled);
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    return await SecureStorageService.isBiometricEnabled();
  }

  /// Validate PIN format
  /// Returns null if valid, error message if invalid
  static String? validatePin(String? pin) {
    if (pin == null || pin.isEmpty) {
      return 'PIN is required';
    }

    if (pin.length < 4 || pin.length > 6) {
      return 'PIN must be 4-6 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      return 'PIN must contain only numbers';
    }

    // Disallow common weak PINs
    const weakPins = [
      '0000',
      '1111',
      '2222',
      '3333',
      '4444',
      '5555',
      '6666',
      '7777',
      '8888',
      '9999',
      '1234',
      '4321',
      '0123',
      '3210',
      '1212',
      '2121',
    ];

    if (weakPins.contains(pin)) {
      return 'Please choose a stronger PIN';
    }

    // Check for sequential digits
    bool isSequential = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) + 1) {
        isSequential = false;
        break;
      }
    }
    if (isSequential && pin.length >= 4) {
      return 'Please choose a stronger PIN';
    }

    // Check for reverse sequential digits
    bool isReverseSequential = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) - 1) {
        isReverseSequential = false;
        break;
      }
    }
    if (isReverseSequential && pin.length >= 4) {
      return 'Please choose a stronger PIN';
    }

    return null;
  }

  /// Get PIN creation date
  static Future<DateTime?> getPinCreatedAt() async {
    return await SecureStorageService.getPinCreatedAt();
  }
}
