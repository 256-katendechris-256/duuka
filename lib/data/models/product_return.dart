import 'package:isar/isar.dart';

import 'product.dart' show SyncStatus;

part 'product_return.g.dart';

/// Reason for the return
enum ReturnReason {
  defective,
  wrongItem,
  notAsDescribed,
  changedMind,
  damaged,
  expired,
  other,
}

extension ReturnReasonExtension on ReturnReason {
  String get label {
    switch (this) {
      case ReturnReason.defective:
        return 'Defective Product';
      case ReturnReason.wrongItem:
        return 'Wrong Item';
      case ReturnReason.notAsDescribed:
        return 'Not as Described';
      case ReturnReason.changedMind:
        return 'Changed Mind';
      case ReturnReason.damaged:
        return 'Damaged';
      case ReturnReason.expired:
        return 'Expired';
      case ReturnReason.other:
        return 'Other';
    }
  }
}

/// How the return was resolved
enum RefundType {
  cash,
  mobileMoney,
  storeCredit,
  exchange,
  noRefund,
}

extension RefundTypeExtension on RefundType {
  String get label {
    switch (this) {
      case RefundType.cash:
        return 'Cash Refund';
      case RefundType.mobileMoney:
        return 'Mobile Money';
      case RefundType.storeCredit:
        return 'Store Credit';
      case RefundType.exchange:
        return 'Exchange';
      case RefundType.noRefund:
        return 'No Refund';
    }
  }
}

/// Condition of the returned item
enum ReturnCondition {
  resellable,
  damaged,
  expired,
  forDisposal,
}

extension ReturnConditionExtension on ReturnCondition {
  String get label {
    switch (this) {
      case ReturnCondition.resellable:
        return 'Good - Can Resell';
      case ReturnCondition.damaged:
        return 'Damaged';
      case ReturnCondition.expired:
        return 'Expired';
      case ReturnCondition.forDisposal:
        return 'For Disposal';
    }
  }

  bool get canRestock => this == ReturnCondition.resellable;
}

@collection
class ProductReturn {
  Id id = Isar.autoIncrement;

  // Link to original sale
  int saleId;
  String? receiptNumber;

  // Product info
  int productId;
  String productName;
  double quantity;
  String unit;
  double unitPrice;
  double costPrice; // Cost price for COGS calculation

  // Return details
  @Enumerated(EnumType.ordinal)
  ReturnReason reason;
  String? reasonNotes;

  @Enumerated(EnumType.ordinal)
  ReturnCondition condition;

  // Refund info
  @Enumerated(EnumType.ordinal)
  RefundType refundType;
  double refundAmount;
  bool isRestocked;

  // Metadata
  DateTime createdAt;
  String? processedBy;

  /// Remote ID in Supabase
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.ordinal)
  SyncStatus syncStatus;

  ProductReturn({
    required this.saleId,
    this.receiptNumber,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    this.costPrice = 0,
    required this.reason,
    this.reasonNotes,
    required this.condition,
    required this.refundType,
    required this.refundAmount,
    this.isRestocked = false,
    required this.createdAt,
    this.processedBy,
    this.remoteId,
    this.syncStatus = SyncStatus.pending,
  });

  /// Total cost of the returned items (for COGS adjustment)
  @ignore
  double get totalCost => quantity * costPrice;

  /// Total value of the return
  @ignore
  double get totalValue => quantity * unitPrice;

  /// Formatted quantity with unit
  @ignore
  String get formattedQuantity {
    if (quantity == quantity.toInt()) {
      return '${quantity.toInt()} $unit';
    }
    return '${quantity.toStringAsFixed(2)} $unit';
  }
}
