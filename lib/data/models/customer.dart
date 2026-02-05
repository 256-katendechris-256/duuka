import 'package:isar/isar.dart';
import 'product.dart' show SyncStatus;

part 'customer.g.dart';

@collection
class Customer {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  @Index(unique: true)
  late String phone;

  String? location;
  String? notes;

  @Index()
  late DateTime createdAt;

  DateTime? lastPurchaseAt;

  /// Total number of purchases
  int totalPurchases = 0;

  /// Total amount spent (lifetime)
  double totalSpent = 0.0;

  /// Credit balance (amount owed by customer)
  double creditBalance = 0.0;

  /// Credit limit for this customer
  double creditLimit = 0.0;

  /// Remote ID for sync
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  Customer();

  Customer.create({
    required this.name,
    required this.phone,
    this.location,
    this.notes,
  }) : createdAt = DateTime.now();

  /// Display name with phone
  String get displayName => '$name ($phone)';

  /// Short display for lists
  String get shortDisplay => name.length > 20 ? '${name.substring(0, 17)}...' : name;

  /// Outstanding balance (alias for creditBalance)
  @ignore
  double get balance => creditBalance;

  /// Check if customer is over their credit limit
  @ignore
  bool get isOverLimit => creditLimit > 0 && creditBalance > creditLimit;

  @override
  String toString() => 'Customer(id: $id, name: $name, phone: $phone)';
}
