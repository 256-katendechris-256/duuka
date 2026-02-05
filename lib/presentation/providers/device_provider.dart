import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/local/preferences_service.dart';
import '../../data/models/device.dart';
import '../../data/models/product.dart' show SyncStatus;
import '../../data/repositories/device_repository.dart';
import '../../data/services/device_info_service.dart';

part 'device_provider.g.dart';

@riverpod
DeviceRepository deviceRepository(DeviceRepositoryRef ref) {
  return DeviceRepository();
}

class DeviceState {
  final bool isLoading;
  final Device? currentDevice;
  final List<Device> userDevices;
  final String? error;

  const DeviceState({
    this.isLoading = false,
    this.currentDevice,
    this.userDevices = const [],
    this.error,
  });

  DeviceState copyWith({
    bool? isLoading,
    Device? currentDevice,
    List<Device>? userDevices,
    String? error,
    bool clearError = false,
    bool clearDevice = false,
  }) {
    return DeviceState(
      isLoading: isLoading ?? this.isLoading,
      currentDevice: clearDevice ? null : (currentDevice ?? this.currentDevice),
      userDevices: userDevices ?? this.userDevices,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isRegistered => currentDevice != null;
}

@Riverpod(keepAlive: true)
class DeviceNotifier extends _$DeviceNotifier {
  @override
  DeviceState build() {
    _loadCurrentDevice();
    return const DeviceState();
  }

  Future<void> _loadCurrentDevice() async {
    final deviceId = PreferencesService.currentDeviceId;
    if (deviceId == null) return;

    final repository = ref.read(deviceRepositoryProvider);
    final device = await repository.getByDeviceId(deviceId);

    if (device != null) {
      state = state.copyWith(currentDevice: device);
    }
  }

  Future<Device?> registerDevice({
    required String userId,
    bool isPrimary = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(deviceRepositoryProvider);

      // Get device info
      final deviceInfo = await DeviceInfoService.getDeviceInfo();

      // Check if device already exists for this user
      var device = await repository.getCurrentDevice(deviceInfo.deviceId, userId);

      if (device != null) {
        // Update existing device
        device.lastActiveAt = DateTime.now();
        device.appVersion = deviceInfo.appVersion;
        device.syncStatus = SyncStatus.pending;
        await repository.save(device);
      } else {
        // Check if this is the first device for the user
        final deviceCount = await repository.getDeviceCount(userId);
        final shouldBePrimary = isPrimary || deviceCount == 0;

        // Create new device
        device = deviceInfo.toDevice(
          userId: userId,
          isPrimary: shouldBePrimary,
        );
        final id = await repository.save(device);
        device.id = id;
      }

      // Store device ID locally
      await PreferencesService.setCurrentDeviceId(device.deviceId);

      // Try to sync with remote
      if (device.remoteId == null) {
        await repository.registerDeviceRemote(device);
      } else {
        await repository.updateDeviceRemote(device);
      }

      state = state.copyWith(
        isLoading: false,
        currentDevice: device,
      );

      return device;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to register device: $e',
      );
      return null;
    }
  }

  Future<void> loadUserDevices(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(deviceRepositoryProvider);

      // First load from local
      var devices = await repository.getByUserId(userId);

      // Try to fetch from remote
      final remoteDevices = await repository.fetchUserDevicesRemote(userId);
      if (remoteDevices.isNotEmpty) {
        // Merge remote devices with local
        for (final remoteDevice in remoteDevices) {
          final existingIndex = devices.indexWhere(
            (d) => d.deviceId == remoteDevice.deviceId,
          );
          if (existingIndex == -1) {
            // New device from remote
            await repository.save(remoteDevice);
            devices.add(remoteDevice);
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        userDevices: devices,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load devices: $e',
      );
    }
  }

  Future<void> updateLastActive() async {
    if (state.currentDevice == null) return;

    final repository = ref.read(deviceRepositoryProvider);
    await repository.updateLastActive(state.currentDevice!.id);

    // Reload current device
    final updated = await repository.getById(state.currentDevice!.id);
    if (updated != null) {
      state = state.copyWith(currentDevice: updated);
    }
  }

  Future<bool> deactivateDevice(Device device) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(deviceRepositoryProvider);

      device.isActive = false;
      device.syncStatus = SyncStatus.pending;
      await repository.save(device);

      if (device.remoteId != null) {
        await repository.deactivateDeviceRemote(device.remoteId!);
      }

      // Update user devices list
      final updatedDevices = state.userDevices
          .map((d) => d.id == device.id ? device : d)
          .toList();

      state = state.copyWith(
        isLoading: false,
        userDevices: updatedDevices,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to deactivate device: $e',
      );
      return false;
    }
  }

  Future<void> syncDevices() async {
    final repository = ref.read(deviceRepositoryProvider);
    await repository.syncPendingDevices();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> clear() async {
    await PreferencesService.setCurrentDeviceId(null);
    state = const DeviceState();
  }
}

@riverpod
Future<String> currentDeviceId(CurrentDeviceIdRef ref) async {
  return await DeviceInfoService.getDeviceId();
}

@riverpod
Future<DeviceRegistrationInfo> currentDeviceInfo(CurrentDeviceInfoRef ref) async {
  return await DeviceInfoService.getDeviceInfo();
}
