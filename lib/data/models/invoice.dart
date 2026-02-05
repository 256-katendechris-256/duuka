import 'package:isar/isar.dart';
import 'product.dart' show SyncStatus;

part 'invoice.g.dart';

enum InvoiceStatus {
  draft,      // Not yet sent to customer
  sent,       // Sent to customer but not paid
  partial,    // Partially paid
  paid,       // Fully paid
  overdue,    // Payment due date passed
  cancelled;  // Cancelled by merchant

  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.partial:
        return 'Partial';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum InvoicePaymentMethod { cash, mobileMoney, bankTransfer, other }

/// Invoice - Quotation/Order sent to customer with payment terms
/// Stock is NOT deducted until invoice is fully paid
@collection
class Invoice {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String invoiceNumber; // INV-2025-001

  late List<InvoiceItem> items;

  late double subtotal;
  double discount = 0; // Fixed discount amount
  double discountPercent = 0; // Discount percentage
  double taxAmount = 0; // Tax/VAT amount
  late double total;

  int? customerId;
  String? customerName;
  String? customerPhone;

  late int userId;
  String? userName;

  // Payment tracking
  @enumerated
  late InvoiceStatus status;

  double amountPaid = 0; // Total amount received so far
  double balance = 0; // Remaining balance

  // Payment records - one entry per payment
  List<InvoicePayment> payments = [];

  // Payment terms
  late DateTime issuedAt;
  DateTime? dueAt; // Optional due date
  String? notes;

  @enumerated
  SyncStatus syncStatus = SyncStatus.pending;

  @Index()
  late DateTime createdAt;

  DateTime? updatedAt;

  /// When invoice was converted to Sale (if paid)
  DateTime? convertedToSaleAt;
  int? saleId; // Reference to Sale record
  String? saleReceiptNumber;

  /// When invoice was sent to customer
  DateTime? sentAt;

  /// When invoice was cancelled
  DateTime? cancelledAt;

  String? remoteId;

  // Computed properties
  @ignore
  int get itemCount => items.length;

  @ignore
  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);

  @ignore
  double get totalProfit => items.fold(0.0, (sum, item) => sum + item.profit);

  /// Remaining balance that needs to be paid
  @ignore
  double get remainingBalance => total - amountPaid;

  /// Percentage of invoice paid
  @ignore
  double get paymentPercentage => total > 0 ? (amountPaid / total) * 100 : 0;

  /// Whether invoice is fully paid
  @ignore
  bool get isPaid => remainingBalance <= 0 && amountPaid > 0;

  /// Whether invoice is overdue
  @ignore
  bool get isOverdue => dueAt != null && dueAt!.isBefore(DateTime.now()) && !isPaid && status != InvoiceStatus.cancelled;

  /// Days until due (negative if overdue)
  @ignore
  int get daysUntilDue => dueAt != null ? dueAt!.difference(DateTime.now()).inDays : 0;

  /// Days overdue (0 if not overdue)
  @ignore
  int get daysOverdue => isOverdue && dueAt != null ? DateTime.now().difference(dueAt!).inDays : 0;

  /// Can edit (only drafts)
  @ignore
  bool get canEdit => status == InvoiceStatus.draft;

  /// Can delete (only drafts)
  @ignore
  bool get canDelete => status == InvoiceStatus.draft;

  /// Can send (only drafts)
  @ignore
  bool get canSend => status == InvoiceStatus.draft;

  /// Can record payment
  @ignore
  bool get canRecordPayment => status != InvoiceStatus.paid && status != InvoiceStatus.cancelled;

  /// Can cancel
  @ignore
  bool get canCancel => status != InvoiceStatus.paid && status != InvoiceStatus.cancelled;

  Invoice();

  Invoice.create({
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.total,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.userId,
    this.userName,
    this.discount = 0,
    this.discountPercent = 0,
    this.taxAmount = 0,
    this.dueAt,
    this.notes,
  }) : createdAt = DateTime.now(),
       issuedAt = DateTime.now(),
       status = InvoiceStatus.draft,
       amountPaid = 0 {
    balance = total;
  }

  /// Update status based on current state
  void updateStatus() {
    if (status == InvoiceStatus.cancelled) return;

    if (remainingBalance <= 0 && amountPaid > 0) {
      status = InvoiceStatus.paid;
    } else if (amountPaid > 0 && remainingBalance > 0) {
      status = InvoiceStatus.partial;
    } else if (isOverdue && status != InvoiceStatus.draft) {
      status = InvoiceStatus.overdue;
    }
    balance = remainingBalance;
  }

  /// Mark as sent
  void markAsSent() {
    if (status == InvoiceStatus.draft) {
      status = InvoiceStatus.sent;
      sentAt = DateTime.now();
    }
  }

  /// Cancel the invoice
  void cancel() {
    if (canCancel) {
      status = InvoiceStatus.cancelled;
      cancelledAt = DateTime.now();
    }
  }

  /// Record a payment
  void recordPayment(InvoicePayment payment) {
    payments.add(payment);
    amountPaid += payment.amount;
    updateStatus();
  }

  @override
  String toString() => 'Invoice(id: $id, invoiceNumber: $invoiceNumber, status: $status, total: $total)';
}

/// Invoice line item (similar to SaleItem but for invoices)
@embedded
class InvoiceItem {
  late int productId;
  late String productName;
  late double quantity;
  late double unitPrice;
  late double costPrice; // For profit calculation when converted to sale
  late double total;

  String unit = 'pcs';
  bool isMeasurable = false;

  List<InvoiceItemSpecification> specifications = [];

  InvoiceItem();

  InvoiceItem.create({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    this.unit = 'pcs',
    this.isMeasurable = false,
  }) : total = quantity * unitPrice;

  @ignore
  double get profit => (unitPrice - costPrice) * quantity;

  @ignore
  String get formattedQuantity {
    if (isMeasurable) {
      return '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} $unit';
    } else {
      return '${quantity.toInt()} $unit';
    }
  }

  @ignore
  bool get hasSpecifications => specifications.isNotEmpty;

  /// Get specifications as a formatted string
  @ignore
  String get specificationsText {
    if (specifications.isEmpty) return '';
    return specifications.map((s) => '${s.name}: ${s.value}').join(', ');
  }

  @override
  String toString() =>
      'InvoiceItem(id: $productId, name: $productName, qty: $quantity, price: $unitPrice)';
}

/// Specification for invoice item at time of invoicing
@embedded
class InvoiceItemSpecification {
  late String name;
  late String value;

  InvoiceItemSpecification();

  InvoiceItemSpecification.create({required this.name, required this.value});
}

/// Payment record for invoice - tracks each payment made
@embedded
class InvoicePayment {
  late DateTime paidAt;
  late double amount;
  @enumerated
  late InvoicePaymentMethod method;
  String? reference; // For bank transfer, mobile money ref, etc.
  String? notes;

  InvoicePayment();

  InvoicePayment.create({
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
  }) : paidAt = DateTime.now();

  @override
  String toString() => 'InvoicePayment(amount: $amount, method: $method, date: $paidAt)';
}
