import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/models/expense.dart';
import '../../data/models/product_return.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/credit_repository.dart';
import '../../data/repositories/return_repository.dart';
import '../../data/datasources/local/database_service.dart';

// ============================================================================
// HELPERS: Realized revenue/profit (excludes unpaid credit)
// ============================================================================

/// Calculate realized revenue: cash/mobile in full, credit only when paid
double _realizedRevenue(List<Sale> sales) {
  return sales.fold<double>(0, (sum, sale) {
    if (sale.paymentMethod == PaymentMethod.credit) {
      if (sale.paymentStatus == PaymentStatus.paid) return sum + sale.total;
      return sum + sale.amountPaid; // Partial: only count what's been paid
    }
    return sum + sale.total;
  });
}

/// Calculate realized profit: proportional to amount paid for credit sales
double _realizedProfit(List<Sale> sales) {
  return sales.fold<double>(0, (sum, sale) {
    if (sale.paymentMethod == PaymentMethod.credit) {
      if (sale.paymentStatus == PaymentStatus.paid) return sum + sale.totalProfit;
      if (sale.amountPaid > 0 && sale.total > 0) {
        return sum + (sale.totalProfit * (sale.amountPaid / sale.total));
      }
      return sum;
    }
    return sum + sale.totalProfit;
  });
}

/// Calculate realized cost of goods sold
double _realizedCost(List<Sale> sales) {
  return sales.fold<double>(0, (sum, sale) {
    final cost = sale.total - sale.totalProfit;
    if (sale.paymentMethod == PaymentMethod.credit) {
      if (sale.paymentStatus == PaymentStatus.paid) return sum + cost;
      if (sale.amountPaid > 0 && sale.total > 0) {
        return sum + (cost * (sale.amountPaid / sale.total));
      }
      return sum;
    }
    return sum + cost;
  });
}

// ============================================================================
// REPORT DATA CLASSES
// ============================================================================

/// Summary of all key metrics for the reports dashboard
class ReportSummary {
  final double todayGrossSales;
  final double weekGrossSales;
  final double monthGrossSales;
  final double todayRefunds;
  final double weekRefunds;
  final double monthRefunds;
  final double todayProfit;
  final double weekProfit;
  final double monthProfit;
  final double todayExpenses;
  final double monthExpenses;
  final double outstandingCredit;
  final int overdueCount;
  final double inventoryValue;
  final int lowStockCount;

  const ReportSummary({
    required this.todayGrossSales,
    required this.weekGrossSales,
    required this.monthGrossSales,
    this.todayRefunds = 0,
    this.weekRefunds = 0,
    this.monthRefunds = 0,
    required this.todayProfit,
    required this.weekProfit,
    required this.monthProfit,
    required this.todayExpenses,
    required this.monthExpenses,
    required this.outstandingCredit,
    required this.overdueCount,
    required this.inventoryValue,
    required this.lowStockCount,
  });

  // Net sales (after refunds)
  double get todaySales => todayGrossSales - todayRefunds;
  double get weekSales => weekGrossSales - weekRefunds;
  double get monthSales => monthGrossSales - monthRefunds;
  
  // Net profit (after refunds and expenses)
  double get todayNetProfit => todayProfit - todayRefunds - todayExpenses;
  double get monthNetProfit => monthProfit - monthRefunds - monthExpenses;
}

/// Sales breakdown by payment method
class PaymentMethodBreakdown {
  final double cash;
  final double mobileMoney;
  final double credit;
  final double total;

  const PaymentMethodBreakdown({
    required this.cash,
    required this.mobileMoney,
    required this.credit,
    required this.total,
  });

  double get cashPercent => total > 0 ? (cash / total) * 100 : 0;
  double get mobileMoneyPercent => total > 0 ? (mobileMoney / total) * 100 : 0;
  double get creditPercent => total > 0 ? (credit / total) * 100 : 0;
}

/// Daily sales data for charts
class DailySalesData {
  final DateTime date;
  final double sales;
  final double profit;
  final int count;

