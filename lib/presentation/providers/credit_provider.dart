import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/repositories/credit_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';
import 'sale_provider.dart';
import 'customer_provider.dart';
import 'report_provider.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepository();
});

/// Credit summary provider
final creditSummaryProvider = FutureProvider<CreditSummary>((ref) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getSummary();
});

/// Outstanding credit sales (debtors)
final outstandingCreditSalesProvider = FutureProvider<List<CreditTransaction>>((ref) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getOutstandingCreditSales();
});

/// Outstanding hire purchases
final outstandingHirePurchasesProvider = FutureProvider<List<CreditTransaction>>((ref) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getOutstandingHirePurchases();
});

/// Overdue transactions
final overdueTransactionsProvider = FutureProvider<List<CreditTransaction>>((ref) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getOverdueTransactions();
});

/// Ready for collection (hire purchase)
final readyForCollectionProvider = FutureProvider<List<CreditTransaction>>((ref) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getReadyForCollection();
});

/// Transactions for a specific customer
final customerTransactionsProvider = FutureProvider.family<List<CreditTransaction>, int>((ref, customerId) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getTransactionsForCustomer(customerId);
});

/// Customer balance provider
final customerBalanceProvider = FutureProvider.family<double, int>((ref, customerId) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getCustomerBalance(customerId);
});

/// Payments for a transaction
final transactionPaymentsProvider = FutureProvider.family<List<CreditPayment>, int>((ref, transactionId) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getPaymentsForTransaction(transactionId);
});

/// Single transaction provider
final creditTransactionProvider = FutureProvider.family<CreditTransaction?, int>((ref, id) async {
  final repository = ref.watch(creditRepositoryProvider);
  return await repository.getTransactionById(id);
});

/// Credit management notifier
class CreditNotifier extends StateNotifier<AsyncValue<CreditSummary>> {
  final CreditRepository _creditRepo;
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final Ref _ref;

  CreditNotifier(this._creditRepo, this._customerRepo, this._productRepo, this._ref)
      : super(const AsyncValue.loading()) {
    loadSummary();
  }

