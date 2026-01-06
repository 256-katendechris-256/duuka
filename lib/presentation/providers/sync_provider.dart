import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart' as connectivity_plus;

import '../../data/datasources/local/database_service.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/models/models.dart';

part 'sync_provider.g.dart';

// Sync Status Enum
enum SyncStatusType { synced, syncing, offline, error }

// Sync State Class
class SyncState {
  final SyncStatusType status;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? error;
  final bool isOnline;

  const SyncState({
    this.status = SyncStatusType.offline,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.error,
    this.isOnline = false,
  });

  SyncState copyWith({
    SyncStatusType? status,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? error,
    bool? isOnline,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: clearError ? null : (error ?? this.error),
      isOnline: isOnline ?? this.isOnline,
    );
  }

  bool get isSynced => status == SyncStatusType.synced && pendingCount == 0;
  bool get isSyncing => status == SyncStatusType.syncing;
  bool get hasError => status == SyncStatusType.error;
  bool get hasPending => pendingCount > 0;
}

// Sync Provider
@riverpod
class Sync extends _$Sync {
  StreamSubscription<connectivity_plus.ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  @override
  SyncState build() {
    _initializeConnectivity();
    _startPeriodicSync();
    _loadInitialState();

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _syncTimer?.cancel();
    });

    return const SyncState();
  }

  Future<void> _loadInitialState() async {
    final lastSync = PreferencesService.lastSyncTime;
    final pendingCount = await _getPendingCount();

    state = state.copyWith(
      lastSyncTime: lastSync,
      pendingCount: pendingCount,
    );
  }

  void _initializeConnectivity() {
    // Listen to connectivity changes
    _connectivitySubscription = connectivity_plus.Connectivity()
        .onConnectivityChanged
        .listen((connectivity_plus.ConnectivityResult result) {
      final isOnline = result == connectivity_plus.ConnectivityResult.mobile ||
          result == connectivity_plus.ConnectivityResult.wifi ||
          result == connectivity_plus.ConnectivityResult.ethernet;

      _updateConnectionStatus(isOnline);

      if (isOnline && state.hasPending) {
        // Auto-sync when coming online with pending changes
        sync();
      }
    });

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await connectivity_plus.Connectivity().checkConnectivity();
      final isOnline = result == connectivity_plus.ConnectivityResult.mobile ||
          result == connectivity_plus.ConnectivityResult.wifi ||
          result == connectivity_plus.ConnectivityResult.ethernet;
      _updateConnectionStatus(isOnline);
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  void _updateConnectionStatus(bool isOnline) {
    state = state.copyWith(
      isOnline: isOnline,
      status: isOnline
          ? (state.hasPending ? SyncStatusType.syncing : SyncStatusType.synced)
          : SyncStatusType.offline,
    );
  }

  void _startPeriodicSync() {
    // Sync every 15 minutes when online
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (state.isOnline && state.hasPending) {
        sync();
      }
    });
  }

  Future<int> _getPendingCount() async {
    try {
      final isar = DatabaseService.instance;
      final pendingCount = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.pending)
          .count();
      final failedCount = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.failed)
          .count();
      return pendingCount + failedCount;
    } catch (e) {
      return 0;
    }
  }

  Future<void> refresh() async {
    final pendingCount = await _getPendingCount();
    final lastSync = PreferencesService.lastSyncTime;

    state = state.copyWith(
      pendingCount: pendingCount,
      lastSyncTime: lastSync,
    );
  }

  Future<bool> sync() async {
    if (!state.isOnline) {
      state = state.copyWith(
        status: SyncStatusType.offline,
        error: 'No internet connection',
      );
      return false;
    }

    if (state.isSyncing) {
      return false; // Already syncing
    }

    state = state.copyWith(
      status: SyncStatusType.syncing,
      clearError: true,
    );

    try {
      // TODO: Implement actual sync with Firebase
      // For now, simulate sync
      await Future.delayed(const Duration(seconds: 2));

      // Get pending items
      final isar = DatabaseService.instance;
      final pendingItems = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.pending)
          .findAll();
      final failedItems = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.failed)
          .findAll();
      final allItems = [...pendingItems, ...failedItems];

      // Simulate processing each item
      for (final item in allItems) {
        // TODO: Sync with Firebase based on operation and collection
        // For now, mark as completed
        await isar.writeTxn(() async {
          item.status = SyncQueueStatus.completed;
          item.processedAt = DateTime.now();
          await isar.syncQueues.put(item);
        });
      }

      // Update last sync time
      final now = DateTime.now();
      await PreferencesService.setLastSyncTime(now);

      state = state.copyWith(
        status: SyncStatusType.synced,
        pendingCount: 0,
        lastSyncTime: now,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatusType.error,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> forceSyncNow() async {
    await sync();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Connectivity Provider (simple bool)
@riverpod
class NetworkStatus extends _$NetworkStatus {
  StreamSubscription<connectivity_plus.ConnectivityResult>? _subscription;

  @override
  bool build() {
    _checkConnectivity();

    _subscription = connectivity_plus.Connectivity()
        .onConnectivityChanged
        .listen((connectivity_plus.ConnectivityResult result) {
      state = result == connectivity_plus.ConnectivityResult.mobile ||
          result == connectivity_plus.ConnectivityResult.wifi ||
          result == connectivity_plus.ConnectivityResult.ethernet;
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return false;
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await connectivity_plus.Connectivity().checkConnectivity();
      state = result == connectivity_plus.ConnectivityResult.mobile ||
          result == connectivity_plus.ConnectivityResult.wifi ||
          result == connectivity_plus.ConnectivityResult.ethernet;
    } catch (e) {
      state = false;
    }
  }
}
