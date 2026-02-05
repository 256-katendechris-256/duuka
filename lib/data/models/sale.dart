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
  int get itemCount => items.length;  // Number of distinct items
  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);
  double get totalProfit => items.fold(0.0, (sum, item) => sum + item.profit);
}

/// Sale item specification (snapshot at time of sale)
@embedded
class SaleItemSpecification {
  late String name;
  late String value;

  SaleItemSpecification();

  SaleItemSpecification.create({required this.name, required this.value});
}

@embedded
class SaleItem {
  late int productId;
  late String productName;
  late double quantity;  // Now double to support measurable products (e.g., 0.5 kg)
  late double unitPrice;
  late double costPrice;
  late double total;

  // Unit information for display
  String unit = 'pcs';
  bool isMeasurable = false;

  // Product specifications at time of sale
  List<SaleItemSpecification> specifications = [];

  double get profit => (unitPrice - costPrice) * quantity;

  /// Get specifications as a formatted string for display
  String get specificationsText {
    if (specifications.isEmpty) return '';
    return specifications.map((s) => '${s.name}: ${s.value}').join(', ');
  }
  
  /// Format quantity with unit for display
  String get formattedQuantity {
    if (isMeasurable) {
      return '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} $unit';
    } else {
      return '${quantity.toInt()} $unit';
    }
  }
}

enum PaymentMethod { cash, mobileMoney, credit }
enum PaymentStatus { paid, partial, unpaid }
