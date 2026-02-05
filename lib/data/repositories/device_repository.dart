import 'package:isar/isar.dart';

import '../datasources/local/database_service.dart';
import '../datasources/remote/supabase_service.dart';
import '../models/device.dart';
import '../models/product.dart' show SyncStatus;
import '../models/sync_queue.dart';

class DeviceRepository {
  final Isar _isar = DatabaseService.instance;

  // Local operations

  Future<List<Device>> getAll() async {
    return await _isar.devices.where().findAll();
  }

  Future<List<Device>> getByUserId(String userId) async {
    return await _isar.devices
        .filter()
        .userIdEqualTo(userId)
        .findAll();
  }

  Future<Device?> getById(int id) async {
    return await _isar.devices.get(id);
  }

  Future<Device?> getByDeviceId(String deviceId) async {
    return await _isar.devices
        .filter()
        .deviceIdEqualTo(deviceId)
        .findFirst();
  }

  Future<Device?> getCurrentDevice(String deviceId, String userId) async {
    return await _isar.devices
        .filter()
        .deviceIdEqualTo(deviceId)
        .and()
        .userIdEqualTo(userId)
        .findFirst();
  }

  Future<int> save(Device device, {bool queueSync = true}) async {
    final isNew = device.id == Isar.autoIncrement;
    device.syncStatus = SyncStatus.pending;

    return await _isar.writeTxn(() async {
      final savedId = await _isar.devices.put(device);

      if (queueSync) {
        await _queueForSync(
          isNew ? SyncOperation.create : SyncOperation.update,
          savedId,
        );
      }

      return savedId;
    });
  }

  Future<bool> delete(int id) async {
    return await _isar.writeTxn(() async {
      await _queueForSync(SyncOperation.delete, id);
      return await _isar.devices.delete(id);
    });
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'devices'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }

  Future<void> updateLastActive(int id) async {
    await _isar.writeTxn(() async {
      final device = await _isar.devices.get(id);
      if (device != null) {
        device.updateLastActive();
        await _isar.devices.put(device);
      }
    });
  }

  Future<Device?> getPrimaryDevice(String userId) async {
    return await _isar.devices
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isPrimaryEqualTo(true)
        .findFirst();
  }

  Future<int> getDeviceCount(String userId) async {
    return await _isar.devices
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isActiveEqualTo(true)
        .count();
  }

  // Remote operations (Supabase)

  Future<Device?> registerDeviceRemote(Device device) async {
    try {
      final data = device.toJson();
      final response = await SupabaseService.insert('devices', data);

      device.remoteId = response['id'] as String?;
      device.syncStatus = SyncStatus.synced;
      await save(device, queueSync: false); // Already synced

      return device;
    } catch (e) {
      device.syncStatus = SyncStatus.failed;
      await save(device, queueSync: false);
      return null;
    }
  }

  Future<bool> updateDeviceRemote(Device device) async {
    if (device.remoteId == null) return false;

    try {
      final data = {
        'device_name': device.deviceName,
        'fcm_token': device.fcmToken,
        'app_version': device.appVersion,
        'last_active_at': device.lastActiveAt?.toIso8601String(),
        'is_active': device.isActive,
      };

      await SupabaseService.update(
        'devices',
        data,
        matchColumn: 'id',
        matchValue: device.remoteId,
      );

      device.syncStatus = SyncStatus.synced;
      await save(device, queueSync: false); // Already synced

      return true;
    } catch (e) {
      device.syncStatus = SyncStatus.failed;
      await save(device, queueSync: false);
      return false;
    }
  }

  Future<List<Device>> fetchUserDevicesRemote(String userId) async {
    try {
      final response = await SupabaseService.select(
        'devices',
        filters: {'user_id': userId, 'is_active': true},
      );

      return response.map((json) => Device.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> deactivateDeviceRemote(String remoteId) async {
    try {
      await SupabaseService.update(
        'devices',
        {'is_active': false},
        matchColumn: 'id',
        matchValue: remoteId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Sync operations

  Future<void> syncPendingDevices() async {
    final pendingDevices = await _isar.devices
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();

    for (final device in pendingDevices) {
      if (device.remoteId == null) {
        await registerDeviceRemote(device);
      } else {
        await updateDeviceRemote(device);
      }
    }
  }
}
