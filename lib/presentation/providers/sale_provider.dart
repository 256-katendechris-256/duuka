import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/sale_repository.dart';

part 'sale_provider.g.dart';

// Repository Provider
@riverpod
SaleRepository saleRepository(SaleRepositoryRef ref) {
  return SaleRepository();
}

// Sales Provider
@riverpod
class Sales extends _$Sales {
  @override
  Future<List<Sale>> build() async {
    return await _loadSales();
  }

  Future<List<Sale>> _loadSales() async {
    try {
      return await ref.read(saleRepositoryProvider).getAll();
    } catch (e) {
      throw Exception('Failed to load sales: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadSales());
  }
}

// Today's Sales Provider
@riverpod
Future<List<Sale>> todaySales(TodaySalesRef ref) async {
  try {
    return await ref.read(saleRepositoryProvider).getToday();
  } catch (e) {
    return [];
  }
}

// Recent Sales Provider
@riverpod
Future<List<Sale>> recentSales(RecentSalesRef ref, {int limit = 10}) async {
  try {
    return await ref.read(saleRepositoryProvider).getRecentSales(limit);
  } catch (e) {
    return [];
  }
}

// Today Stats Class
class TodayStats {
  final double total;
  final int count;
  final double profit;

  const TodayStats({
    required this.total,
    required this.count,
    required this.profit,
  });

  TodayStats copyWith({
    double? total,
    int? count,
    double? profit,
  }) {
    return TodayStats(
      total: total ?? this.total,
      count: count ?? this.count,
      profit: profit ?? this.profit,
    );
  }
}

// Today Stats Provider
@riverpod
Future<TodayStats> todayStats(TodayStatsRef ref) async {
  try {
    final repository = ref.read(saleRepositoryProvider);

    final total = await repository.getTodayTotal();
    final count = await repository.getTodayCount();
    final profit = await repository.getTodayProfit();

    return TodayStats(total: total, count: count, profit: profit);
  } catch (e) {
    return const TodayStats(total: 0, count: 0, profit: 0);
  }
}

// Weekly Sales Provider
@riverpod
Future<List<DailySales>> weeklySales(WeeklySalesRef ref) async {
  try {
    return await ref.read(saleRepositoryProvider).getWeekSales();
  } catch (e) {
    return [];
  }
}

// ============================================================================
// CART MANAGEMENT
// ============================================================================

// Cart Item Class
class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final double costPrice;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.costPrice,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;
  double get profit => (unitPrice - costPrice) * quantity;

  CartItem copyWith({
    int? productId,
    String? productName,
    double? unitPrice,
    double? costPrice,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Cart State
class CartState {
  final List<CartItem> items;
  final int? customerId;
  final String? customerName;
  final double discount;
  final double discountPercent;

  const CartState({
    this.items = const [],
    this.customerId,
    this.customerName,
    this.discount = 0,
    this.discountPercent = 0,
  });

  CartState copyWith({
    List<CartItem>? items,
    int? customerId,
    String? customerName,
    double? discount,
    double? discountPercent,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      discount: discount ?? this.discount,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get discountAmount => discountPercent > 0
      ? subtotal * (discountPercent / 100)
      : discount;
  double get total => subtotal - discountAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

// Cart Provider
@riverpod
class Cart extends _$Cart {
  @override
  CartState build() => const CartState();

  void addItem(Product product, {int quantity = 1}) {
    final items = List<CartItem>.from(state.items);

    // Check if product already in cart
    final existingIndex = items.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      // Update quantity
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + quantity,
      );
    } else {
      // Add new item
      items.add(CartItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.sellPrice,
        costPrice: product.costPrice,
        quantity: quantity,
      ));
    }

    state = state.copyWith(items: items);
  }

  void removeItem(int productId) {
    final items = state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: items);
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final items = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
  }

  void updatePrice(int productId, double price) {
    final items = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(unitPrice: price);
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
  }

  void setCustomer(int customerId, String customerName) {
    state = state.copyWith(
      customerId: customerId,
      customerName: customerName,
    );
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void setDiscount(double amount) {
    state = state.copyWith(discount: amount, discountPercent: 0);
  }

  void setDiscountPercent(double percent) {
    state = state.copyWith(discountPercent: percent, discount: 0);
  }

  void clear() {
    state = const CartState();
  }

  Future<Sale?> checkout({
    required PaymentMethod paymentMethod,
    double? amountPaid,
    String? notes,
  }) async {
    if (state.isEmpty) return null;

    try {
      // Generate receipt number
      final receiptNumber = await ref.read(saleRepositoryProvider).generateReceiptNumber();

      // Create sale items
      final saleItems = state.items
          .map((item) => SaleItem()
            ..productId = item.productId
            ..productName = item.productName
            ..quantity = item.quantity
            ..unitPrice = item.unitPrice
            ..costPrice = item.costPrice
            ..total = item.total)
          .toList();

      // Determine payment status
      final paidAmount = amountPaid ?? state.total;
      PaymentStatus paymentStatus;
      double balance = 0;

      if (paymentMethod == PaymentMethod.credit) {
        paymentStatus = PaymentStatus.unpaid;
        balance = state.total;
      } else if (paidAmount >= state.total) {
        paymentStatus = PaymentStatus.paid;
      } else {
        paymentStatus = PaymentStatus.partial;
        balance = state.total - paidAmount;
      }

      // Create sale
      final sale = Sale()
        ..receiptNumber = receiptNumber
        ..items = saleItems
        ..subtotal = state.subtotal
        ..discount = state.discountAmount
        ..discountPercent = state.discountPercent
        ..total = state.total
        ..paymentMethod = paymentMethod
        ..paymentStatus = paymentStatus
        ..amountPaid = paidAmount
        ..balance = balance
        ..customerId = state.customerId
        ..customerName = state.customerName
        ..userId = 1 // TODO: Get from auth
        ..userName = 'Owner' // TODO: Get from auth
        ..notes = notes
        ..syncStatus = SyncStatus.pending
        ..createdAt = DateTime.now();

      // Save sale
      final id = await ref.read(saleRepositoryProvider).save(sale);
      sale.id = id;

      // Refresh sales list
      ref.invalidate(salesProvider);
      ref.invalidate(todaySalesProvider);
      ref.invalidate(todayStatsProvider);

      // Clear cart
      clear();

      return sale;
    } catch (e) {
      return null;
    }
  }
}
