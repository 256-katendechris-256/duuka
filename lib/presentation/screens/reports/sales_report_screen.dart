import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    // Redirect non-owners to home
    if (!isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/home');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedPeriod = ref.watch(selectedReportPeriodProvider);
    final salesAsync = ref.watch(periodSalesProvider);
    final paymentBreakdownAsync = ref.watch(paymentBreakdownProvider);
    final topProductsAsync = ref.watch(topProductsProvider);
    final periodTotalsAsync = ref.watch(periodTotalsProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Sales Report',
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            color: DuukaColors.surface,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportPeriod.values
                    .where((p) => p != ReportPeriod.custom)
                    .map((period) => Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: ChoiceChip(
                            label: Text(period.label),
                            selected: selectedPeriod == period,
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(selectedReportPeriodProvider.notifier).state = period;
                              }
                            },
                            selectedColor: DuukaColors.primary,
                            labelStyle: TextStyle(
                              color: selectedPeriod == period 
                                  ? Colors.white 
                                  : DuukaColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(periodSalesProvider);
                ref.invalidate(paymentBreakdownProvider);
                ref.invalidate(topProductsProvider);
                ref.invalidate(periodTotalsProvider);
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    periodTotalsAsync.when(
                      data: (totals) => _buildSummaryCards(totals),
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    SizedBox(height: 24.h),

                    // Payment Method Breakdown
                    Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    paymentBreakdownAsync.when(
                      data: (breakdown) => _buildPaymentBreakdown(breakdown),
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    SizedBox(height: 24.h),

                    // Top Products
                    Text(
                      'Top Selling Products',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    topProductsAsync.when(
                      data: (products) => _buildTopProducts(products),
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    SizedBox(height: 24.h),

                    // Recent Transactions
                    Text(
                      'Transactions (${selectedPeriod.label})',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    salesAsync.when(
                      data: (sales) => _buildTransactionsList(sales),
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, double> totals) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Sales',
                value: DuukaFormatters.currency(totals['sales'] ?? 0),
                icon: Icons.point_of_sale,
                color: DuukaColors.success,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _SummaryCard(
                label: 'Transactions',
                value: (totals['salesCount'] ?? 0).toInt().toString(),
                icon: Icons.receipt_long,
                color: DuukaColors.info,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Gross Profit',
                value: DuukaFormatters.currency(totals['grossProfit'] ?? 0),
                icon: Icons.trending_up,
                color: DuukaColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _SummaryCard(
                label: 'Avg. per Sale',
                value: DuukaFormatters.currency(
                  (totals['salesCount'] ?? 0) > 0
                      ? (totals['sales'] ?? 0) / (totals['salesCount'] ?? 1)
                      : 0,
                ),
                icon: Icons.analytics,
                color: DuukaColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown(PaymentMethodBreakdown breakdown) {
    if (breakdown.total == 0) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No sales in this period',
            style: TextStyle(color: DuukaColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
              children: [
                if (breakdown.cash > 0)
                  Expanded(
                    flex: (breakdown.cashPercent).round(),
                    child: Container(height: 24.h, color: DuukaColors.success),
                  ),
                if (breakdown.mobileMoney > 0)
                  Expanded(
                    flex: (breakdown.mobileMoneyPercent).round(),
                    child: Container(height: 24.h, color: DuukaColors.info),
                  ),
                if (breakdown.credit > 0)
                  Expanded(
                    flex: (breakdown.creditPercent).round(),
                    child: Container(height: 24.h, color: DuukaColors.warning),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Legend
          _PaymentMethodRow(
            label: 'Cash',
            amount: breakdown.cash,
            percent: breakdown.cashPercent,
            color: DuukaColors.success,
          ),
          SizedBox(height: 8.h),
          _PaymentMethodRow(
            label: 'Mobile Money',
            amount: breakdown.mobileMoney,
            percent: breakdown.mobileMoneyPercent,
            color: DuukaColors.info,
          ),
          SizedBox(height: 8.h),
          _PaymentMethodRow(
            label: 'Credit',
            amount: breakdown.credit,
            percent: breakdown.creditPercent,
            color: DuukaColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<ProductSalesData> products) {
    if (products.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No product sales data',
            style: TextStyle(color: DuukaColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length > 5 ? 5 : products.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: DuukaColors.border),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: DuukaColors.primaryBg,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: DuukaColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              product.productName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${product.quantitySold} sold',
              style: TextStyle(fontSize: 12.sp),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DuukaFormatters.currency(product.revenue),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  'Profit: ${DuukaFormatters.currencyCompact(product.profit)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: DuukaColors.success,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(List<Sale> sales) {
    if (sales.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No transactions in this period',
            style: TextStyle(color: DuukaColors.textSecondary),
          ),
        ),
      );
    }

    final displaySales = sales.length > 10 ? sales.sublist(0, 10) : sales;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displaySales.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: DuukaColors.border),
            itemBuilder: (context, index) {
              final sale = displaySales[index];
              return ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getPaymentColor(sale.paymentMethod).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getPaymentIcon(sale.paymentMethod),
                    color: _getPaymentColor(sale.paymentMethod),
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  sale.receiptNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Text(
                  DuukaFormatters.dateTime(sale.createdAt),
                  style: TextStyle(fontSize: 12.sp),
                ),
                trailing: Text(
                  DuukaFormatters.currency(sale.total),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              );
            },
          ),
        ),
        if (sales.length > 10) ...[
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => context.push('/sales'),
            child: Text(
              'View all ${sales.length} transactions',
              style: TextStyle(
                color: DuukaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return DuukaColors.success;
      case PaymentMethod.mobileMoney:
        return DuukaColors.info;
      case PaymentMethod.credit:
        return DuukaColors.warning;
    }
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.credit:
        return Icons.credit_card;
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(icon, size: 16.sp, color: color),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: DuukaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String label;
  final double amount;
  final double percent;
  final Color color;

  const _PaymentMethodRow({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: DuukaColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          DuukaFormatters.currency(amount),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.textPrimary,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
