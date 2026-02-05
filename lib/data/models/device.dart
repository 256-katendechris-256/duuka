import 'package:isar/isar.dart';

import 'product.dart' show SyncStatus;

part 'device.g.dart';

@collection
class Device {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String deviceId;

  @Index()
  late String userId;

  String? deviceName;

  @enumerated
  DeviceType deviceType = DeviceType.android;

  String? deviceModel;
  String? osVersion;
  String? appVersion;
  String? fcmToken;

  bool isPrimary = false;
  bool isActive = true;

  late DateTime registeredAt;
  DateTime? lastActiveAt;

  String? remoteId;

  @enumerated
  SyncStatus syncStatus = SyncStatus.pending;

  Device();

  factory Device.create({
    required String deviceId,
    required String userId,
    String? deviceName,
    required DeviceType deviceType,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    String? fcmToken,
    bool isPrimary = false,
  }) {
    return Device()
      ..deviceId = deviceId
      ..userId = userId
      ..deviceName = deviceName
      ..deviceType = deviceType
      ..deviceModel = deviceModel
      ..osVersion = osVersion
      ..appVersion = appVersion
      ..fcmToken = fcmToken
      ..isPrimary = isPrimary
      ..isActive = true
      ..registeredAt = DateTime.now()
      ..lastActiveAt = DateTime.now()
      ..syncStatus = SyncStatus.pending;
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType.name,
      'device_model': deviceModel,
      'os_version': osVersion,
      'app_version': appVersion,
      'fcm_token': fcmToken,
      'is_primary': isPrimary,
      'is_active': isActive,
      'registered_at': registeredAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device()
      ..deviceId = json['device_id'] as String
      ..userId = json['user_id'] as String
      ..deviceName = json['device_name'] as String?
      ..deviceType = DeviceType.values.firstWhere(
        (e) => e.name == json['device_type'],
        orElse: () => DeviceType.android,
      )
      ..deviceModel = json['device_model'] as String?
      ..osVersion = json['os_version'] as String?
      ..appVersion = json['app_version'] as String?
      ..fcmToken = json['fcm_token'] as String?
      ..isPrimary = json['is_primary'] as bool? ?? false
      ..isActive = json['is_active'] as bool? ?? true
      ..registeredAt = DateTime.parse(json['registered_at'] as String)
      ..lastActiveAt = json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null
      ..remoteId = json['id'] as String?
      ..syncStatus = SyncStatus.synced;
  }

  void updateLastActive() {
    lastActiveAt = DateTime.now();
    syncStatus = SyncStatus.pending;
  }

  @ignore
  String get displayName => deviceName ?? deviceModel ?? 'Unknown Device';

  @ignore
  String get deviceTypeDisplay {
    switch (deviceType) {
      case DeviceType.android:
        return 'Android';
      case DeviceType.ios:
        return 'iOS';
      case DeviceType.web:
        return 'Web';
    }
  }
}

enum DeviceType {
  android,
  ios,
  web,
}
