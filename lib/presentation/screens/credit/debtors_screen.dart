import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import 'record_payment_screen.dart';

class DebtorsScreen extends ConsumerStatefulWidget {
  const DebtorsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends ConsumerState<DebtorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(creditSummaryProvider);
    final outstandingAsync = ref.watch(outstandingCreditSalesProvider);
    final overdueAsync = ref.watch(overdueTransactionsProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Debtors',
      ),
      body: Column(
        children: [
          // Summary Card
          summaryAsync.when(
            data: (summary) => Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DuukaColors.error, DuukaColors.error.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Outstanding',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DuukaFormatters.currency(summary.totalCreditSalesOutstanding),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: 'Debtors',
                        value: '${summary.creditSalesCount}',
                      ),
                      Container(width: 1, height: 30.h, color: Colors.white30),
                      _SummaryItem(
                        label: 'Overdue',
                        value: '${summary.overdueCount}',
                      ),
                      Container(width: 1, height: 30.h, color: Colors.white30),
                      _SummaryItem(
                        label: 'Overdue Amt',
                        value: DuukaFormatters.currencyCompact(summary.overdueAmount),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => Container(
              height: 140.h,
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: DuukaColors.surface,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Tabs
          Container(
            color: DuukaColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: DuukaColors.primary,
              unselectedLabelColor: DuukaColors.textSecondary,
              indicatorColor: DuukaColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Overdue'),
                Tab(text: 'Due Soon'),
              ],
            ),
          ),

          // List
          Expanded(
            child: outstandingAsync.when(
              data: (transactions) {
                final overdue = transactions.where((t) => t.isOverdue).toList();
                final dueSoon = transactions.where((t) => 
                    !t.isOverdue && t.daysUntilDue <= 7).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(transactions),
                    _buildTransactionList(overdue),
                    _buildTransactionList(dueSoon),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<CreditTransaction> transactions) {
    if (transactions.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No outstanding debts',
        description: 'All credit sales have been paid',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outstandingCreditSalesProvider);
        ref.invalidate(creditSummaryProvider);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final txn = transactions[index];
          return _DebtorCard(
            transaction: txn,
            onTap: () => context.push('/customer/${txn.customerId}'),
            onRecordPayment: () => _showRecordPayment(txn),
          );
        },
      ),
    );
  }

  void _showRecordPayment(CreditTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordPaymentSheet(transaction: transaction),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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

class _DebtorCard extends StatelessWidget {
  final CreditTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onRecordPayment;

  const _DebtorCard({
    required this.transaction,
    required this.onTap,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: transaction.isOverdue
            ? Border.all(color: DuukaColors.error.withOpacity(0.5), width: 1)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: transaction.isOverdue
                          ? DuukaColors.error.withOpacity(0.1)
                          : DuukaColors.primaryBg,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Center(
                      child: Text(
                        transaction.customerName.isNotEmpty
                            ? transaction.customerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: transaction.isOverdue
                              ? DuukaColors.error
                              : DuukaColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.customerName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                        Text(
                          transaction.customerPhone,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DuukaFormatters.currency(transaction.balance),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.error,
                        ),
                      ),
                      if (transaction.isOverdue)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: DuukaColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '${transaction.daysOverdue}d overdue',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid: ${DuukaFormatters.currency(transaction.amountPaid)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                            Text(
                              'of ${DuukaFormatters.currency(transaction.totalAmount)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: transaction.progressPercent / 100,
                            backgroundColor: DuukaColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              transaction.isOverdue
                                  ? DuukaColors.error
                                  : DuukaColors.primary,
                            ),
                            minHeight: 6.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Footer
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14.sp, color: DuukaColors.textSecondary),
                  SizedBox(width: 4.w),
                  Text(
                    'Due: ${DuukaFormatters.date(transaction.agreedPaymentDate)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: transaction.isOverdue
                          ? DuukaColors.error
                          : DuukaColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onRecordPayment,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      backgroundColor: DuukaColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
