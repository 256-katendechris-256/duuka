import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';

class ProfitLossScreen extends ConsumerWidget {
  const ProfitLossScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    // Redirect non-owners to home
    if (!isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedPeriod = ref.watch(selectedReportPeriodProvider);
    final periodTotalsAsync = ref.watch(periodTotalsProvider);
    final expensesByCatAsync = ref.watch(expensesByCategoryProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Profit & Loss',
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
                ref.invalidate(periodTotalsProvider);
                ref.invalidate(expensesByCategoryProvider);
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Net Profit Card
                    periodTotalsAsync.when(
                      data: (totals) => _buildNetProfitCard(totals),
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    SizedBox(height: 24.h),

                    // Income Statement
                    Text(
                      'Income Statement',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    periodTotalsAsync.when(
                      data: (totals) => _buildIncomeStatement(totals),
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    SizedBox(height: 24.h),

                    // Expenses by Category
                    Text(
                      'Expenses Breakdown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    expensesByCatAsync.when(
                      data: (expenses) => _buildExpensesBreakdown(expenses),
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

  Widget _buildNetProfitCard(Map<String, double> totals) {
    final netProfit = totals['netProfit'] ?? 0;
    final isPositive = netProfit >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [DuukaColors.success, DuukaColors.success.withOpacity(0.8)]
              : [DuukaColors.error, DuukaColors.error.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? DuukaColors.success : DuukaColors.error)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 28.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                isPositive ? 'Net Profit' : 'Net Loss',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            DuukaFormatters.currency(netProfit.abs()),
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              isPositive 
                  ? 'Your business is profitable!' 
                  : 'Expenses exceeded income',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeStatement(Map<String, double> totals) {
    final sales = totals['sales'] ?? 0;
    final cost = totals['cost'] ?? 0;
    final grossProfit = totals['grossProfit'] ?? 0;
    final expenses = totals['expenses'] ?? 0;
    final netProfit = totals['netProfit'] ?? 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border),
      ),
      child: Column(
        children: [
          // Revenue
          _StatementRow(
            label: 'Total Revenue',
            value: sales,
            isHeader: true,
            color: DuukaColors.success,
          ),
          Divider(color: DuukaColors.border, height: 24.h),
          
          // Cost of Goods
          _StatementRow(
            label: 'Cost of Goods Sold',
            value: -cost,
            color: DuukaColors.error,
          ),
          SizedBox(height: 8.h),
          
          // Gross Profit
          _StatementRow(
            label: 'Gross Profit',
            value: grossProfit,
            isSubtotal: true,
            color: DuukaColors.primary,
          ),
          Divider(color: DuukaColors.border, height: 24.h),
          
          // Operating Expenses
          _StatementRow(
            label: 'Operating Expenses',
            value: -expenses,
            color: DuukaColors.error,
          ),
          Divider(color: DuukaColors.border, height: 24.h),
          
          // Net Profit
          _StatementRow(
            label: 'Net Profit',
            value: netProfit,
            isTotal: true,
            color: netProfit >= 0 ? DuukaColors.success : DuukaColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesBreakdown(Map<ExpenseCategory, double> expenses) {
    if (expenses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, color: DuukaColors.success, size: 48.sp),
              SizedBox(height: 12.h),
              Text(
                'No expenses recorded',
                style: TextStyle(color: DuukaColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final total = expenses.values.fold<double>(0, (sum, val) => sum + val);
    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border),
      ),
      child: Column(
        children: sortedEntries.map((entry) {
          final percent = total > 0 ? (entry.value / total) * 100 : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _ExpenseRow(
              category: entry.key,
              amount: entry.value,
              percent: percent,
            ),
          );
        }).toList(),
      ),
    );
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

class _StatementRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isHeader;
  final bool isSubtotal;
  final bool isTotal;

  const _StatementRow({
    required this.label,
    required this.value,
    required this.color,
    this.isHeader = false,
    this.isSubtotal = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal || isHeader || isSubtotal
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isTotal ? color : DuukaColors.textPrimary,
            ),
          ),
        ),
        Text(
          DuukaFormatters.currency(value.abs()),
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal || isSubtotal ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double percent;

  const _ExpenseRow({
    required this.category,
    required this.amount,
    required this.percent,
  });

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.salaries:
        return 'Salaries';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _getCategoryIcon(category),
                size: 18.sp,
                color: _getCategoryColor(category),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}% of expenses',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DuukaFormatters.currency(amount),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.error,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: DuukaColors.border,
            valueColor: AlwaysStoppedAnimation(_getCategoryColor(category)),
            minHeight: 4.h,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Colors.blue;
      case ExpenseCategory.utilities:
        return Colors.orange;
      case ExpenseCategory.salaries:
        return Colors.purple;
      case ExpenseCategory.supplies:
        return Colors.teal;
      case ExpenseCategory.transport:
        return Colors.indigo;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.maintenance:
        return Colors.brown;
      case ExpenseCategory.taxes:
        return Colors.red;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.utilities:
        return Icons.flash_on;
      case ExpenseCategory.salaries:
        return Icons.people;
      case ExpenseCategory.supplies:
        return Icons.inventory;
      case ExpenseCategory.transport:
        return Icons.local_shipping;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.taxes:
        return Icons.receipt;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }
}
