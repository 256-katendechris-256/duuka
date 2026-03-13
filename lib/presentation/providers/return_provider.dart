import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/database_service.dart';
import '../../data/models/product_return.dart';
import '../../data/repositories/return_repository.dart';
import 'product_provider.dart';
import 'sale_provider.dart';
import 'report_provider.dart';
import 'sync_provider.dart';

/// Repository provider
final returnRepositoryProvider = Provider<ReturnRepository>((ref) {
  return ReturnRepository(DatabaseService.instance);
});

/// All returns provider
final returnsProvider = FutureProvider<List<ProductReturn>>((ref) async {
  final repository = ref.watch(returnRepositoryProvider);
  return await repository.getAll();
});

/// Returns for a specific sale
final saleReturnsProvider = FutureProvider.family<List<ProductReturn>, int>((ref, saleId) async {
  final repository = ref.watch(returnRepositoryProvider);
  return await repository.getBySale(saleId);
});

/// Get returned quantity for a specific item in a sale
final returnedQuantityProvider = FutureProvider.family<double, ({int saleId, int productId})>((ref, params) async {
  final repository = ref.watch(returnRepositoryProvider);
  return await repository.getReturnedQuantity(params.saleId, params.productId);
});

/// Today's refund total
final todayRefundTotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(returnRepositoryProvider);
  return await repository.getTodayRefundTotal();
});

/// Returns notifier for mutations
class ReturnsNotifier extends Notifier<AsyncValue<List<ProductReturn>>> {
  @override
  AsyncValue<List<ProductReturn>> build() {
    _loadReturns();
    return const AsyncValue.loading();
  }

  Future<void> _loadReturns() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(returnRepositoryProvider);
      final returns = await repository.getAll();
      state = AsyncValue.data(returns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadReturns();
    _invalidateAll();
  }

  /// Process a return from a sale
  Future<bool> processReturn({
    required int saleId,
    String? receiptNumber,
    required int productId,
    required String productName,
    required double quantity,
    required String unit,
    required double unitPrice,
    double costPrice = 0,
    required ReturnReason reason,
    String? reasonNotes,
    required ReturnCondition condition,
    required RefundType refundType,
    required double refundAmount,
  }) async {
    try {
      final repository = ref.read(returnRepositoryProvider);
      
      final productReturn = ProductReturn(
        saleId: saleId,
        receiptNumber: receiptNumber,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        costPrice: costPrice,
        reason: reason,
        reasonNotes: reasonNotes,
        condition: condition,
        refundType: refundType,
        refundAmount: refundAmount,
        createdAt: DateTime.now(),
      );

      // Save return and restock if condition allows
      await repository.save(productReturn, restock: condition.canRestock);
      
      // Refresh data
      await refresh();
      
      // Also refresh products if restocked
      if (condition.canRestock) {
        ref.invalidate(productsProvider);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  void _invalidateAll() {
    // Returns
    ref.invalidate(returnsProvider);
    ref.invalidate(todayRefundTotalProvider);
    
    // Sales
    ref.invalidate(todayStatsProvider);
    ref.invalidate(salesProvider);
    ref.invalidate(todaySalesProvider);
    
    // Products (if restocked)
    ref.invalidate(productsProvider);
    ref.invalidate(lowStockProductsProvider);
    
    // Reports
    ref.invalidate(reportSummaryProvider);
    ref.invalidate(periodTotalsProvider);
    ref.invalidate(dailySalesChartProvider);

    // Trigger sync
    Future.delayed(const Duration(seconds: 1), () {
      try {
        ref.read(syncProvider.notifier).refresh();
        ref.read(syncProvider.notifier).sync();
      } catch (_) {}
    });
  }
}

final returnsNotifierProvider =
    NotifierProvider<ReturnsNotifier, AsyncValue<List<ProductReturn>>>(
  ReturnsNotifier.new,
);
