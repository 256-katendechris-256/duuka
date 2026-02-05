import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/sale_repository.dart';
import 'return_provider.dart';
import 'product_provider.dart';
import 'report_provider.dart';

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

// Sale by ID Provider
@riverpod
Future<Sale?> saleById(SaleByIdRef ref, int id) async {
  try {
    return await ref.read(saleRepositoryProvider).getById(id);
  } catch (e) {
    return null;
  }
}

// Today Stats Class
class TodayStats {
  final double total;
  final double cashAtHand;  // Actual money received (cash + mobile + credit deposits)
  final double creditOutstanding;  // Unpaid credit balance
  final int count;
  final double profit;
  final double yesterdayTotal;
  final double yesterdayCashAtHand;
  final double refunded;

  const TodayStats({
    required this.total,
    required this.cashAtHand,
    required this.creditOutstanding,
    required this.count,
    required this.profit,
    required this.yesterdayTotal,
    required this.yesterdayCashAtHand,
    this.refunded = 0,
  });

  /// Net total after deducting refunds
  double get netTotal => total - refunded;

  /// Net cash at hand after deducting refunds
  double get netCashAtHand => cashAtHand - refunded;

  /// Net profit after deducting refunds
  double get netProfit => profit - refunded;

  /// Calculate percentage change compared to yesterday (based on cash at hand)
  double get percentageChange {
    if (yesterdayCashAtHand == 0) {
      return netCashAtHand > 0 ? 100.0 : 0.0;
    }
    return ((netCashAtHand - yesterdayCashAtHand) / yesterdayCashAtHand) * 100;
  }

  /// Whether cash at hand is up compared to yesterday
  bool get isUp => percentageChange >= 0;

  TodayStats copyWith({
    double? total,
    double? cashAtHand,
    double? creditOutstanding,
    int? count,
    double? profit,
    double? yesterdayTotal,
    double? yesterdayCashAtHand,
    double? refunded,
  }) {
    return TodayStats(
      total: total ?? this.total,
      cashAtHand: cashAtHand ?? this.cashAtHand,
      creditOutstanding: creditOutstanding ?? this.creditOutstanding,
      count: count ?? this.count,
      profit: profit ?? this.profit,
      yesterdayTotal: yesterdayTotal ?? this.yesterdayTotal,
      yesterdayCashAtHand: yesterdayCashAtHand ?? this.yesterdayCashAtHand,
      refunded: refunded ?? this.refunded,
    );
  }
}

