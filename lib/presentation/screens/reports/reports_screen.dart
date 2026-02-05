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

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
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

    final summaryAsync = ref.watch(reportSummaryProvider);
    final dailyChartAsync = ref.watch(dailySalesChartProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Reports',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportSummaryProvider);
          ref.invalidate(dailySalesChartProvider);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Row
              summaryAsync.when(
                data: (summary) => _buildQuickStats(summary),
                loading: () => _buildLoadingStats(),
                error: (_, __) => _buildErrorStats(),
              ),
              SizedBox(height: 24.h),

              // Sales Chart
              Text(
                'Sales Trend (Last 7 Days)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              dailyChartAsync.when(
                data: (data) => _buildSalesChart(data),
                loading: () => _buildLoadingChart(),
                error: (_, __) => _buildErrorChart(),
              ),
              SizedBox(height: 24.h),

              // Report Cards
              Text(
                'Detailed Reports',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              _buildReportCards(),
              SizedBox(height: 24.h),

              // Profit Summary
              summaryAsync.when(
                data: (summary) => _buildProfitSummary(summary),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ReportSummary summary) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: DuukaColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickStatItem(
                  label: 'Today',
                  value: DuukaFormatters.currencyCompact(summary.todaySales),
                  icon: Icons.today,
                ),
              ),
              Container(width: 1, height: 50.h, color: Colors.white24),
              Expanded(
                child: _QuickStatItem(
                  label: 'This Week',
                  value: DuukaFormatters.currencyCompact(summary.weekSales),
                  icon: Icons.date_range,
                ),
              ),
              Container(width: 1, height: 50.h, color: Colors.white24),
              Expanded(
                child: _QuickStatItem(
                  label: 'This Month',
                  value: DuukaFormatters.currencyCompact(summary.monthSales),
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStatItem(
                  label: "Today's Profit",
                  value: DuukaFormatters.currencyCompact(summary.todayNetProfit),
                  isPositive: summary.todayNetProfit >= 0,
                ),
                _MiniStatItem(
                  label: "Month's Profit",
                  value: DuukaFormatters.currencyCompact(summary.monthNetProfit),
                  isPositive: summary.monthNetProfit >= 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        gradient: DuukaColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorStats() {
    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        color: DuukaColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Text(
          'Failed to load stats',
          style: TextStyle(color: DuukaColors.error),
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<DailySalesData> data) {
    if (data.isEmpty) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No sales data available',
            style: TextStyle(color: DuukaColors.textSecondary),
          ),
        ),
      );
    }

    final maxSales = data.map((d) => d.sales).reduce((a, b) => a > b ? a : b);
    final barMaxHeight = 100.h;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: barMaxHeight + 55.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final barHeight = maxSales > 0 
                    ? (d.sales / maxSales) * barMaxHeight 
                    : 0.0;
                final isToday = d.date.day == DateTime.now().day &&
                    d.date.month == DateTime.now().month;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DuukaFormatters.currencyCompact(d.sales),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: barHeight < 4 && d.sales > 0 ? 4.h : barHeight,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isToday
                                ? [DuukaColors.primary, DuukaColors.primary.withOpacity(0.7)]
                                : [DuukaColors.info, DuukaColors.info.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _getDayLabel(d.date),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday 
                              ? DuukaColors.primary 
                              : DuukaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) {
      return 'Today';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorChart() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: DuukaColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          'Failed to load chart',
          style: TextStyle(color: DuukaColors.error),
        ),
      ),
    );
  }

  Widget _buildReportCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.2,
      children: [
        _ReportCard(
          icon: Icons.point_of_sale,
          label: 'Sales Report',
          description: 'Revenue & transactions',
          color: DuukaColors.success,
          onTap: () => context.push('/reports/sales'),
        ),
        _ReportCard(
          icon: Icons.account_balance_wallet,
          label: 'Profit & Loss',
          description: 'Income vs expenses',
          color: DuukaColors.primary,
          onTap: () => context.push('/reports/profit-loss'),
        ),
        _ReportCard(
          icon: Icons.inventory_2,
          label: 'Inventory',
          description: 'Stock levels & value',
          color: DuukaColors.info,
          onTap: () => context.push('/reports/inventory'),
        ),
        _ReportCard(
          icon: Icons.people,
          label: 'Credit Report',
          description: 'Debtors & balances',
          color: DuukaColors.warning,
          onTap: () => context.push('/debtors'),
        ),
      ],
    );
  }

  Widget _buildProfitSummary(ReportSummary summary) {
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
          Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _FinancialRow(
            label: 'Outstanding Credit',
            value: summary.outstandingCredit,
            color: DuukaColors.warning,
            icon: Icons.credit_card,
          ),
          SizedBox(height: 12.h),
          _FinancialRow(
            label: 'Overdue Debts',
            value: summary.overdueCount.toDouble(),
            isCount: true,
            color: DuukaColors.error,
            icon: Icons.warning_amber,
          ),
          SizedBox(height: 12.h),
          _FinancialRow(
            label: 'Inventory Value',
            value: summary.inventoryValue,
            color: DuukaColors.info,
            icon: Icons.inventory,
          ),
          SizedBox(height: 12.h),
          _FinancialRow(
            label: 'Low Stock Items',
            value: summary.lowStockCount.toDouble(),
            isCount: true,
            color: summary.lowStockCount > 0 ? DuukaColors.warning : DuukaColors.success,
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20.sp, color: Colors.white70),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;

  const _MiniStatItem({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14.sp,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
            ),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: DuukaColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 18.sp, color: color),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 10.sp,
                color: DuukaColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isCount;

  const _FinancialRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: color),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: DuukaColors.textSecondary,
            ),
          ),
        ),
        Text(
          isCount ? value.toInt().toString() : DuukaFormatters.currency(value),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: DuukaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
