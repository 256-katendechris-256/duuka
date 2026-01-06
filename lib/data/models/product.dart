import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  String? barcode;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  String? description;
  String? photoPath;
  String? category;

  late double costPrice;
  late double sellPrice;
  late int quantity;
  int reorderLevel = 5;
  String unit = 'pcs';

  bool isActive = true;

  @enumerated
  SyncStatus syncStatus = SyncStatus.pending;

  @Index()
  late DateTime createdAt;
  late DateTime updatedAt;

  String? remoteId;

  // Computed properties
  double get stockValue => costPrice * quantity;
  double get profit => sellPrice - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
  bool get isLowStock => quantity <= reorderLevel;
}

enum SyncStatus { synced, pending, failed }
