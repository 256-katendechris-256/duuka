import 'package:isar/isar.dart';

part 'sync_queue.g.dart';

@collection
class SyncQueue {
  Id id = Isar.autoIncrement;

  @enumerated
  late SyncOperation operation;

  late String collectionName;
  late int localId;
  String? remoteId;

  String? payload;

  int retryCount = 0;
  String? errorMessage;

  @enumerated
  SyncQueueStatus status = SyncQueueStatus.pending;

  late DateTime createdAt;
  DateTime? processedAt;
}

enum SyncOperation { create, update, delete }
enum SyncQueueStatus { pending, processing, completed, failed }
