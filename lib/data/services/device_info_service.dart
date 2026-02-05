import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/device.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get unique device identifier
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'unknown-ios';
      }
    } catch (e) {
      // Fallback to a generated ID if device info fails
    }
    return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get full device info for registration
  static Future<DeviceRegistrationInfo> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return DeviceRegistrationInfo(
        deviceId: info.id,
        deviceName: info.model,
        deviceType: DeviceType.android,
        deviceModel: '${info.manufacturer} ${info.model}',
        osVersion: 'Android ${info.version.release}',
        appVersion: packageInfo.version,
      );
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return DeviceRegistrationInfo(
        deviceId: info.identifierForVendor ?? 'unknown-ios',
        deviceName: info.name,
        deviceType: DeviceType.ios,
        deviceModel: info.model,
        osVersion: 'iOS ${info.systemVersion}',
        appVersion: packageInfo.version,
      );
    }

    return DeviceRegistrationInfo(
      deviceId: 'unknown-${DateTime.now().millisecondsSinceEpoch}',
      deviceName: 'Unknown Device',
      deviceType: DeviceType.android,
      deviceModel: 'Unknown',
      osVersion: 'Unknown',
      appVersion: packageInfo.version,
    );
  }

  /// Get app version
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Get app build number
  static Future<String> getBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  /// Get full app version string
  static Future<String> getFullVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Get platform name
  static String get platformName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
}

class DeviceRegistrationInfo {
  final String deviceId;
  final String deviceName;
  final DeviceType deviceType;
  final String deviceModel;
  final String osVersion;
  final String appVersion;

  DeviceRegistrationInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });

  Device toDevice({required String userId, bool isPrimary = false}) {
    return Device.create(
      deviceId: deviceId,
      userId: userId,
      deviceName: deviceName,
      deviceType: deviceType,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
      isPrimary: isPrimary,
    );
  }

  @override
  String toString() {
    return 'DeviceRegistrationInfo(deviceId: $deviceId, deviceName: $deviceName, '
        'deviceType: $deviceType, deviceModel: $deviceModel, '
        'osVersion: $osVersion, appVersion: $appVersion)';
  }
}
