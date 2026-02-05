import 'package:isar/isar.dart';

import 'product.dart' show SyncStatus;

part 'credit_transaction.g.dart';

/// Type of credit transaction
enum CreditType {
  /// Customer takes item now, pays later
  credit,
  
  /// Customer pays in installments, takes item when fully paid (layaway)
  hirePurchase,
}

/// Status of the credit transaction
enum CreditStatus {
  /// Payment not yet started or minimal
  pending,
  
  /// Some payment made but not complete
  partial,
  
  /// Fully paid/cleared
  cleared,
  
  /// Past the agreed payment date
  overdue,
}

@collection
class CreditTransaction {
  Id id = Isar.autoIncrement;

  /// Link to customer
  @Index()
  late int customerId;

  /// Customer name (denormalized for display)
  late String customerName;

  /// Customer phone (denormalized for display)
  late String customerPhone;

  /// Link to sale (for credit sales)
  int? saleId;

  /// Type: credit or hirePurchase
  @Enumerated(EnumType.name)
  late CreditType type;

  /// Current status
  @Enumerated(EnumType.name)
  late CreditStatus status;

  /// Total amount owed
  late double totalAmount;

  /// Amount paid so far
  double amountPaid = 0.0;

  /// Agreed date to clear the debt
  @Index()
  late DateTime agreedPaymentDate;

  /// For hire purchase: product being paid for
  String? productName;

  /// For hire purchase: product ID (to mark as reserved)
  int? productId;

  /// For hire purchase: quantity reserved
  int? productQuantity;

  /// Optional notes
  String? notes;

  /// When this transaction was created
  @Index()
  late DateTime createdAt;

  /// When fully cleared (if cleared)
  DateTime? clearedAt;

  /// For hire purchase: when item was collected
  DateTime? collectedAt;

  /// Remote ID in Supabase
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  CreditTransaction();

  CreditTransaction.createCredit({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.saleId,
    required this.totalAmount,
    required this.agreedPaymentDate,
    this.amountPaid = 0.0,
    this.notes,
  })  : type = CreditType.credit,
        status = CreditStatus.pending,
        createdAt = DateTime.now();

  CreditTransaction.createHirePurchase({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.productId,
    required this.productName,
    required this.productQuantity,
    required this.totalAmount,
    required this.agreedPaymentDate,
    this.amountPaid = 0.0,
    this.notes,
  })  : type = CreditType.hirePurchase,
        status = CreditStatus.pending,
        createdAt = DateTime.now();

  /// Remaining balance
  double get balance => totalAmount - amountPaid;

  /// Payment progress percentage (0-100)
  double get progressPercent => 
      totalAmount > 0 ? (amountPaid / totalAmount * 100).clamp(0, 100) : 0;

  /// Is this fully paid?
  bool get isCleared => status == CreditStatus.cleared || balance <= 0;

  /// Is this overdue?
  bool get isOverdue => 
      !isCleared && DateTime.now().isAfter(agreedPaymentDate);

  /// Days until due (negative if overdue)
  int get daysUntilDue => 
      agreedPaymentDate.difference(DateTime.now()).inDays;

  /// Days overdue (0 if not overdue)
  int get daysOverdue => 
      isOverdue ? DateTime.now().difference(agreedPaymentDate).inDays : 0;

  /// For hire purchase: has the item been collected?
  bool get isCollected => collectedAt != null;

  /// Can collect item? (hire purchase only, when fully paid)
  bool get canCollect => 
      type == CreditType.hirePurchase && isCleared && !isCollected;

  /// Update status based on current state
  void updateStatus() {
    if (balance <= 0) {
      status = CreditStatus.cleared;
      clearedAt ??= DateTime.now();
    } else if (isOverdue) {
      status = CreditStatus.overdue;
    } else if (amountPaid > 0) {
      status = CreditStatus.partial;
    } else {
      status = CreditStatus.pending;
    }
  }

  @override
  String toString() => 
      'CreditTransaction(id: $id, customer: $customerName, type: $type, '
      'total: $totalAmount, paid: $amountPaid, status: $status)';
}
