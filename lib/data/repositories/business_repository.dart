import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../datasources/local/preferences_service.dart';
import '../models/models.dart';

class BusinessRepository {
  final Isar _isar = DatabaseService.instance;

  /// Get current business (first and usually only business)
  Future<Business?> getCurrent() async {
    try {
      // Try to get from preferences first
      final businessId = PreferencesService.businessId;
      if (businessId != null) {
        return await _isar.business.get(businessId);
      }

      // Otherwise get first business
      return await _isar.business.where().findFirst();
    } catch (e) {
      throw Exception('Failed to fetch business: $e');
    }
  }

  /// Save new business
  Future<int> save(Business business) async {
    try {
      final now = DateTime.now();
      business.createdAt = now;
      business.updatedAt = now;

      return await _isar.writeTxn(() async {
        final id = await _isar.business.put(business);

        // Save to preferences
        await PreferencesService.setBusinessId(id);

        // Queue for sync
        await _queueForSync(SyncOperation.create, id);

        return id;
      });
    } catch (e) {
      throw Exception('Failed to save business: $e');
    }
  }

  /// Update existing business
  Future<void> update(Business business) async {
    try {
      business.updatedAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.business.put(business);

        // Queue for sync
        await _queueForSync(SyncOperation.update, business.id);
      });
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  /// Check if business exists
  Future<bool> exists() async {
    try {
      final count = await _isar.business.count();
      return count > 0;
    } catch (e) {
      throw Exception('Failed to check business existence: $e');
    }
  }

  /// Queue change for sync
  Future<void> _queueForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'businesses'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}
