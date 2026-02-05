import 'package:isar/isar.dart';

import 'product.dart' show SyncStatus;

part 'credit_payment.g.dart';

@collection
class CreditPayment {
  Id id = Isar.autoIncrement;

  /// Link to credit transaction
  @Index()
  late int creditTransactionId;

  /// Amount paid
  late double amount;

  /// When payment was made
  @Index()
  late DateTime paidAt;

  /// Payment method used
  late String paymentMethod;

  /// Optional notes/reference
  String? notes;

  /// Receipt/reference number
  String? receiptNumber;

  /// Remote ID in Supabase
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  CreditPayment();

  CreditPayment.create({
    required this.creditTransactionId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    this.receiptNumber,
  }) : paidAt = DateTime.now();

  @override
  String toString() => 
      'CreditPayment(id: $id, txnId: $creditTransactionId, amount: $amount)';
}
