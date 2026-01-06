import 'package:isar/isar.dart';
import 'product.dart';

part 'sale.g.dart';

@collection
class Sale {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String receiptNumber;

  late List<SaleItem> items;

  late double subtotal;
  double discount = 0;
  double discountPercent = 0;
  late double total;

  @enumerated
  late PaymentMethod paymentMethod;

  @enumerated
  PaymentStatus paymentStatus = PaymentStatus.paid;

  double amountPaid = 0;
  double balance = 0;

  int? customerId;
  String? customerName;

  late int userId;
  String? userName;

  String? notes;

  @enumerated
  SyncStatus syncStatus = SyncStatus.pending;

  @Index()
  late DateTime createdAt;

  String? remoteId;

  // Computed properties
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalProfit => items.fold(0.0, (sum, item) => sum + item.profit);
}

@embedded
class SaleItem {
  late int productId;
  late String productName;
  late int quantity;
  late double unitPrice;
  late double costPrice;
  late double total;

  double get profit => (unitPrice - costPrice) * quantity;
}

enum PaymentMethod { cash, mobileMoney, credit }
enum PaymentStatus { paid, partial, unpaid }
