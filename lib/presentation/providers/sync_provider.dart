import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart' as connectivity_plus;

import '../../data/datasources/local/database_service.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/datasources/remote/supabase_service.dart';
import '../../data/models/models.dart';

part 'sync_provider.g.dart';

// Sync Status Enum
enum SyncStatusType { synced, syncing, offline, error }

// Sync State Class
class SyncState {
  final SyncStatusType status;
  final int pendingCount;
  final int totalToSync;      // Total items in current sync batch
  final int syncedInBatch;    // Items synced so far in current batch
  final DateTime? lastSyncTime;
  final String? error;
  final bool isOnline;
  final bool isLocalOnly;  // True for team members (non-owners)

  const SyncState({
    this.status = SyncStatusType.offline,
    this.pendingCount = 0,
    this.totalToSync = 0,
    this.syncedInBatch = 0,
    this.lastSyncTime,
    this.error,
    this.isOnline = false,
    this.isLocalOnly = false,
  });

  SyncState copyWith({
    SyncStatusType? status,
    int? pendingCount,
    int? totalToSync,
    int? syncedInBatch,
    DateTime? lastSyncTime,
    String? error,
    bool? isOnline,
    bool? isLocalOnly,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      totalToSync: totalToSync ?? this.totalToSync,
      syncedInBatch: syncedInBatch ?? this.syncedInBatch,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: clearError ? null : (error ?? this.error),
      isOnline: isOnline ?? this.isOnline,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    );
  }

  bool get isSynced => status == SyncStatusType.synced && pendingCount == 0;
  bool get isSyncing => status == SyncStatusType.syncing;
  bool get hasError => status == SyncStatusType.error;
  bool get hasPending => pendingCount > 0;