  const DailySalesData({
    required this.date,
    required this.sales,
    required this.profit,
    required this.count,
  });
}

/// Product sales performance
class ProductSalesData {
  final int productId;
  final String productName;
  final String category;
  final double quantitySold;  // Now double to support measurable products
  final double revenue;
  final double profit;

  const ProductSalesData({
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantitySold,
    required this.revenue,
    required this.profit,
  });
}

/// Date range for filtering reports
enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.custom:
        return 'Custom';
    }
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: lastMonth, end: endOfLastMonth);
      case ReportPeriod.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.custom:
        // Default to this month for custom
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Selected report period provider
final selectedReportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.thisMonth;
});

/// Custom date range provider (for custom period)
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  return null;
});

/// Get the active date range based on selected period
final activeDateRangeProvider = Provider<DateTimeRange>((ref) {
  final period = ref.watch(selectedReportPeriodProvider);
  if (period == ReportPeriod.custom) {
    final customRange = ref.watch(customDateRangeProvider);
    if (customRange != null) return customRange;
  }
  return period.dateRange;
});

/// Report summary provider - aggregates all key metrics
final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  try {
    final saleRepo = SaleRepository();
    final productRepo = ProductRepository();
    final expenseRepo = ExpenseRepository();
    final creditRepo = CreditRepository();
    final returnRepo = ReturnRepository(DatabaseService.instance);

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Get sales data
    final todaySales = await saleRepo.getByDateRange(startOfToday, endOfToday);
    final weekSales = await saleRepo.getByDateRange(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endOfToday,
    );
    final monthSales = await saleRepo.getByDateRange(startOfMonth, endOfToday);

    // Calculate realized totals (exclude unpaid credit)
    final todayGrossTotal = _realizedRevenue(todaySales);
    final weekGrossTotal = _realizedRevenue(weekSales);
    final monthGrossTotal = _realizedRevenue(monthSales);

    final todayProfit = _realizedProfit(todaySales);
    final weekProfit = _realizedProfit(weekSales);
    final monthProfit = _realizedProfit(monthSales);

    // Get returns/refunds for each period (with error handling)
    List<ProductReturn> allReturns = [];
    try {
      allReturns = await returnRepo.getAll();
    } catch (e) {
      // If returns fail to load, continue with empty list
    }
    
    final todayRefunds = allReturns
        .where((r) => r.createdAt.isAfter(startOfToday) && r.createdAt.isBefore(endOfToday.add(const Duration(seconds: 1))))
        .fold<double>(0, (sum, r) => sum + r.refundAmount);
    final weekRefunds = allReturns
        .where((r) => r.createdAt.isAfter(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)) && r.createdAt.isBefore(endOfToday.add(const Duration(seconds: 1))))
        .fold<double>(0, (sum, r) => sum + r.refundAmount);
    final monthRefunds = allReturns
        .where((r) => r.createdAt.isAfter(startOfMonth) && r.createdAt.isBefore(endOfToday.add(const Duration(seconds: 1))))
        .fold<double>(0, (sum, r) => sum + r.refundAmount);

    // Get expenses
    final todayExpenses = await expenseRepo.getTodayTotal();
    final monthExpenses = await expenseRepo.getMonthTotal();

    // Get credit info
    final creditSummary = await creditRepo.getSummary();

    // Get inventory info
    final inventoryValue = await productRepo.getTotalValue();
    final lowStock = await productRepo.getLowStock();

    return ReportSummary(
      todayGrossSales: todayGrossTotal,
      weekGrossSales: weekGrossTotal,
      monthGrossSales: monthGrossTotal,
      todayRefunds: todayRefunds,
      weekRefunds: weekRefunds,
      monthRefunds: monthRefunds,
      todayProfit: todayProfit,
      weekProfit: weekProfit,
      monthProfit: monthProfit,
      todayExpenses: todayExpenses,
      monthExpenses: monthExpenses,
      outstandingCredit: creditSummary.totalOutstanding,
      overdueCount: creditSummary.overdueCount,
      inventoryValue: inventoryValue,
      lowStockCount: lowStock.length,
    );
  } catch (e) {
    // Return empty summary on error
    return const ReportSummary(
      todayGrossSales: 0,
      weekGrossSales: 0,
      monthGrossSales: 0,
      todayRefunds: 0,
      weekRefunds: 0,
      monthRefunds: 0,
      todayProfit: 0,
      weekProfit: 0,
      monthProfit: 0,
      todayExpenses: 0,
      monthExpenses: 0,
      outstandingCredit: 0,
      overdueCount: 0,
      inventoryValue: 0,
      lowStockCount: 0,
    );
  }
});

