import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../datasources/local/preferences_service.dart';
import '../models/models.dart';

class AuthRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get current user
  Future<AppUser?> getCurrentUser() async {
    try {
      final userId = PreferencesService.userId;
      if (userId == null) return null;

      return await _isar.appUsers
          .filter()
          .uidEqualTo(userId)
          .findFirst();
    } catch (e) {
      throw Exception('Failed to fetch current user: $e');
    }
  }

  /// Save user
  Future<int> saveUser(AppUser user) async {
    try {
      final now = DateTime.now();

      if (user.id == Isar.autoIncrement) {
        // New user
        user.createdAt = now;
      }

      return await _isar.writeTxn(() async {
        final id = await _isar.appUsers.put(user);

        // Save to preferences
        await PreferencesService.setUserId(user.uid);

        // Queue for sync
        await _queueForSync(
          user.id == Isar.autoIncrement ? SyncOperation.create : SyncOperation.update,
          id,
        );

        return id;
      });
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  /// Update last login time
  Future<void> updateLastLogin() async {
    try {
      final userId = PreferencesService.userId;
      if (userId == null) return;

      await _isar.writeTxn(() async {
        final user = await _isar.appUsers
            .filter()
            .uidEqualTo(userId)
            .findFirst();

        if (user != null) {
          user.lastLoginAt = DateTime.now();
          await _isar.appUsers.put(user);

          // Queue for sync
          await _queueForSync(SyncOperation.update, user.id);
        }
      });
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return PreferencesService.userId != null;
  }

  /// Logout (clear preferences and optionally clear user data)
  Future<void> logout({bool clearData = false}) async {
    try {
      await PreferencesService.clearAuth();

      if (clearData) {
        // Optionally clear all local data
        await DatabaseService.clear();
      }
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'users'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}