  /// Progress percentage (0.0 to 1.0) for the current sync batch
  double get progress => totalToSync > 0 ? syncedInBatch / totalToSync : 0.0;
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
        .listen((connectivity_plus.ConnectivityResult result) async {
      final isOnline = result == connectivity_plus.ConnectivityResult.mobile ||
          result == connectivity_plus.ConnectivityResult.wifi ||
          result == connectivity_plus.ConnectivityResult.ethernet;

      _updateConnectionStatus(isOnline);

      if (isOnline && state.hasPending && !state.isLocalOnly) {
        // Auto-sync when coming online with pending changes (owners only)
        final isOwner = await _isOwnerUser();
        if (isOwner) {
          sync();
        }
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

      // Check if user is owner before attempting sync
      final isOwner = await _isOwnerUser();
      if (!isOwner) {
        print('👤 Non-owner user detected - local-only mode enabled');
        state = state.copyWith(isLocalOnly: true, status: SyncStatusType.synced);
        return;
      }

      // Trigger initial sync if online and have pending items (owners only)
      if (isOnline && state.hasPending) {
        print('🔄 Initial connectivity check: online with pending items, starting sync');
        sync();
      } else if (isOnline) {
        // Check for pending items again after a short delay (database might not be ready yet)
        Future.delayed(const Duration(seconds: 2), () async {
          final pendingCount = await _getPendingCount();
          if (pendingCount > 0) {
            print('🔄 Found $pendingCount pending items after delay, starting sync');
            state = state.copyWith(pendingCount: pendingCount);
            sync();
          }
        });
      }
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  Future<void> _updateConnectionStatus(bool isOnline) async {
    // Always refresh pending count from database when connection status changes
    final pendingCount = await _getPendingCount();

    final newStatus = isOnline
        ? (pendingCount > 0 ? SyncStatusType.syncing : SyncStatusType.synced)
        : SyncStatusType.offline;

    state = state.copyWith(
      isOnline: isOnline,
      status: newStatus,
      pendingCount: pendingCount,
    );
  }

  void _startPeriodicSync() {
    // Sync every 15 minutes when online (owners only)
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      if (state.isOnline && state.hasPending && !state.isLocalOnly) {
        final isOwner = await _isOwnerUser();
        if (isOwner) {
          sync();
        }
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
      // Only count failed items that can still be retried (less than 3 retries)
      final failedCount = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.failed)
          .retryCountLessThan(3)
          .count();
      final completedCount = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.completed)
          .count();
      final permanentlyFailedCount = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.failed)
          .retryCountGreaterThan(2)
          .count();

      print('📊 Sync queue: $pendingCount pending, $failedCount retryable, $permanentlyFailedCount permanently failed, $completedCount completed');

      // Debug: print what's actually pending
      if (pendingCount > 0 || failedCount > 0) {
        final items = await isar.syncQueues
            .filter()
            .group((q) => q
                .statusEqualTo(SyncQueueStatus.pending)
                .or()
                .statusEqualTo(SyncQueueStatus.failed)
                .retryCountLessThan(3))
            .findAll();
        final summary = <String, int>{};
        for (final item in items) {
          final key = '${item.collectionName}(${item.status.name})';
          summary[key] = (summary[key] ?? 0) + 1;
        }
        print('   📋 Pending items: $summary');
      }

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

  /// Clear permanently failed items and reset failed items for retry
  Future<void> clearFailedAndRetry() async {
    print('🔄 clearFailedAndRetry() called');
    try {
      final isar = DatabaseService.instance;

      // Delete permanently failed items (retryCount >= 3)
      await isar.writeTxn(() async {
        final permanentlyFailed = await isar.syncQueues
            .filter()
            .statusEqualTo(SyncQueueStatus.failed)
            .retryCountGreaterThan(2)
            .findAll();

        if (permanentlyFailed.isNotEmpty) {
          print('🧹 Clearing ${permanentlyFailed.length} permanently failed items:');
          for (final item in permanentlyFailed) {
            print('   - ${item.collectionName} (ID: ${item.localId}): ${item.errorMessage}');
          }
          await isar.syncQueues.deleteAll(permanentlyFailed.map((e) => e.id).toList());
        } else {
          print('   No permanently failed items to clear');
        }

        // Reset retry count for failed items that can be retried
        final failedItems = await isar.syncQueues
            .filter()
            .statusEqualTo(SyncQueueStatus.failed)
            .findAll();

        for (final item in failedItems) {
          item.retryCount = 0;
          item.status = SyncQueueStatus.pending;
          await isar.syncQueues.put(item);
        }
        if (failedItems.isNotEmpty) {
          print('🔄 Reset ${failedItems.length} failed items for retry');
        }
      });

      // Reset syncing state in case it's stuck
      state = state.copyWith(status: SyncStatusType.offline);

      // Refresh count and trigger sync
      await refresh();
      print('📊 After refresh: isOnline=${state.isOnline}, hasPending=${state.hasPending}, pendingCount=${state.pendingCount}');

      if (state.hasPending) {
        print('🚀 Triggering sync...');
        await sync();
      } else {
        print('✅ No pending items to sync');
        state = state.copyWith(status: SyncStatusType.synced);
      }
    } catch (e) {
      print('❌ Error clearing failed items: $e');
    }
  }

  /// Check if current user is an owner (only owners can sync to cloud)
  Future<bool> _isOwnerUser() async {
    try {
      final isar = DatabaseService.instance;
      final userId = PreferencesService.userId;

      if (userId == null) return false;

      // Try to parse as int for local user ID
      final localUserId = int.tryParse(userId);
      if (localUserId != null) {
        final user = await isar.appUsers.get(localUserId);
        if (user != null) {
          return user.role == UserRole.owner;
        }
      }

      // Try to find by uid (Supabase auth ID)
      final userByUid = await isar.appUsers
          .filter()
          .uidEqualTo(userId)
          .findFirst();

      if (userByUid != null) {
        return userByUid.role == UserRole.owner;
      }

      // If we can't find the user, check if they have Supabase auth (likely owner)
      return SupabaseService.isAuthenticated;
    } catch (e) {
      print('   ⚠️ Error checking owner status: $e');
      // Default to allowing sync if we can't determine (Supabase auth users)
      return SupabaseService.isAuthenticated;
    }
  }

  /// Batch size for processing items in a single sync run.
  static const int _batchSize = 20;

  /// Maximum consecutive failures before stopping the current run.
  static const int _maxConsecutiveFailures = 5;

  /// Retry delay between batches to avoid overwhelming the server.
  static const Duration _batchDelay = Duration(milliseconds: 500);

  int _retryAttempt = 0;

  Future<bool> sync() async {
    print('🔄 Sync started...');

    // Check connectivity directly
    final connectivityResult = await connectivity_plus.Connectivity().checkConnectivity();
    final isOnline = connectivityResult == connectivity_plus.ConnectivityResult.mobile ||
        connectivityResult == connectivity_plus.ConnectivityResult.wifi ||
        connectivityResult == connectivity_plus.ConnectivityResult.ethernet;

    print('   📡 Connectivity: $connectivityResult, isOnline: $isOnline');

    if (!isOnline) {
      print('   ❌ No internet connection');
      state = state.copyWith(
        status: SyncStatusType.offline,
        isOnline: false,
        error: 'No internet connection',
      );
      return false;
    }

    // Update online state
    state = state.copyWith(isOnline: true);

    if (state.isSyncing) {
      print('   ⏳ Already syncing, skipping');
      return false;
    }

    // Check if user is owner
    final isOwner = await _isOwnerUser();
    if (!isOwner) {
      print('   👤 Non-owner user - sync disabled, working locally');
      state = state.copyWith(
        status: SyncStatusType.synced,
        isLocalOnly: true,
        pendingCount: 0,
        clearError: true,
      );
      return true;
    }

    // Check Supabase auth
    print('   🔐 Supabase authenticated: ${SupabaseService.isAuthenticated}');
    if (!SupabaseService.isAuthenticated) {
      print('   ❌ Owner not authenticated with Supabase');
      state = state.copyWith(
        status: SyncStatusType.error,
        error: 'Please sign in to sync data',
      );
      return false;
    }

    print('   ✅ Online and authenticated, proceeding with sync');
    state = state.copyWith(
      status: SyncStatusType.syncing,
      syncedInBatch: 0,
      totalToSync: 0,
      clearError: true,
    );

    try {
      final isar = DatabaseService.instance;

      // Get total pending count
      final totalPending = await _getPendingCount();
      if (totalPending == 0) {
        print('   ✅ No items to sync');
        final now = DateTime.now();
        await PreferencesService.setLastSyncTime(now);
        state = state.copyWith(
          status: SyncStatusType.synced,
          pendingCount: 0,
          lastSyncTime: now,
        );
        _retryAttempt = 0;
        return true;
      }

      state = state.copyWith(totalToSync: totalPending, pendingCount: totalPending);

      int totalSuccess = 0;
      int totalFail = 0;
      int batchNumber = 0;

      // Process in batches until done or hitting too many failures
      while (true) {
        batchNumber++;
        print('   📦 Batch #$batchNumber (processed so far: $totalSuccess ok, $totalFail failed)');

        // Fetch next batch
        final pendingItems = await isar.syncQueues
            .filter()
            .statusEqualTo(SyncQueueStatus.pending)
            .limit(_batchSize)
            .findAll();
        final failedItems = await isar.syncQueues
            .filter()
            .statusEqualTo(SyncQueueStatus.failed)
            .retryCountLessThan(3)
            .limit((_batchSize / 2).ceil())
            .findAll();
        final batchItems = [...pendingItems, ...failedItems];

        if (batchItems.isEmpty) break; // Nothing left

        // Sort by dependency order
        batchItems.sort((a, b) {
          const order = [
            'business', 'businesses',
            'devices',
            'invitations',
            'team_members',
            'customers',
            'products',
            'sales',
            'invoices',
            'credit_transactions',
            'credit_payments',
            'product_returns',
            'expenses',
          ];
          final aIndex = order.indexOf(a.collectionName);
          final bIndex = order.indexOf(b.collectionName);
          return (aIndex == -1 ? 999 : aIndex).compareTo(bIndex == -1 ? 999 : bIndex);
        });

        int batchSuccess = 0;
        int batchFail = 0;
        int consecutiveFailures = 0;

        for (final item in batchItems) {
          // Stop if too many consecutive failures (server might be down)
          if (consecutiveFailures >= _maxConsecutiveFailures) {
            print('   ⛔ Too many consecutive failures, pausing sync');
            break;
          }

          try {
            await _syncItem(item, isar);
            batchSuccess++;
            totalSuccess++;
            consecutiveFailures = 0; // Reset on success

            // Update progress
            state = state.copyWith(
              syncedInBatch: totalSuccess,
              pendingCount: totalPending - totalSuccess,
            );
          } catch (e) {
            batchFail++;
            totalFail++;
            consecutiveFailures++;
            print('   ❌ Sync failed for ${item.collectionName} (ID: ${item.localId}): $e');

            try {
              await isar.writeTxn(() async {
                item.status = SyncQueueStatus.failed;
                item.retryCount++;
                item.errorMessage = e.toString().length > 200
                    ? e.toString().substring(0, 200)
                    : e.toString();
                await isar.syncQueues.put(item);
              });
            } catch (dbError) {
              print('   ⚠️ Could not update failed item status: $dbError');
            }
          }
        }

        print('   📊 Batch #$batchNumber: $batchSuccess ok, $batchFail failed');

        // Stop if this batch had only failures
        if (batchSuccess == 0 && batchFail > 0) {
          print('   ⛔ Entire batch failed, stopping sync run');
          break;
        }

        // Stop if we hit the consecutive failure limit
        if (consecutiveFailures >= _maxConsecutiveFailures) break;

        // Delay between batches to avoid overwhelming the server
        if (batchItems.length >= _batchSize) {
          await Future.delayed(_batchDelay);
        }
      }

      print('   📊 Sync run complete: $totalSuccess success, $totalFail failed');

      // Clean up old completed items
      try {
        await _cleanupCompletedItems(isar);
      } catch (_) {}

      // Update last sync time
      final now = DateTime.now();
      await PreferencesService.setLastSyncTime(now);

      // Refresh pending count
      final remainingCount = await _getPendingCount();

      // Determine final status
      final SyncStatusType finalStatus;
      if (totalFail > 0 && totalSuccess == 0) {
        finalStatus = SyncStatusType.error;
      } else if (remainingCount > 0 && totalFail > 0) {
        finalStatus = SyncStatusType.error; // Partial success with failures
      } else if (remainingCount > 0) {
        finalStatus = SyncStatusType.syncing; // More to do
      } else {
        finalStatus = SyncStatusType.synced;
      }

      state = state.copyWith(
        status: finalStatus,
        pendingCount: remainingCount,
        lastSyncTime: now,
        totalToSync: 0,
        syncedInBatch: 0,
        error: totalFail > 0 ? '$totalFail items failed. Tap to retry.' : null,
        clearError: totalFail == 0,
      );

      // Auto-retry remaining items if no failures this run (more items were added during sync)
      if (remainingCount > 0 && totalFail == 0) {
        _retryAttempt++;
        final delay = Duration(seconds: _retryAttempt <= 3 ? 2 : (_retryAttempt <= 6 ? 5 : 15));
        print('   🔄 More items pending, retry #$_retryAttempt in ${delay.inSeconds}s');
        Future.delayed(delay, () => sync());
      } else if (totalFail == 0) {
        _retryAttempt = 0; // Reset on full success
      }

      return totalFail == 0;
    } catch (e) {
      print('   ❌ Sync error: $e');
      state = state.copyWith(
        status: SyncStatusType.error,
        error: 'Sync error: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e}',
        totalToSync: 0,
        syncedInBatch: 0,
      );
      return false;
    }
  }

  Future<void> _syncItem(SyncQueue item, Isar isar) async {
    final authUserId = SupabaseService.userId;
    if (authUserId == null) throw Exception('User not authenticated');

    print('🔄 Syncing item: ${item.collectionName} (ID: ${item.localId}, Op: ${item.operation})');

    // Get the user's remote ID from the users table (not the auth ID)
    final userRemoteId = await _ensureUserExists(isar, authUserId);
    if (userRemoteId == null && item.collectionName != 'business' && item.collectionName != 'businesses' && item.collectionName != 'users') {
      throw Exception('User not synced to Supabase yet');
    }

    // Get business ID from local database
    final business = await isar.business.where().findFirst();
    final businessId = business?.remoteId;

    switch (item.collectionName) {
      case 'products':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring product sync');
          throw Exception('Business not synced yet');
        }
        await _syncProduct(item, isar, userRemoteId!, businessId);
        print('   ✅ Product synced successfully');
        break;
      case 'sales':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring sale sync');
          throw Exception('Business not synced yet');
        }
        await _syncSale(item, isar, userRemoteId!, businessId);
        print('   ✅ Sale synced successfully');
        break;
      case 'customers':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring customer sync');
          throw Exception('Business not synced yet');
        }
        await _syncCustomer(item, isar, userRemoteId!, businessId);
        print('   ✅ Customer synced successfully');
        break;
      case 'expenses':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring expense sync');
          throw Exception('Business not synced yet');
        }
        await _syncExpense(item, isar, userRemoteId!, businessId);
        print('   ✅ Expense synced successfully');
        break;
      case 'business':
      case 'businesses': // Handle legacy collection name
        await _syncBusiness(item, isar, authUserId);
        print('   ✅ Business synced successfully');
        break;
      case 'users':
        // Users are synced directly during auth, just mark as completed
        await _markCompleted(item, isar);
        print('   ✅ User sync skipped (handled during auth)');
        break;
      case 'devices':
        await _syncDevice(item, isar, userRemoteId!, businessId);
        print('   ✅ Device synced successfully');
        break;
      case 'invitations':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring invitation sync');
          throw Exception('Business not synced yet');
        }
        await _syncInvitation(item, isar, userRemoteId!, businessId);
        print('   ✅ Invitation synced successfully');
        break;
      case 'team_members':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring team member sync');
          throw Exception('Business not synced yet');
        }
        await _syncTeamMember(item, isar, userRemoteId!, businessId);
        print('   ✅ Team member synced successfully');
        break;
      case 'invoices':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring invoice sync');
          throw Exception('Business not synced yet');
        }
        await _syncInvoice(item, isar, userRemoteId!, businessId);
        print('   ✅ Invoice synced successfully');
        break;
      case 'credit_transactions':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring credit transaction sync');
          throw Exception('Business not synced yet');
        }
        await _syncCreditTransaction(item, isar, userRemoteId!, businessId);
        print('   ✅ Credit transaction synced successfully');
        break;
      case 'credit_payments':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring credit payment sync');
          throw Exception('Business not synced yet');
        }
        await _syncCreditPayment(item, isar, userRemoteId!, businessId);
        print('   ✅ Credit payment synced successfully');
        break;
      case 'product_returns':
        if (businessId == null) {
          print('   ⏳ Business not synced yet, deferring product return sync');
          throw Exception('Business not synced yet');
        }
        await _syncProductReturn(item, isar, userRemoteId!, businessId);
        print('   ✅ Product return synced successfully');
        break;
      default:
        print('   ⚠️ Unknown collection: ${item.collectionName}, marking as completed');
        // Unknown collection, mark as completed
        await isar.writeTxn(() async {
          item.status = SyncQueueStatus.completed;
          item.processedAt = DateTime.now();
          await isar.syncQueues.put(item);
        });
    }
  }

  Future<void> _syncProduct(SyncQueue item, Isar isar, String userId, String businessId) async {
    final product = await isar.products.get(item.localId);
    if (product == null) {
      // Product was deleted locally, mark sync as completed
      await _markCompleted(item, isar);
      return;
    }

    // Convert specifications to JSON array
    final specificationsJson = product.specifications
        .map((spec) => {'name': spec.name, 'value': spec.value})
        .toList();

    // Map local column names to Supabase schema
    final data = {
      'business_id': businessId,
      'name': product.name,
      'description': product.description ?? (product.size != null || product.color != null
          ? '${product.size ?? ''} ${product.color ?? ''}'.trim()
          : null),
      'category': product.category,
      'barcode': product.barcode,
      'unit': product.measurementUnit?.name ?? product.customUnit ?? 'piece',
      'buying_price': product.costPrice,
      'selling_price': product.sellPrice,
      'quantity': product.stockQuantity,
      'min_stock_level': product.reorderLevel,
      'specifications': specificationsJson,
      'is_active': product.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = product.createdAt.toIso8601String();
        final response = await SupabaseService.insert('products', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          product.remoteId = remoteId;
          product.syncStatus = SyncStatus.synced;
          await isar.products.put(product);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (product.remoteId != null) {
          await SupabaseService.update('products', data,
              matchColumn: 'id', matchValue: product.remoteId);
          await isar.writeTxn(() async {
            product.syncStatus = SyncStatus.synced;
            await isar.products.put(product);
            await _markCompleted(item, isar, inTransaction: true);
          });
        } else {
          // No remote ID, create instead
          data['created_at'] = product.createdAt.toIso8601String();
          final response = await SupabaseService.insert('products', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            product.remoteId = remoteId;
            product.syncStatus = SyncStatus.synced;
            await isar.products.put(product);
            await _markCompleted(item, isar, inTransaction: true);
          });
        }
        break;

      case SyncOperation.delete:
        if (product.remoteId != null) {
          await SupabaseService.update('products', {'is_active': false},
              matchColumn: 'id', matchValue: product.remoteId);
        }
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncSale(SyncQueue item, Isar isar, String userId, String businessId) async {
    final sale = await isar.sales.get(item.localId);
    if (sale == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get customer remote ID if customer exists
    String? customerRemoteId;
    if (sale.customerId != null) {
      final customer = await isar.customers.get(sale.customerId!);
      customerRemoteId = customer?.remoteId;
    }

    // Map local column names to Supabase schema
    final data = {
      'business_id': businessId,
      'user_id': userId,
      'customer_id': customerRemoteId,
      'sale_number': sale.receiptNumber,
      'sale_type': sale.paymentMethod.name,
      'subtotal': sale.subtotal,
      'discount': sale.discount,
      'total': sale.total,
      'amount_paid': sale.amountPaid,
      'payment_method': sale.paymentMethod.name,
      'status': sale.paymentStatus == PaymentStatus.paid ? 'completed' : 'pending',
      'notes': sale.notes,
      'sold_at': sale.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = sale.createdAt.toIso8601String();
        final response = await SupabaseService.insert('sales', data);
        final remoteId = response['id'] as String?;

        // Also sync sale items
        if (remoteId != null) {
          for (final saleItem in sale.items) {
            // Get product remote ID
            String? productRemoteId;
            final product = await isar.products.get(saleItem.productId);
            productRemoteId = product?.remoteId;

            // Convert specifications to JSON array
            final specsJson = saleItem.specifications
                .map((s) => {'name': s.name, 'value': s.value})
                .toList();

            await SupabaseService.insert('sale_items', {
              'sale_id': remoteId,
              'product_id': productRemoteId,
              'product_name': saleItem.productName,
              'quantity': saleItem.quantity,
              'unit_price': saleItem.unitPrice,
              'total': saleItem.total,
              'specifications': specsJson,
              'created_at': sale.createdAt.toIso8601String(),
            });
          }
        }

        await isar.writeTxn(() async {
          sale.remoteId = remoteId;
          sale.syncStatus = SyncStatus.synced;
          await isar.sales.put(sale);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (sale.remoteId != null) {
          await SupabaseService.update('sales', data,
              matchColumn: 'id', matchValue: sale.remoteId);
        }
        await isar.writeTxn(() async {
          sale.syncStatus = SyncStatus.synced;
          await isar.sales.put(sale);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        // Sales typically aren't deleted, just mark completed
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncCustomer(SyncQueue item, Isar isar, String userId, String businessId) async {
    final customer = await isar.customers.get(item.localId);
    if (customer == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Map local column names to Supabase schema
    final data = {
      'business_id': businessId,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.location,
      'notes': customer.notes,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = customer.createdAt.toIso8601String();
        final response = await SupabaseService.insert('customers', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          customer.remoteId = remoteId;
          customer.syncStatus = SyncStatus.synced;
          await isar.customers.put(customer);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (customer.remoteId != null) {
          await SupabaseService.update('customers', data,
              matchColumn: 'id', matchValue: customer.remoteId);
        } else {
          // No remote ID, create instead
          data['created_at'] = customer.createdAt.toIso8601String();
          final response = await SupabaseService.insert('customers', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            customer.remoteId = remoteId;
            customer.syncStatus = SyncStatus.synced;
            await isar.customers.put(customer);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          customer.syncStatus = SyncStatus.synced;
          await isar.customers.put(customer);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        if (customer.remoteId != null) {
          await SupabaseService.update('customers', {'is_active': false},
              matchColumn: 'id', matchValue: customer.remoteId);
        }
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncExpense(SyncQueue item, Isar isar, String userId, String businessId) async {
    final expense = await isar.expenses.get(item.localId);
    if (expense == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Map local column names to Supabase schema
    final data = {
      'business_id': businessId,
      'user_id': userId,
      'category': expense.category.name,
      'description': expense.description,
      'amount': expense.amount,
      'payment_method': expense.paymentMethod,
      'expense_date': expense.date.toIso8601String().split('T')[0], // Date only
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = expense.createdAt.toIso8601String();
        final response = await SupabaseService.insert('expenses', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          expense.remoteId = remoteId;
          expense.syncStatus = SyncStatus.synced;
          await isar.expenses.put(expense);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (expense.remoteId != null) {
          await SupabaseService.update('expenses', data,
              matchColumn: 'id', matchValue: expense.remoteId);
        } else {
          // No remote ID, create instead
          data['created_at'] = expense.createdAt.toIso8601String();
          final response = await SupabaseService.insert('expenses', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            expense.remoteId = remoteId;
            expense.syncStatus = SyncStatus.synced;
            await isar.expenses.put(expense);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          expense.syncStatus = SyncStatus.synced;
          await isar.expenses.put(expense);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncBusiness(SyncQueue item, Isar isar, String authUserId) async {
    final business = await isar.business.get(item.localId);
    if (business == null) {
      await _markCompleted(item, isar);
      return;
    }

    // First, ensure the user record exists in Supabase users table
    String? userRemoteId = await _ensureUserExists(isar, authUserId);
    if (userRemoteId == null) {
      throw Exception('Failed to get or create user record');
    }

    // Check if business already exists in Supabase for this owner
    if (business.remoteId == null) {
      final existingBusiness = await SupabaseService.from('businesses')
          .select('id')
          .eq('owner_id', userRemoteId)
          .maybeSingle();

      if (existingBusiness != null) {
        // Business already exists, link it to local
        final remoteId = existingBusiness['id'] as String;
        print('   🔗 Found existing business in Supabase, linking: $remoteId');
        await isar.writeTxn(() async {
          business.remoteId = remoteId;
          await isar.business.put(business);
          await _markCompleted(item, isar, inTransaction: true);
        });
        return;
      }
    }

    final data = {
      'name': business.name,
      'owner_name': business.ownerName,
      'phone': business.phone,
      'email': business.email,
      'address': business.address,
      'district': business.district,
      'area': business.area,
      'tin_number': business.tinNumber,
      'business_type': business.businessType.name,
      'business_size': business.businessSize.name,
      'owner_id': userRemoteId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = business.createdAt.toIso8601String();
        final response = await SupabaseService.insert('businesses', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          business.remoteId = remoteId;
          await isar.business.put(business);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (business.remoteId != null) {
          await SupabaseService.update('businesses', data,
              matchColumn: 'id', matchValue: business.remoteId);
        } else {
          // No remote ID, create instead
          data['created_at'] = business.createdAt.toIso8601String();
          final response = await SupabaseService.insert('businesses', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            business.remoteId = remoteId;
            await isar.business.put(business);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await _markCompleted(item, isar);
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncDevice(SyncQueue item, Isar isar, String userId, String? businessId) async {
    final device = await isar.devices.get(item.localId);
    if (device == null) {
      await _markCompleted(item, isar);
      return;
    }

    // If we don't have a remote ID yet, try to link an existing device by (user_id, device_id)
    if (device.remoteId == null) {
      try {
        final existing = await SupabaseService.from('devices')
            .select('id')
            .eq('user_id', userId)
            .eq('device_id', device.deviceId)
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          await isar.writeTxn(() async {
            device.remoteId = existing['id'] as String;
            await isar.devices.put(device);
          });
        }
      } catch (e) {
        // If lookup fails, we'll fall back to insert/update below
        print('⚠️ Device lookup failed: $e');
      }
    }

    final data = {
      'user_id': userId,
      'business_id': businessId,
      'device_id': device.deviceId,
      'device_name': device.deviceName,
      'device_type': device.deviceType.name,
      'device_model': device.deviceModel,
      'os_version': device.osVersion,
      'app_version': device.appVersion,
      'fcm_token': device.fcmToken,
      'is_primary': device.isPrimary,
      'is_approved': true,
      'is_active': device.isActive,
      'last_active_at': device.lastActiveAt?.toIso8601String(),
      'registered_at': device.registeredAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        if (device.remoteId != null) {
          await SupabaseService.update('devices', data,
              matchColumn: 'id', matchValue: device.remoteId);
        } else {
          data['created_at'] = device.registeredAt.toIso8601String();
          final response = await SupabaseService.insert('devices', data);
          device.remoteId = response['id'] as String?;
        }

        await isar.writeTxn(() async {
          device.syncStatus = SyncStatus.synced;
          await isar.devices.put(device);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (device.remoteId != null) {
          await SupabaseService.update('devices', data,
              matchColumn: 'id', matchValue: device.remoteId);
        } else {
          data['created_at'] = device.registeredAt.toIso8601String();
          final response = await SupabaseService.insert('devices', data);
          device.remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            device.syncStatus = SyncStatus.synced;
            await isar.devices.put(device);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          device.syncStatus = SyncStatus.synced;
          await isar.devices.put(device);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        if (device.remoteId != null) {
          await SupabaseService.update('devices', {'is_active': false},
              matchColumn: 'id', matchValue: device.remoteId);
        }
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncCreditTransaction(SyncQueue item, Isar isar, String userId, String businessId) async {
    final creditTxn = await isar.creditTransactions.get(item.localId);
    if (creditTxn == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get customer remote ID
    String? customerRemoteId;
    final customer = await isar.customers.get(creditTxn.customerId);
    customerRemoteId = customer?.remoteId;
    if (customerRemoteId == null) {
      throw Exception('Customer not synced yet');
    }

    // Get sale remote ID if exists
    String? saleRemoteId;
    if (creditTxn.saleId != null) {
      final sale = await isar.sales.get(creditTxn.saleId!);
      saleRemoteId = sale?.remoteId;
    }

    // Get product remote ID if exists (for hire purchase)
    String? productRemoteId;
    if (creditTxn.productId != null) {
      final product = await isar.products.get(creditTxn.productId!);
      productRemoteId = product?.remoteId;
    }

    final data = {
      'business_id': businessId,
      'customer_id': customerRemoteId,
      'sale_id': saleRemoteId,
      'user_id': userId,
      'amount': creditTxn.totalAmount,
      'total_amount': creditTxn.totalAmount,
      'amount_paid': creditTxn.amountPaid,
      'balance_before': 0.0,
      'balance_after': creditTxn.totalAmount - creditTxn.amountPaid,
      'due_date': creditTxn.agreedPaymentDate.toIso8601String().split('T')[0],
      'type': creditTxn.type.name,
      'status': creditTxn.status.name,
      'product_id': productRemoteId,
      'product_name': creditTxn.productName,
      'product_quantity': creditTxn.productQuantity,
      'cleared_at': creditTxn.clearedAt?.toIso8601String(),
      'collected_at': creditTxn.collectedAt?.toIso8601String(),
      'notes': creditTxn.notes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = creditTxn.createdAt.toIso8601String();
        final response = await SupabaseService.insert('credit_transactions', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          creditTxn.remoteId = remoteId;
          creditTxn.syncStatus = SyncStatus.synced;
          await isar.creditTransactions.put(creditTxn);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (creditTxn.remoteId != null) {
          await SupabaseService.update('credit_transactions', data,
              matchColumn: 'id', matchValue: creditTxn.remoteId);
        } else {
          data['created_at'] = creditTxn.createdAt.toIso8601String();
          final response = await SupabaseService.insert('credit_transactions', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            creditTxn.remoteId = remoteId;
            creditTxn.syncStatus = SyncStatus.synced;
            await isar.creditTransactions.put(creditTxn);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          creditTxn.syncStatus = SyncStatus.synced;
          await isar.creditTransactions.put(creditTxn);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncCreditPayment(SyncQueue item, Isar isar, String userId, String businessId) async {
    final payment = await isar.creditPayments.get(item.localId);
    if (payment == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get credit transaction to find customer
    final creditTxn = await isar.creditTransactions.get(payment.creditTransactionId);
    if (creditTxn == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get customer remote ID
    String? customerRemoteId;
    final customer = await isar.customers.get(creditTxn.customerId);
    customerRemoteId = customer?.remoteId;
    if (customerRemoteId == null) {
      throw Exception('Customer not synced yet');
    }

    final data = {
      'business_id': businessId,
      'customer_id': customerRemoteId,
      'user_id': userId,
      'amount': payment.amount,
      'balance_before': 0.0,
      'balance_after': 0.0,
      'payment_method': payment.paymentMethod,
      'receipt_number': payment.receiptNumber,
      'notes': payment.notes,
      'paid_at': payment.paidAt.toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = payment.paidAt.toIso8601String();
        final response = await SupabaseService.insert('credit_payments', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          payment.remoteId = remoteId;
          payment.syncStatus = SyncStatus.synced;
          await isar.creditPayments.put(payment);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (payment.remoteId != null) {
          await SupabaseService.update('credit_payments', data,
              matchColumn: 'id', matchValue: payment.remoteId);
        } else {
          data['created_at'] = payment.paidAt.toIso8601String();
          final response = await SupabaseService.insert('credit_payments', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            payment.remoteId = remoteId;
            payment.syncStatus = SyncStatus.synced;
            await isar.creditPayments.put(payment);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          payment.syncStatus = SyncStatus.synced;
          await isar.creditPayments.put(payment);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncProductReturn(SyncQueue item, Isar isar, String userId, String businessId) async {
    final productReturn = await isar.productReturns.get(item.localId);
    if (productReturn == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get sale remote ID
    String? saleRemoteId;
    final sale = await isar.sales.get(productReturn.saleId);
    saleRemoteId = sale?.remoteId;

    // Get product remote ID
    String? productRemoteId;
    final product = await isar.products.get(productReturn.productId);
    productRemoteId = product?.remoteId;

    // Get customer remote ID if exists
    String? customerRemoteId;
    if (sale?.customerId != null) {
      final customer = await isar.customers.get(sale!.customerId!);
      customerRemoteId = customer?.remoteId;
    }

    final data = {
      'business_id': businessId,
      'sale_id': saleRemoteId,
      'product_id': productRemoteId,
      'customer_id': customerRemoteId,
      'user_id': userId,
      'product_name': productReturn.productName,
      'quantity': productReturn.quantity,
      'unit_price': productReturn.unitPrice,
      'total_refund': productReturn.refundAmount,
      'reason': productReturn.reasonNotes ?? productReturn.reason.name,
      'restock': productReturn.isRestocked,
      'returned_at': productReturn.createdAt.toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = productReturn.createdAt.toIso8601String();
        final response = await SupabaseService.insert('product_returns', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          productReturn.remoteId = remoteId;
          productReturn.syncStatus = SyncStatus.synced;
          await isar.productReturns.put(productReturn);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (productReturn.remoteId != null) {
          await SupabaseService.update('product_returns', data,
              matchColumn: 'id', matchValue: productReturn.remoteId);
        } else {
          data['created_at'] = productReturn.createdAt.toIso8601String();
          final response = await SupabaseService.insert('product_returns', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            productReturn.remoteId = remoteId;
            productReturn.syncStatus = SyncStatus.synced;
            await isar.productReturns.put(productReturn);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          productReturn.syncStatus = SyncStatus.synced;
          await isar.productReturns.put(productReturn);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncInvitation(SyncQueue item, Isar isar, String userId, String businessId) async {
    final invitation = await isar.invitations.get(item.localId);
    if (invitation == null) {
      await _markCompleted(item, isar);
      return;
    }

    final data = {
      'business_id': businessId,
      'invited_by': userId,
      'phone': invitation.phone,
      'code': invitation.code,
      'role': invitation.role.name,
      'can_make_sales': invitation.canMakeSales,
      'can_view_products': invitation.canViewProducts,
      'can_edit_products': invitation.canEditProducts,
      'can_manage_credit': invitation.canManageCredit,
      'can_view_reports': invitation.canViewReports,
      'can_add_team': invitation.canAddTeam,
      'status': invitation.status.name,
      'expires_at': invitation.expiresAt.toIso8601String(),
      'accepted_at': invitation.acceptedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = invitation.createdAt.toIso8601String();
        final response = await SupabaseService.insert('invitations', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          invitation.remoteId = remoteId;
          invitation.syncStatus = SyncStatus.synced;
          await isar.invitations.put(invitation);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (invitation.remoteId != null) {
          await SupabaseService.update('invitations', data,
              matchColumn: 'id', matchValue: invitation.remoteId);
        } else {
          data['created_at'] = invitation.createdAt.toIso8601String();
          final response = await SupabaseService.insert('invitations', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            invitation.remoteId = remoteId;
            invitation.syncStatus = SyncStatus.synced;
            await isar.invitations.put(invitation);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          invitation.syncStatus = SyncStatus.synced;
          await isar.invitations.put(invitation);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncTeamMember(SyncQueue item, Isar isar, String userId, String businessId) async {
    final teamMember = await isar.teamMembers.get(item.localId);
    if (teamMember == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get the user's remote ID for the team member
    String? memberUserRemoteId;
    final memberUser = await isar.appUsers.filter().idEqualTo(teamMember.userId).findFirst();
    if (memberUser == null) {
      throw Exception('Team member user not found locally');
    }

    memberUserRemoteId = memberUser.remoteId;
    if (memberUserRemoteId == null) {
      // Create a remote user row for local-only team members (auth_id null)
      final phone = (memberUser.phone != null && memberUser.phone!.trim().isNotEmpty)
          ? memberUser.phone
          : null;
      if (phone == null) {
        throw Exception('Team member phone is required to sync user');
      }

      final userData = {
        'auth_id': null,
        'phone': phone,
        'name': memberUser.name,
        'email': memberUser.email,
        'is_active': memberUser.isActive,
        'created_at': memberUser.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      String? remoteId;
      try {
        final response = await SupabaseService.insert('users', userData);
        remoteId = response['id'] as String?;
      } catch (e) {
        // If user already exists (unique phone), try to fetch by phone
        try {
          final existing = await SupabaseService.from('users')
              .select('id')
              .eq('phone', phone)
              .maybeSingle();
          remoteId = existing?['id'] as String?;
        } catch (_) {
          rethrow;
        }
      }

      if (remoteId == null) {
        throw Exception('Failed to create remote user for team member');
      }

      await isar.writeTxn(() async {
        memberUser.remoteId = remoteId;
        await isar.appUsers.put(memberUser);
      });

      memberUserRemoteId = remoteId;
    }
    if (memberUserRemoteId == null) {
      throw Exception('Team member user not synced yet');
    }

    final data = {
      'business_id': businessId,
      'user_id': memberUserRemoteId,
      'role': teamMember.role.name,
      'can_make_sales': teamMember.canMakeSales,
      'can_view_products': teamMember.canViewProducts,
      'can_edit_products': teamMember.canEditProducts,
      'can_manage_credit': teamMember.canManageCredit,
      'can_view_reports': teamMember.canViewReports,
      'can_add_team': teamMember.canAddTeam,
      'can_manage_devices': teamMember.canManageDevices,
      'can_delete': teamMember.canDelete,
      'is_active': teamMember.isActive,
      'joined_at': teamMember.joinedAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = teamMember.createdAt.toIso8601String();
        final response = await SupabaseService.insert('team_members', data);
        final remoteId = response['id'] as String?;

        await isar.writeTxn(() async {
          teamMember.remoteId = remoteId;
          teamMember.syncStatus = SyncStatus.synced;
          await isar.teamMembers.put(teamMember);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (teamMember.remoteId != null) {
          await SupabaseService.update('team_members', data,
              matchColumn: 'id', matchValue: teamMember.remoteId);
        } else {
          data['created_at'] = teamMember.createdAt.toIso8601String();
          final response = await SupabaseService.insert('team_members', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            teamMember.remoteId = remoteId;
            teamMember.syncStatus = SyncStatus.synced;
            await isar.teamMembers.put(teamMember);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          teamMember.syncStatus = SyncStatus.synced;
          await isar.teamMembers.put(teamMember);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        if (teamMember.remoteId != null) {
          await SupabaseService.update('team_members', {'is_active': false},
              matchColumn: 'id', matchValue: teamMember.remoteId);
        }
        await _markCompleted(item, isar);
        break;
    }
  }

  Future<void> _syncInvoice(SyncQueue item, Isar isar, String userId, String businessId) async {
    final invoice = await isar.invoices.get(item.localId);
    if (invoice == null) {
      await _markCompleted(item, isar);
      return;
    }

    // Get customer remote ID if customer exists
    String? customerRemoteId;
    if (invoice.customerId != null) {
      final customer = await isar.customers.get(invoice.customerId!);
      customerRemoteId = customer?.remoteId;
    }

    // Get sale remote ID if exists
    String? saleRemoteId;
    if (invoice.saleId != null) {
      final sale = await isar.sales.get(invoice.saleId!);
      saleRemoteId = sale?.remoteId;
    }

    final data = {
      'business_id': businessId,
      'user_id': userId,
      'customer_id': customerRemoteId,
      'invoice_number': invoice.invoiceNumber,
      'status': invoice.status.name,
      'subtotal': invoice.subtotal,
      'discount': invoice.discount,
      'discount_percent': invoice.discountPercent,
      'tax_amount': invoice.taxAmount,
      'total': invoice.total,
      'amount_paid': invoice.amountPaid,
      'balance': invoice.balance,
      'customer_name': invoice.customerName,
      'customer_phone': invoice.customerPhone,
      'user_name': invoice.userName,
      'notes': invoice.notes,
      'issued_at': invoice.issuedAt.toIso8601String(),
      'due_at': invoice.dueAt?.toIso8601String(),
      'sent_at': invoice.sentAt?.toIso8601String(),
      'cancelled_at': invoice.cancelledAt?.toIso8601String(),
      'converted_to_sale_at': invoice.convertedToSaleAt?.toIso8601String(),
      'sale_id': saleRemoteId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (item.operation) {
      case SyncOperation.create:
        data['created_at'] = invoice.createdAt.toIso8601String();
        final response = await SupabaseService.insert('invoices', data);
        final remoteId = response['id'] as String?;

        // Sync invoice items
        if (remoteId != null) {
          for (final item in invoice.items) {
            // Get product remote ID
            String? productRemoteId;
            final product = await isar.products.get(item.productId);
            productRemoteId = product?.remoteId;

            // Convert specifications to JSON array
            final specsJson = item.specifications
                .map((s) => {'name': s.name, 'value': s.value})
                .toList();

            await SupabaseService.insert('invoice_items', {
              'invoice_id': remoteId,
              'product_id': productRemoteId,
              'product_name': item.productName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'cost_price': item.costPrice,
              'total': item.total,
              'unit': item.unit,
              'is_measurable': item.isMeasurable,
              'specifications': specsJson,
              'created_at': invoice.createdAt.toIso8601String(),
            });
          }

          // Sync invoice payments
          for (final payment in invoice.payments) {
            await SupabaseService.insert('invoice_payments', {
              'invoice_id': remoteId,
              'business_id': businessId,
              'user_id': userId,
              'amount': payment.amount,
              'payment_method': payment.method.name,
              'reference': payment.reference,
              'notes': payment.notes,
              'paid_at': payment.paidAt.toIso8601String(),
              'created_at': payment.paidAt.toIso8601String(),
            });
          }
        }

        await isar.writeTxn(() async {
          invoice.remoteId = remoteId;
          invoice.syncStatus = SyncStatus.synced;
          await isar.invoices.put(invoice);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.update:
        if (invoice.remoteId != null) {
          await SupabaseService.update('invoices', data,
              matchColumn: 'id', matchValue: invoice.remoteId);
        } else {
          data['created_at'] = invoice.createdAt.toIso8601String();
          final response = await SupabaseService.insert('invoices', data);
          final remoteId = response['id'] as String?;

          await isar.writeTxn(() async {
            invoice.remoteId = remoteId;
            invoice.syncStatus = SyncStatus.synced;
            await isar.invoices.put(invoice);
            await _markCompleted(item, isar, inTransaction: true);
          });
          return;
        }
        await isar.writeTxn(() async {
          invoice.syncStatus = SyncStatus.synced;
          await isar.invoices.put(invoice);
          await _markCompleted(item, isar, inTransaction: true);
        });
        break;

      case SyncOperation.delete:
        await _markCompleted(item, isar);
        break;
    }
  }

  /// Ensure user exists in Supabase users table and return their ID
  Future<String?> _ensureUserExists(Isar isar, String authUserId) async {
    // Check if we have a local user with remote ID
    final localUser = await isar.appUsers.filter().uidEqualTo(authUserId).findFirst();
    if (localUser?.remoteId != null) {
      return localUser!.remoteId;
    }

    // Try to find user in Supabase by auth_id
    try {
      final existing = await SupabaseService.from('users')
          .select('id')
          .eq('auth_id', authUserId)
          .maybeSingle();

      if (existing != null) {
        final remoteId = existing['id'] as String;
        // Update local user with remote ID
        if (localUser != null) {
          await isar.writeTxn(() async {
            localUser.remoteId = remoteId;
            await isar.appUsers.put(localUser);
          });
        }
        return remoteId;
      }

      // Create user in Supabase
      final supabaseUser = SupabaseService.currentUser;
      final rawPhone = supabaseUser?.phone ?? localUser?.phone;
      final phone = (rawPhone != null && rawPhone.trim().isNotEmpty) ? rawPhone : null;
      final email = supabaseUser?.email ?? localUser?.email;
      final userData = {
        'auth_id': authUserId,
        'phone': phone,
        'name': localUser?.name,
        'email': email,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.insert('users', userData);
      final remoteId = response['id'] as String?;

      // Update local user with remote ID
      if (localUser != null && remoteId != null) {
        await isar.writeTxn(() async {
          localUser.remoteId = remoteId;
          await isar.appUsers.put(localUser);
        });
      }

      return remoteId;
    } catch (e) {
      print('Error ensuring user exists: $e');
      return null;
    }
  }

  /// Resolve business remote ID, optionally linking from Supabase if missing.
  Future<String?> _getBusinessRemoteId(Isar isar) async {
    final business = await isar.business.where().findFirst();
    if (business == null) {
      return null;
    }

    if (business.remoteId != null) {
      return business.remoteId;
    }

    final authUserId = SupabaseService.userId;
    if (authUserId == null) {
      return null;
    }

    try {
      final userRemoteId = await _ensureUserExists(isar, authUserId);
      if (userRemoteId == null) {
        return null;
      }

      final existingBusiness = await SupabaseService.from('businesses')
          .select('id')
          .eq('owner_id', userRemoteId)
          .maybeSingle();

      if (existingBusiness != null) {
        final remoteId = existingBusiness['id'] as String;
        await isar.writeTxn(() async {
          business.remoteId = remoteId;
          await isar.business.put(business);
        });
        return remoteId;
      }
    } catch (e) {
      print('Error resolving business remote ID: $e');
    }

    return null;
  }

  Future<void> _markCompleted(SyncQueue item, Isar isar, {bool inTransaction = false}) async {
    item.status = SyncQueueStatus.completed;
    item.processedAt = DateTime.now();

    if (inTransaction) {
      await isar.syncQueues.put(item);
    } else {
      await isar.writeTxn(() async {
        await isar.syncQueues.put(item);
      });
    }
  }

  /// Clean up old completed items to prevent database bloat
  Future<void> _cleanupCompletedItems(Isar isar) async {
    try {
      final completedItems = await isar.syncQueues
          .filter()
          .statusEqualTo(SyncQueueStatus.completed)
          .sortByProcessedAt()
          .findAll();

      // Keep only the last 100 completed items
      if (completedItems.length > 100) {
        final toDelete = completedItems.sublist(0, completedItems.length - 100);
        await isar.writeTxn(() async {
          await isar.syncQueues.deleteAll(toDelete.map((e) => e.id).toList());
        });
        print('   🧹 Cleaned up ${toDelete.length} old completed sync items');
      }
    } catch (e) {
      print('   ⚠️ Failed to cleanup completed items: $e');
    }
  }

  Future<void> forceSyncNow() async {
    await sync();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Link existing Supabase business to local business (for recovery)
  Future<bool> linkExistingBusiness() async {
    final userId = SupabaseService.userId;
    if (userId == null) {
      print('❌ Cannot link business: not authenticated');
      return false;
    }

    final isar = DatabaseService.instance;
    final localBusiness = await isar.business.where().findFirst();
    if (localBusiness == null) {
      print('❌ Cannot link business: no local business found');
      return false;
    }

    if (localBusiness.remoteId != null) {
      print('✅ Business already linked: ${localBusiness.remoteId}');
      return true;
    }

    try {
      // Get user's remote ID first
      final userRemoteId = await _ensureUserExists(isar, userId);
      if (userRemoteId == null) {
        print('❌ Cannot link business: failed to get user remote ID');
        return false;
      }

      // Find business in Supabase
      final existingBusiness = await SupabaseService.from('businesses')
          .select('id')
          .eq('owner_id', userRemoteId)
          .maybeSingle();

      if (existingBusiness != null) {
        final remoteId = existingBusiness['id'] as String;
        await isar.writeTxn(() async {
          localBusiness.remoteId = remoteId;
          await isar.business.put(localBusiness);
        });
        print('✅ Business linked successfully: $remoteId');
        return true;
      } else {
        print('❌ No business found in Supabase for this user');
        return false;
      }
    } catch (e) {
      print('❌ Error linking business: $e');
      return false;
    }
  }

  /// Get list of failed sync items with their errors (for debugging)
  Future<List<Map<String, dynamic>>> getFailedItems() async {
    final isar = DatabaseService.instance;
    final failed = await isar.syncQueues
        .filter()
        .statusEqualTo(SyncQueueStatus.failed)
        .findAll();

    return failed.map((item) => {
      'id': item.id,
      'collection': item.collectionName,
      'localId': item.localId,
      'operation': item.operation.name,
      'error': item.errorMessage,
      'retryCount': item.retryCount,
    }).toList();
  }

  /// Clear all sync queue (use with caution - for debugging)
  Future<void> clearSyncQueue() async {
    final isar = DatabaseService.instance;
    await isar.writeTxn(() async {
      await isar.syncQueues.clear();
    });

    state = state.copyWith(
      pendingCount: 0,
      status: SyncStatusType.synced,
    );
  }

  /// Get sync queue status for debugging
  Future<Map<String, int>> getSyncQueueStats() async {
    final isar = DatabaseService.instance;
    final pending = await isar.syncQueues
        .filter()
        .statusEqualTo(SyncQueueStatus.pending)
        .count();
    final processing = await isar.syncQueues
        .filter()
        .statusEqualTo(SyncQueueStatus.processing)
        .count();
    final completed = await isar.syncQueues
        .filter()
        .statusEqualTo(SyncQueueStatus.completed)
        .count();
    final failed = await isar.syncQueues
        .filter()
        .statusEqualTo(SyncQueueStatus.failed)
        .count();

    return {
      'pending': pending,
      'processing': processing,
      'completed': completed,
      'failed': failed,
      'total': pending + processing + completed + failed,
    };
  }

  // ==========================================
  // BIDIRECTIONAL SYNC - PULL FROM REMOTE
  // ==========================================

  /// Pull data from remote Supabase to local database
  Future<void> pullFromRemote() async {
    print('🔄 Pull from remote started...');

    if (!SupabaseService.isAuthenticated) {
      print('   ❌ Not authenticated, skipping pull');
      return;
    }

    try {
      final isar = DatabaseService.instance;
      final authUserId = SupabaseService.userId!;

      // Get user's remote ID
      final userRemoteId = await _ensureUserExists(isar, authUserId);
      if (userRemoteId == null) {
        print('   ❌ User not synced, skipping pull');
        return;
      }

      // Get business
      final business = await isar.business.where().findFirst();
      final businessId = business?.remoteId;
      if (businessId == null) {
        print('   ❌ Business not synced, skipping pull');
        return;
      }

      // Get last pull time
      final lastPull = PreferencesService.lastPullTime;
      print('   📅 Last pull: ${lastPull?.toIso8601String() ?? "never"}');

      // Pull each entity type
      await _pullProducts(isar, businessId, lastPull);
      await _pullCustomers(isar, businessId, lastPull);
      await _pullTeamMembers(isar, businessId, lastPull);
      await _pullInvitations(isar, businessId, lastPull);

      // Update last pull time
      await PreferencesService.setLastPullTime(DateTime.now());
      print('✅ Pull from remote completed');
    } catch (e) {
      print('❌ Pull from remote error: $e');
    }
  }

  /// Pull products from remote
  Future<void> _pullProducts(Isar isar, String businessId, DateTime? since) async {
    try {
      var query = SupabaseService.from('products')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true);

      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }

      final remoteProducts = await query;
      print('   📦 Pulled ${remoteProducts.length} products');

      await isar.writeTxn(() async {
        for (final remote in remoteProducts) {
          // Find existing by remoteId
          final existing = await isar.products
              .filter()
              .remoteIdEqualTo(remote['id'])
              .findFirst();

          // Check for local pending changes
          if (existing != null && existing.syncStatus == SyncStatus.pending) {
            continue; // Local has pending changes, skip
          }

          final product = existing ?? Product();
          product.remoteId = remote['id'];
          product.name = remote['name'] ?? '';
          product.description = remote['description'];
          product.category = remote['category'];
          product.barcode = remote['barcode'];
          product.costPrice = (remote['buying_price'] as num?)?.toDouble() ?? 0;
          product.sellPrice = (remote['selling_price'] as num?)?.toDouble() ?? 0;
          product.stockQuantity = (remote['quantity'] as num?)?.toDouble() ?? 0;
          product.reorderLevel = (remote['min_stock_level'] as num?)?.toInt() ?? 0;
          product.isActive = remote['is_active'] ?? true;
          product.syncStatus = SyncStatus.synced;

          if (existing == null) {
            product.createdAt = DateTime.parse(remote['created_at']);
          }

          await isar.products.put(product);
        }
      });
    } catch (e) {
      print('   ⚠️ Error pulling products: $e');
    }
  }

  /// Pull customers from remote
  Future<void> _pullCustomers(Isar isar, String businessId, DateTime? since) async {
    try {
      var query = SupabaseService.from('customers')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true);

      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }

      final remoteCustomers = await query;
      print('   👥 Pulled ${remoteCustomers.length} customers');

      await isar.writeTxn(() async {
        for (final remote in remoteCustomers) {
          // Find existing by remoteId
          final existing = await isar.customers
              .filter()
              .remoteIdEqualTo(remote['id'])
              .findFirst();

          // Check for local pending changes
          if (existing != null && existing.syncStatus == SyncStatus.pending) {
            continue; // Local has pending changes, skip
          }

          final customer = existing ?? Customer();
          customer.remoteId = remote['id'];
          customer.name = remote['name'] ?? '';
          customer.phone = remote['phone'];
          customer.location = remote['address'];
          customer.notes = remote['notes'];
          customer.syncStatus = SyncStatus.synced;

          if (existing == null) {
            customer.createdAt = DateTime.parse(remote['created_at']);
          }

          await isar.customers.put(customer);
        }
      });
    } catch (e) {
      print('   ⚠️ Error pulling customers: $e');
    }
  }

  /// Pull team members from remote
  Future<void> _pullTeamMembers(Isar isar, String businessId, DateTime? since) async {
    try {
      var query = SupabaseService.from('team_members')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true);

      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }

      final remoteMembers = await query;
      print('   👤 Pulled ${remoteMembers.length} team members');

      await isar.writeTxn(() async {
        for (final remote in remoteMembers) {
          // Find existing by remoteId
          final existing = await isar.teamMembers
              .filter()
              .remoteIdEqualTo(remote['id'])
              .findFirst();

          // Check for local pending changes
          if (existing != null && existing.syncStatus == SyncStatus.pending) {
            continue; // Local has pending changes, skip
          }

          final teamMember = existing ?? TeamMember();
          teamMember.remoteId = remote['id'];
          teamMember.role = UserRole.values.firstWhere(
            (r) => r.name == remote['role'],
            orElse: () => UserRole.cashier,
          );
          teamMember.canMakeSales = remote['can_make_sales'] ?? true;
          teamMember.canViewProducts = remote['can_view_products'] ?? true;
          teamMember.canEditProducts = remote['can_edit_products'] ?? false;
          teamMember.canManageCredit = remote['can_manage_credit'] ?? false;
          teamMember.canViewReports = remote['can_view_reports'] ?? false;
          teamMember.canAddTeam = remote['can_add_team'] ?? false;
          teamMember.canManageDevices = remote['can_manage_devices'] ?? false;
          teamMember.canDelete = remote['can_delete'] ?? false;
          teamMember.isActive = remote['is_active'] ?? true;
          teamMember.syncStatus = SyncStatus.synced;

          if (existing == null) {
            teamMember.createdAt = DateTime.parse(remote['created_at']);
            teamMember.joinedAt = DateTime.parse(remote['joined_at'] ?? remote['created_at']);
            // Note: userId and businessId would need to be resolved from local IDs
            // This is a simplified version - in production, you'd need to map remote IDs to local IDs
          }

          await isar.teamMembers.put(teamMember);
        }
      });
    } catch (e) {
      print('   ⚠️ Error pulling team members: $e');
    }
  }

  /// Pull invitations from remote
  Future<void> _pullInvitations(Isar isar, String businessId, DateTime? since) async {
    try {
      var query = SupabaseService.from('invitations')
          .select()
          .eq('business_id', businessId);

      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }

      final remoteInvitations = await query;
      print('   📨 Pulled ${remoteInvitations.length} invitations');

      await isar.writeTxn(() async {
        for (final remote in remoteInvitations) {
          // Find existing by remoteId
          final existing = await isar.invitations
              .filter()
              .remoteIdEqualTo(remote['id'])
              .findFirst();

          // Check for local pending changes
          if (existing != null && existing.syncStatus == SyncStatus.pending) {
            continue; // Local has pending changes, skip
          }

          final invitation = existing ?? Invitation();
          invitation.remoteId = remote['id'];
          invitation.phone = remote['phone'] ?? '';
          invitation.code = remote['code'] ?? '';
          invitation.role = UserRole.values.firstWhere(
            (r) => r.name == remote['role'],
            orElse: () => UserRole.cashier,
          );
          invitation.status = InvitationStatus.values.firstWhere(
            (s) => s.name == remote['status'],
            orElse: () => InvitationStatus.pending,
          );
          invitation.canMakeSales = remote['can_make_sales'] ?? true;
          invitation.canViewProducts = remote['can_view_products'] ?? true;
          invitation.canEditProducts = remote['can_edit_products'] ?? false;
          invitation.canManageCredit = remote['can_manage_credit'] ?? false;
          invitation.canViewReports = remote['can_view_reports'] ?? false;
          invitation.canAddTeam = remote['can_add_team'] ?? false;
          invitation.expiresAt = DateTime.parse(remote['expires_at']);
          if (remote['accepted_at'] != null) {
            invitation.acceptedAt = DateTime.parse(remote['accepted_at']);
          }
          invitation.syncStatus = SyncStatus.synced;

          if (existing == null) {
            invitation.createdAt = DateTime.parse(remote['created_at']);
            // Note: businessId and invitedByUserId would need to be resolved from local IDs
          }

          await isar.invitations.put(invitation);
        }
      });
    } catch (e) {
      print('   ⚠️ Error pulling invitations: $e');
    }
  }

  /// Full sync - push local changes then pull remote changes
  Future<bool> fullSync() async {
    // First push local changes
    final pushResult = await sync();

    // Then pull remote changes
    await pullFromRemote();

    return pushResult;
  }

  /// Direct sync for invitation acceptance (bypasses owner-only sync)
  /// Called when a team member accepts an invitation
  Future<bool> syncInvitationAcceptanceDirectly({
    required Invitation invitation,
    required String memberName,
    String? memberPhone,
  }) async {
    print('🔄 Direct sync of invitation acceptance...');

    try {
      // Check if invitation has a remote ID
      if (invitation.remoteId == null) {
        print('   ⚠️ Invitation has no remote ID, cannot sync directly');
        return false;
      }

      // Check connectivity
      final connectivityResult = await connectivity_plus.Connectivity().checkConnectivity();
      final isOnline = connectivityResult == connectivity_plus.ConnectivityResult.mobile ||
          connectivityResult == connectivity_plus.ConnectivityResult.wifi ||
          connectivityResult == connectivity_plus.ConnectivityResult.ethernet;

      if (!isOnline) {
        print('   ⚠️ No internet connection, skipping direct sync');
        return false;
      }

      // Update invitation in Supabase
      final updateData = {
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
        'member_name': memberName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.update(
        'invitations',
        updateData,
        matchColumn: 'id',
        matchValue: invitation.remoteId,
      );

      print('   ✅ Invitation acceptance synced to Supabase');

      // Update local invitation sync status
      final isar = DatabaseService.instance;
      await isar.writeTxn(() async {
        invitation.syncStatus = SyncStatus.synced;
        await isar.invitations.put(invitation);
      });

      return true;
    } catch (e) {
      print('   ❌ Error syncing invitation acceptance: $e');
      return false;
    }
  }

  /// Pull only team-related data (invitations) for owner to see team members
  Future<void> pullTeamData() async {
    print('🔄 Pulling team data from remote...');

    try {
      // Check if user is owner
      final isOwner = await _isOwnerUser();
      if (!isOwner) {
        print('   ❌ Non-owner cannot pull team data');
        return;
      }

      // Check connectivity
      final connectivityResult = await connectivity_plus.Connectivity().checkConnectivity();
      final isOnline = connectivityResult == connectivity_plus.ConnectivityResult.mobile ||
          connectivityResult == connectivity_plus.ConnectivityResult.wifi ||
          connectivityResult == connectivity_plus.ConnectivityResult.ethernet;

      if (!isOnline) {
        print('   ⚠️ No internet connection');
        return;
      }

      final isar = DatabaseService.instance;
      final businessId = await _getBusinessRemoteId(isar);

      if (businessId == null) {
        print('   ⚠️ No business remote ID found');
        return;
      }

      // Pull invitations (which now include accepted ones with member info)
      await _pullInvitations(isar, businessId, null);

      // Also pull team members if any exist
      await _pullTeamMembers(isar, businessId, null);

      print('   ✅ Team data pulled successfully');
    } catch (e) {
      print('   ❌ Error pulling team data: $e');
    }
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