  Future<void> loadSummary() async {
    state = const AsyncValue.loading();
    try {
      final summary = await _creditRepo.getSummary();
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a credit sale transaction
  Future<CreditTransaction?> createCreditSale({
    required int customerId,
    required String customerName,
    required String customerPhone,
    required int saleId,
    required double totalAmount,
    required DateTime agreedPaymentDate,
    double initialPayment = 0,
    String? notes,
  }) async {
    try {
      final transaction = CreditTransaction.createCredit(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        saleId: saleId,
        totalAmount: totalAmount,
        agreedPaymentDate: agreedPaymentDate,
        amountPaid: initialPayment,
        notes: notes,
      );

      final id = await _creditRepo.saveTransaction(transaction);
      transaction.id = id;

      // Update customer stats
      await _customerRepo.updatePurchaseStats(customerId, totalAmount);

      await _invalidateAll();
      return transaction;
    } catch (e) {
      print('Error creating credit sale: $e');
      return null;
    }
  }

  /// Create a hire purchase transaction
  Future<CreditTransaction?> createHirePurchase({
    required int customerId,
    required String customerName,
    required String customerPhone,
    required int productId,
    required String productName,
    required int quantity,
    required double totalAmount,
    required DateTime agreedPaymentDate,
    double initialPayment = 0,
    String? notes,
  }) async {
    try {
      final transaction = CreditTransaction.createHirePurchase(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        productId: productId,
        productName: productName,
        productQuantity: quantity,
        totalAmount: totalAmount,
        agreedPaymentDate: agreedPaymentDate,
        amountPaid: initialPayment,
        notes: notes,
      );

      final id = await _creditRepo.saveTransaction(transaction);
      transaction.id = id;

      // Reserve the product (reduce available stock)
      // Note: For hire purchase, the stock is reserved but not "sold" until collected
      // You might want to track reserved stock separately

      await _invalidateAll();
      return transaction;
    } catch (e) {
      print('Error creating hire purchase: $e');
      return null;
    }
  }

  /// Record a payment
  Future<bool> recordPayment({
    required int transactionId,
    required double amount,
    required String paymentMethod,
    String? notes,
    String? receiptNumber,
  }) async {
    try {
      final payment = CreditPayment.create(
        creditTransactionId: transactionId,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
        receiptNumber: receiptNumber,
      );

      await _creditRepo.recordPayment(payment);
      
      // Check if transaction is now cleared and update the associated sale
      final transaction = await _creditRepo.getTransactionById(transactionId);
      if (transaction != null && transaction.saleId != null) {
        // Update the sale's payment status
        await _updateSalePaymentStatus(transaction.saleId!, transaction.amountPaid, transaction.isCleared);
      }
      
      await _invalidateAll();
      _ref.invalidate(creditTransactionProvider(transactionId));
      _ref.invalidate(transactionPaymentsProvider(transactionId));
      return true;
    } catch (e) {
      print('Error recording payment: $e');
      return false;
    }
  }
  
  /// Update the sale's payment status when credit is paid
  Future<void> _updateSalePaymentStatus(int saleId, double amountPaid, bool isCleared) async {
    try {
      final saleRepo = SaleRepository();
      final sale = await saleRepo.getById(saleId);
      if (sale != null) {
        sale.amountPaid = amountPaid;
        sale.balance = sale.total - amountPaid;
        if (isCleared || sale.balance <= 0) {
          sale.paymentStatus = PaymentStatus.paid;
          sale.balance = 0;
        } else if (amountPaid > 0) {
          sale.paymentStatus = PaymentStatus.partial;
        }
        await saleRepo.save(sale);
        print('✅ Updated sale ${sale.receiptNumber} status to ${sale.paymentStatus}');
      }
    } catch (e) {
      print('Error updating sale payment status: $e');
    }
  }

  /// Mark hire purchase as collected
  Future<bool> markAsCollected(int transactionId) async {
    try {
      final transaction = await _creditRepo.getTransactionById(transactionId);
      if (transaction == null || !transaction.canCollect) {
        return false;
      }

      await _creditRepo.markAsCollected(transactionId);

      // Now actually deduct the stock since item is being taken
      if (transaction.productId != null && transaction.productQuantity != null) {
        final product = await _productRepo.getById(transaction.productId!);
        if (product != null) {
          product.stockQuantity -= transaction.productQuantity!;
          if (product.stockQuantity < 0) product.stockQuantity = 0;
          await _productRepo.save(product);
        }
      }

      await _invalidateAll();
      _ref.invalidate(creditTransactionProvider(transactionId));
      return true;
    } catch (e) {
      print('Error marking as collected: $e');
      return false;
    }
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      await _creditRepo.deleteTransaction(id);
      await _invalidateAll();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _invalidateAll() async {
    await loadSummary();
    
    // Credit
    _ref.invalidate(outstandingCreditSalesProvider);
    _ref.invalidate(outstandingHirePurchasesProvider);
    _ref.invalidate(overdueTransactionsProvider);
    _ref.invalidate(readyForCollectionProvider);
    _ref.invalidate(creditSummaryProvider);
    
    // Sales
    _ref.invalidate(salesProvider);
    _ref.invalidate(todaySalesProvider);
    _ref.invalidate(todayStatsProvider);
    
    // Customers
    _ref.invalidate(customersProvider);
    _ref.invalidate(customerNotifierProvider);
    
    // Reports
    _ref.invalidate(reportSummaryProvider);
    _ref.invalidate(periodTotalsProvider);
    _ref.invalidate(paymentBreakdownProvider);
  }
}

final creditNotifierProvider = StateNotifierProvider<CreditNotifier, AsyncValue<CreditSummary>>((ref) {
  final creditRepo = ref.watch(creditRepositoryProvider);
  final customerRepo = CustomerRepository();
  final productRepo = ProductRepository();
  return CreditNotifier(creditRepo, customerRepo, productRepo, ref);
});