// Today Stats Provider
@riverpod
Future<TodayStats> todayStats(TodayStatsRef ref) async {
  try {
    final repository = ref.read(saleRepositoryProvider);

    final total = await repository.getTodayTotal();
    final cashAtHand = await repository.getTodayCashAtHand();
    final creditOutstanding = await repository.getTodayCreditTotal();
    final count = await repository.getTodayCount();
    final profit = await repository.getTodayProfit();

    // Get today's refunds from return repository
    final returnRepository = ref.read(returnRepositoryProvider);
    final todayRefunded = await returnRepository.getTodayRefundTotal();

    // Calculate yesterday's totals
    final now = DateTime.now();
    final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
    final yesterdayEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
    final yesterdaySales = await repository.getByDateRange(yesterdayStart, yesterdayEnd);
    final yesterdayTotal = yesterdaySales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    // Calculate yesterday's cash at hand (only fully paid sales)
    final yesterdayCashAtHand = yesterdaySales.fold<double>(0.0, (sum, sale) {
      if (sale.paymentMethod == PaymentMethod.credit) {
        // Only count credit sales that are fully paid
        if (sale.paymentStatus == PaymentStatus.paid) {
          return sum + sale.total;
        }
        return sum;
      }
      return sum + sale.total;
    });

    return TodayStats(
      total: total,
      cashAtHand: cashAtHand,
      creditOutstanding: creditOutstanding,
      count: count,
      profit: profit,
      yesterdayTotal: yesterdayTotal,
      yesterdayCashAtHand: yesterdayCashAtHand,
      refunded: todayRefunded,
    );
  } catch (e) {
    return const TodayStats(
      total: 0,
      cashAtHand: 0,
      creditOutstanding: 0,
      count: 0,
      profit: 0,
      yesterdayTotal: 0,
      yesterdayCashAtHand: 0,
    );
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

// Cart Item Specification (for passing specs to cart)
class CartItemSpecification {
  final String name;
  final String value;

  const CartItemSpecification({required this.name, required this.value});
}

// Cart Item Class
class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final double costPrice;
  double quantity;  // Now double to support measurable products
  final String unit;
  final bool isMeasurable;
  final List<CartItemSpecification> specifications;
  final double stockQuantity; // Available stock when item was added

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.costPrice,
    this.quantity = 1,
    this.unit = 'pcs',
    this.isMeasurable = false,
    this.specifications = const [],
    this.stockQuantity = double.infinity, // Default to unlimited for backwards compatibility
  });

  /// Check if can increase quantity
  bool get canIncrease => quantity < stockQuantity;

  /// Remaining stock that can be added
  double get remainingStock => stockQuantity - quantity;

  double get total => unitPrice * quantity;
  double get profit => (unitPrice - costPrice) * quantity;

  /// Format quantity for display
  String get formattedQuantity {
    if (isMeasurable) {
      return '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} $unit';
    } else {
      return '${quantity.toInt()} $unit';
    }
  }

  /// Get specifications as formatted string
  String get specificationsText {
    if (specifications.isEmpty) return '';
    return specifications.map((s) => '${s.name}: ${s.value}').join(', ');
  }

  /// Check if has specifications
  bool get hasSpecifications => specifications.isNotEmpty;

  CartItem copyWith({
    int? productId,
    String? productName,
    double? unitPrice,
    double? costPrice,
    double? quantity,
    String? unit,
    bool? isMeasurable,
    List<CartItemSpecification>? specifications,
    double? stockQuantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isMeasurable: isMeasurable ?? this.isMeasurable,
      specifications: specifications ?? this.specifications,
      stockQuantity: stockQuantity ?? this.stockQuantity,
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
  int get itemCount => items.length;  // Number of distinct items
  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

// Cart Provider
@riverpod
class Cart extends _$Cart {
  @override
  CartState build() => const CartState();

  void addItem(Product product, {double quantity = 1, List<CartItemSpecification>? specifications}) {
    final items = List<CartItem>.from(state.items);
    final availableStock = product.safeStockQuantity;

    // Convert product specifications to cart specifications if not provided
    final specs = specifications ?? product.specifications
        .map((s) => CartItemSpecification(name: s.name, value: s.value))
        .toList();

    // Check if product already in cart (with same specifications)
    final existingIndex = items.indexWhere((item) =>
        item.productId == product.id &&
        _specificationsMatch(item.specifications, specs));

    if (existingIndex >= 0) {
      // Check if new total would exceed stock
      final newQuantity = items[existingIndex].quantity + quantity;
      if (newQuantity > availableStock) {
        // Don't add more than available
        return;
      }
      // Update quantity
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: newQuantity,
      );
    } else {
      // Check stock before adding
      if (quantity > availableStock) {
        // Don't add more than available
        return;
      }
      // Add new item
      items.add(CartItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.sellPrice,
        costPrice: product.costPrice,
        quantity: quantity,
        unit: product.displayUnit,
        isMeasurable: product.isMeasurable,
        specifications: specs,
        stockQuantity: availableStock,
      ));
    }

    state = state.copyWith(items: items);
  }

  /// Check if two specification lists match
  bool _specificationsMatch(List<CartItemSpecification> a, List<CartItemSpecification> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name || a[i].value != b[i].value) return false;
    }
    return true;
  }

  void removeItem(int productId) {
    final items = state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: items);
  }

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final items = state.items.map((item) {
      if (item.productId == productId) {
        // Don't allow quantity to exceed available stock
        final newQuantity = quantity > item.stockQuantity
            ? item.stockQuantity
            : quantity;
        return item.copyWith(quantity: newQuantity);
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
    String? customerName,
  }) async {
    if (state.isEmpty) {
      print('🛒 Checkout failed: Cart is empty');
      return null;
    }

    try {
      print('🛒 Generating receipt number...');
      // Generate receipt number
      final receiptNumber = await ref.read(saleRepositoryProvider).generateReceiptNumber();
      print('🧾 Receipt number: $receiptNumber');

      // Create sale items from ALL cart items
      print('📦 Creating sale items from ${state.items.length} cart items:');
      final saleItems = <SaleItem>[];
      for (var i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        print('   [$i] ${item.productName} x${item.quantity} ${item.unit} @ ${item.unitPrice}');
        if (item.hasSpecifications) {
          print('       Specs: ${item.specificationsText}');
        }

        // Convert cart specifications to sale item specifications
        final saleSpecs = item.specifications
            .map((s) => SaleItemSpecification.create(name: s.name, value: s.value))
            .toList();

        saleItems.add(SaleItem()
          ..productId = item.productId
          ..productName = item.productName
          ..quantity = item.quantity
          ..unitPrice = item.unitPrice
          ..costPrice = item.costPrice
          ..total = item.total
          ..unit = item.unit
          ..isMeasurable = item.isMeasurable
          ..specifications = saleSpecs);
      }
      print('📦 Total sale items created: ${saleItems.length}');

      // Determine payment status
      PaymentStatus paymentStatus;
      double balance = 0;
      double paidAmount;

      if (paymentMethod == PaymentMethod.credit) {
        // For credit sales, amountPaid represents the initial deposit
        paidAmount = amountPaid ?? 0;
        balance = state.total - paidAmount;
        
        if (paidAmount >= state.total) {
          // Fully paid upfront (rare but possible)
          paymentStatus = PaymentStatus.paid;
          balance = 0;
        } else if (paidAmount > 0) {
          // Partial payment (initial deposit)
          paymentStatus = PaymentStatus.partial;
        } else {
          // No initial payment
          paymentStatus = PaymentStatus.unpaid;
        }
      } else if ((amountPaid ?? state.total) >= state.total) {
        paidAmount = amountPaid ?? state.total;
        paymentStatus = PaymentStatus.paid;
      } else {
        paidAmount = amountPaid ?? state.total;
        paymentStatus = PaymentStatus.partial;
        balance = state.total - paidAmount;
      }

      print('💰 Payment: ${paymentMethod.name}, Status: ${paymentStatus.name}, Amount: $paidAmount');

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
        ..customerName = customerName ?? state.customerName
        ..userId = 1 // TODO: Get from auth
        ..userName = 'Owner' // TODO: Get from auth
        ..notes = notes
        ..syncStatus = SyncStatus.pending
        ..createdAt = DateTime.now();

      print('💾 Saving sale to database...');
      // Save sale
      final id = await ref.read(saleRepositoryProvider).save(sale);
      sale.id = id;
      print('✅ Sale saved with ID: $id');

      // Refresh all related providers for automatic UI updates
      _invalidateAllSaleRelated();

      // Clear cart
      clear();
      print('🧹 Cart cleared');

      return sale;
    } catch (e) {
      print('💥 Checkout error: $e');
      return null;
    }
  }

  /// Invalidate all sale-related providers to trigger automatic UI updates
  void _invalidateAllSaleRelated() {
    // Sales
    ref.invalidate(salesProvider);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(todayStatsProvider);
    
    // Products (stock changed)
    ref.invalidate(productsProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(productCategoriesProvider);
    
    // Reports
    ref.invalidate(reportSummaryProvider);
    ref.invalidate(periodTotalsProvider);
    ref.invalidate(dailySalesChartProvider);
    ref.invalidate(paymentBreakdownProvider);
    ref.invalidate(topProductsProvider);
  }
}