/// Sales for selected period
final periodSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final dateRange = ref.watch(activeDateRangeProvider);
  final saleRepo = SaleRepository();
  return await saleRepo.getByDateRange(dateRange.start, dateRange.end);
});

/// Payment method breakdown for selected period
final paymentBreakdownProvider = FutureProvider<PaymentMethodBreakdown>((ref) async {
  final sales = await ref.watch(periodSalesProvider.future);

  double cash = 0;
  double mobileMoney = 0;
  double credit = 0;

  double creditPaid = 0;
  double creditOutstanding = 0;

  for (final sale in sales) {
    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        cash += sale.total;
        break;
      case PaymentMethod.mobileMoney:
        mobileMoney += sale.total;
        break;
      case PaymentMethod.credit:
        if (sale.paymentStatus == PaymentStatus.paid) {
          creditPaid += sale.total;
        } else {
          creditPaid += sale.amountPaid;
          creditOutstanding += (sale.total - sale.amountPaid);
        }
        credit += sale.total; // Keep total credit for display breakdown
        break;
    }
  }

  // Total realized revenue = cash + mobile + paid portion of credit
  final realizedTotal = cash + mobileMoney + creditPaid;

  return PaymentMethodBreakdown(
    cash: cash,
    mobileMoney: mobileMoney,
    credit: credit,
    total: realizedTotal,
  );
});

/// Daily sales data for charts (last 7 days)
final dailySalesChartProvider = FutureProvider<List<DailySalesData>>((ref) async {
  try {
    final saleRepo = SaleRepository();
    final returnRepo = ReturnRepository(DatabaseService.instance);
    final now = DateTime.now();
    final List<DailySalesData> data = [];
    
    // Get all returns for the week (with error handling)
    List<ProductReturn> allReturns = [];
    try {
      allReturns = await returnRepo.getAll();
    } catch (e) {
      // If returns fail to load, continue with empty list
    }

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final sales = await saleRepo.getByDateRange(startOfDay, endOfDay);
      final grossTotal = _realizedRevenue(sales);
      final grossProfit = _realizedProfit(sales);
      
      // Subtract refunds for this day
      final dayRefunds = allReturns
          .where((r) => r.createdAt.isAfter(startOfDay) && r.createdAt.isBefore(endOfDay.add(const Duration(seconds: 1))))
          .fold<double>(0, (sum, r) => sum + r.refundAmount);

      data.add(DailySalesData(
        date: startOfDay,
        sales: grossTotal - dayRefunds,
        profit: grossProfit - dayRefunds,
        count: sales.length,
      ));
    }

    return data;
  } catch (e) {
    // Return empty data for 7 days on error
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DailySalesData(
        date: DateTime(date.year, date.month, date.day),
        sales: 0,
        profit: 0,
        count: 0,
      );
    });
  }
});

