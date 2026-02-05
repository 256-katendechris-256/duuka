import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class CreditRepository {
  final Isar _isar = DatabaseService.instance;

  // ============== CREDIT TRANSACTIONS ==============

  /// Get all credit transactions
  Future<List<CreditTransaction>> getAllTransactions() async {
    return await _isar.creditTransactions
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get transaction by ID
  Future<CreditTransaction?> getTransactionById(int id) async {
    return await _isar.creditTransactions.get(id);
  }

  /// Get transactions for a customer
  Future<List<CreditTransaction>> getTransactionsForCustomer(int customerId) async {
    return await _isar.creditTransactions
        .filter()
        .customerIdEqualTo(customerId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get all credit sales (not hire purchase)
  Future<List<CreditTransaction>> getCreditSales() async {
    return await _isar.creditTransactions
        .filter()
        .typeEqualTo(CreditType.credit)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get all hire purchase transactions
  Future<List<CreditTransaction>> getHirePurchases() async {
    return await _isar.creditTransactions
        .filter()
        .typeEqualTo(CreditType.hirePurchase)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get outstanding credit sales (debtors)
  Future<List<CreditTransaction>> getOutstandingCreditSales() async {
    return await _isar.creditTransactions
        .filter()
        .typeEqualTo(CreditType.credit)
        .not()
        .statusEqualTo(CreditStatus.cleared)
        .sortByAgreedPaymentDate()
        .findAll();
  }

  /// Get outstanding hire purchases
  Future<List<CreditTransaction>> getOutstandingHirePurchases() async {
    return await _isar.creditTransactions
        .filter()
        .typeEqualTo(CreditType.hirePurchase)
        .not()
        .statusEqualTo(CreditStatus.cleared)
        .sortByAgreedPaymentDate()
        .findAll();
  }

  /// Get overdue transactions
  Future<List<CreditTransaction>> getOverdueTransactions() async {
    final now = DateTime.now();
    return await _isar.creditTransactions
        .filter()
        .not()
        .statusEqualTo(CreditStatus.cleared)
        .agreedPaymentDateLessThan(now)
        .sortByAgreedPaymentDate()
        .findAll();
  }

  /// Get hire purchases ready for collection (fully paid but not collected)
  Future<List<CreditTransaction>> getReadyForCollection() async {
    return await _isar.creditTransactions
        .filter()
        .typeEqualTo(CreditType.hirePurchase)
        .statusEqualTo(CreditStatus.cleared)
        .collectedAtIsNull()
        .sortByCreatedAt()
        .findAll();
  }

  /// Save transaction
  Future<int> saveTransaction(CreditTransaction transaction) async {
    final isNew = transaction.id == Isar.autoIncrement;

    if (isNew) {
      transaction.createdAt = DateTime.now();
    }
    transaction.updateStatus();
    transaction.syncStatus = SyncStatus.pending;

    return await _isar.writeTxn(() async {
      final savedId = await _isar.creditTransactions.put(transaction);

      // Queue for sync
      await _queueTransactionForSync(
        isNew ? SyncOperation.create : SyncOperation.update,
        savedId,
      );

      return savedId;
    });
  }

  /// Delete transaction
  Future<bool> deleteTransaction(int id) async {
    return await _isar.writeTxn(() async {
      // Also delete related payments
      await _isar.creditPayments
          .filter()
          .creditTransactionIdEqualTo(id)
          .deleteAll();
      return await _isar.creditTransactions.delete(id);
    });
  }

  /// Mark hire purchase as collected
  Future<void> markAsCollected(int transactionId) async {
    final transaction = await getTransactionById(transactionId);
    if (transaction != null && transaction.canCollect) {
      transaction.collectedAt = DateTime.now();
      await saveTransaction(transaction);
    }
  }

  // ============== PAYMENTS ==============

  /// Get all payments for a transaction
  Future<List<CreditPayment>> getPaymentsForTransaction(int transactionId) async {
    return await _isar.creditPayments
        .filter()
        .creditTransactionIdEqualTo(transactionId)
        .sortByPaidAtDesc()
        .findAll();
  }

  /// Record a payment
  Future<int> recordPayment(CreditPayment payment) async {
    payment.syncStatus = SyncStatus.pending;

    return await _isar.writeTxn(() async {
      // Save the payment
      final paymentId = await _isar.creditPayments.put(payment);

      // Queue payment for sync
      await _queuePaymentForSync(SyncOperation.create, paymentId);

      // Update the transaction
      final transaction = await _isar.creditTransactions.get(payment.creditTransactionId);
      if (transaction != null) {
        transaction.amountPaid += payment.amount;
        transaction.updateStatus();
        transaction.syncStatus = SyncStatus.pending;
        await _isar.creditTransactions.put(transaction);

        // Queue transaction update for sync
        await _queueTransactionForSync(SyncOperation.update, transaction.id);
      }

      return paymentId;
    });
  }

  /// Delete a payment and update transaction
  Future<bool> deletePayment(int paymentId) async {
    return await _isar.writeTxn(() async {
      final payment = await _isar.creditPayments.get(paymentId);
      if (payment == null) return false;

      // Update the transaction
      final transaction = await _isar.creditTransactions.get(payment.creditTransactionId);
      if (transaction != null) {
        transaction.amountPaid -= payment.amount;
        if (transaction.amountPaid < 0) transaction.amountPaid = 0;
        transaction.updateStatus();
        await _isar.creditTransactions.put(transaction);
      }

      // Delete the payment
      return await _isar.creditPayments.delete(paymentId);
    });
  }

  // ============== SUMMARIES ==============

  /// Get total outstanding credit (debtors owe you)
  Future<double> getTotalOutstandingCredit() async {
    final transactions = await getOutstandingCreditSales();
    return transactions.fold<double>(0, (sum, t) => sum + t.balance);
  }

  /// Get total outstanding hire purchase
  Future<double> getTotalOutstandingHirePurchase() async {
    final transactions = await getOutstandingHirePurchases();
    return transactions.fold<double>(0, (sum, t) => sum + t.balance);
  }

  /// Get total outstanding (all types)
  Future<double> getTotalOutstanding() async {
    final credit = await getTotalOutstandingCredit();
    final hp = await getTotalOutstandingHirePurchase();
    return credit + hp;
  }

  /// Get count of overdue transactions
  Future<int> getOverdueCount() async {
    final transactions = await getOverdueTransactions();
    return transactions.length;
  }

  /// Get customer's total outstanding balance
  Future<double> getCustomerBalance(int customerId) async {
    final transactions = await _isar.creditTransactions
        .filter()
        .customerIdEqualTo(customerId)
        .not()
        .statusEqualTo(CreditStatus.cleared)
        .findAll();
    return transactions.fold<double>(0, (sum, t) => sum + t.balance);
  }

  /// Get summary stats
  Future<CreditSummary> getSummary() async {
    final allTransactions = await getAllTransactions();
    final outstanding = allTransactions.where((t) => !t.isCleared).toList();
    final overdue = outstanding.where((t) => t.isOverdue).toList();
    final creditSales = outstanding.where((t) => t.type == CreditType.credit).toList();
    final hirePurchases = outstanding.where((t) => t.type == CreditType.hirePurchase).toList();
    final readyForCollection = await getReadyForCollection();

    return CreditSummary(
      totalOutstanding: outstanding.fold<double>(0, (sum, t) => sum + t.balance),
      totalCreditSalesOutstanding: creditSales.fold<double>(0, (sum, t) => sum + t.balance),
      totalHirePurchaseOutstanding: hirePurchases.fold<double>(0, (sum, t) => sum + t.balance),
      overdueCount: overdue.length,
      overdueAmount: overdue.fold<double>(0, (sum, t) => sum + t.balance),
      creditSalesCount: creditSales.length,
      hirePurchaseCount: hirePurchases.length,
      readyForCollectionCount: readyForCollection.length,
    );
  }

  /// Queue credit transaction for sync
  Future<void> _queueTransactionForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'credit_transactions'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }

  /// Queue credit payment for sync
  Future<void> _queuePaymentForSync(SyncOperation operation, int localId) async {
    final syncQueue = SyncQueue()
      ..operation = operation
      ..collectionName = 'credit_payments'
      ..localId = localId
      ..status = SyncQueueStatus.pending
      ..createdAt = DateTime.now();

    await _isar.syncQueues.put(syncQueue);
  }
}

/// Summary of credit status
class CreditSummary {
  final double totalOutstanding;
  final double totalCreditSalesOutstanding;
  final double totalHirePurchaseOutstanding;
  final int overdueCount;
  final double overdueAmount;
  final int creditSalesCount;
  final int hirePurchaseCount;
  final int readyForCollectionCount;

  CreditSummary({
    required this.totalOutstanding,
    required this.totalCreditSalesOutstanding,
    required this.totalHirePurchaseOutstanding,
    required this.overdueCount,
    required this.overdueAmount,
    required this.creditSalesCount,
    required this.hirePurchaseCount,
    required this.readyForCollectionCount,
  });
}
