import 'package:isar/isar.dart';
import 'product.dart';

part 'customer.g.dart';

@collection
class Customer {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  @Index()
  String? phone;

  String? address;
  String? notes;

  double creditLimit = 0;
  double balance = 0;

  DateTime? lastPurchaseDate;
  double totalPurchases = 0;
  int purchaseCount = 0;

  @enumerated
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime createdAt;
  late DateTime updatedAt;

  String? remoteId;

  // Computed properties
  bool get hasDebt => balance > 0;
  bool get isOverLimit => balance > creditLimit && creditLimit > 0;
}