/// Top selling products for selected period
final topProductsProvider = FutureProvider<List<ProductSalesData>>((ref) async {
  final sales = await ref.watch(periodSalesProvider.future);

  // Aggregate sales by product
  final Map<int, ProductSalesData> productMap = {};

  for (final sale in sales) {
    // Determine how much of this sale counts toward realized revenue
    double revenueFraction = 1.0;
    if (sale.paymentMethod == PaymentMethod.credit) {
      if (sale.paymentStatus == PaymentStatus.paid) {
        revenueFraction = 1.0;
      } else if (sale.amountPaid > 0 && sale.total > 0) {
        revenueFraction = sale.amountPaid / sale.total;
      } else {
        revenueFraction = 0.0;
      }
    }

    for (final item in sale.items) {
      final itemRevenue = item.total * revenueFraction;
      final itemProfit = item.profit * revenueFraction;
      final itemQty = item.quantity * revenueFraction;

      if (productMap.containsKey(item.productId)) {
        final existing = productMap[item.productId]!;
        productMap[item.productId] = ProductSalesData(
          productId: item.productId,
          productName: item.productName,
          category: '', // Would need to lookup
          quantitySold: existing.quantitySold + itemQty,
          revenue: existing.revenue + itemRevenue,
          profit: existing.profit + itemProfit,
        );
      } else {
        productMap[item.productId] = ProductSalesData(
          productId: item.productId,
          productName: item.productName,
          category: '',
          quantitySold: itemQty,
          revenue: itemRevenue,
          profit: itemProfit,
        );
      }
    }
  }

  // Sort by revenue and return top 10
  final products = productMap.values.toList();
  products.sort((a, b) => b.revenue.compareTo(a.revenue));
  return products.take(10).toList();
});

/// Expenses by category for selected period
final expensesByCategoryProvider = FutureProvider<Map<ExpenseCategory, double>>((ref) async {
  final dateRange = ref.watch(activeDateRangeProvider);
  final expenseRepo = ExpenseRepository();
  final expenses = await expenseRepo.getByDateRange(dateRange.start, dateRange.end);

  final Map<ExpenseCategory, double> categoryTotals = {};

  for (final expense in expenses) {
    categoryTotals[expense.category] = 
        (categoryTotals[expense.category] ?? 0) + expense.amount;
  }

  return categoryTotals;
});

/// Period totals (sales, expenses, profit)
final periodTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  try {
    final sales = await ref.watch(periodSalesProvider.future);
    final dateRange = ref.watch(activeDateRangeProvider);
    final expenseRepo = ExpenseRepository();
    final returnRepo = ReturnRepository(DatabaseService.instance);
    final expenses = await expenseRepo.getByDateRange(dateRange.start, dateRange.end);
    
    // Get returns for the period (with error handling)
    List<ProductReturn> allReturns = [];
    try {
      allReturns = await returnRepo.getAll();
    } catch (e) {
      // If returns fail to load, continue with empty list
    }
    
    final periodRefunds = allReturns
        .where((r) => r.createdAt.isAfter(dateRange.start) && r.createdAt.isBefore(dateRange.end.add(const Duration(seconds: 1))))
        .fold<double>(0, (sum, r) => sum + r.refundAmount);

    final grossSales = _realizedRevenue(sales);
    final totalSales = grossSales - periodRefunds; // Net sales after refunds
    
    // Calculate gross COGS (before returns) - only for realized sales
    final grossCost = _realizedCost(sales);
    
    // Calculate the cost of returned items
    final periodReturns = allReturns
        .where((r) => r.createdAt.isAfter(dateRange.start) && r.createdAt.isBefore(dateRange.end.add(const Duration(seconds: 1))))
        .toList();
    final returnedCost = periodReturns.fold<double>(0, (sum, r) => sum + (r.costPrice * r.quantity));
    
    // Net COGS = Gross COGS - Cost of returned items
    final totalCost = grossCost - returnedCost;
    
    // Gross profit after accounting for returns
    final grossProfit = totalSales - totalCost;
    
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netProfit = grossProfit - totalExpenses;

    return {
      'grossSales': grossSales,
      'refunds': periodRefunds,
      'sales': totalSales,
      'cost': totalCost,
      'grossProfit': grossProfit,
      'expenses': totalExpenses,
      'netProfit': netProfit,
      'salesCount': sales.length.toDouble(),
    };
  } catch (e) {
    // Return empty data on error
    return {
      'grossSales': 0.0,
      'refunds': 0.0,
      'sales': 0.0,
      'cost': 0.0,
      'grossProfit': 0.0,
      'expenses': 0.0,
      'netProfit': 0.0,
      'salesCount': 0.0,
    };
  }
});
