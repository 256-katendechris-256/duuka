import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/customer_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../credit/record_payment_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final transactionsAsync = ref.watch(customerTransactionsProvider(customerId));
    final balanceAsync = ref.watch(customerBalanceProvider(customerId));

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Customer Details',
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Edit customer
            },
            icon: Icon(Icons.edit_outlined, size: 24.sp),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const EmptyState(
              icon: Icons.person_off,
              title: 'Customer not found',
              description: 'This customer may have been deleted',
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Header
                Container(
                  color: DuukaColors.surface,
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: DuukaColors.primaryBg,
                          borderRadius: BorderRadius.circular(40.r),
                        ),
                        child: Center(
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w700,
                              color: DuukaColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      if (customer.location != null) ...[
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 14.sp, color: DuukaColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              customer.location!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 16.h),

                      // Balance Card
                      balanceAsync.when(
                        data: (balance) => Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: balance > 0 
                                ? DuukaColors.error.withOpacity(0.1)
                                : DuukaColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: balance > 0 ? DuukaColors.error : DuukaColors.success,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                balance > 0 ? 'Outstanding Balance' : 'No Outstanding Balance',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: balance > 0 ? DuukaColors.error : DuukaColors.success,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                DuukaFormatters.currency(balance),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: balance > 0 ? DuukaColors.error : DuukaColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Stats Row
                Container(
                  color: DuukaColors.surface,
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'Total Purchases',
                          value: '${customer.totalPurchases}',
                          icon: Icons.shopping_cart,
                        ),
                      ),
                      Container(width: 1, height: 40.h, color: DuukaColors.border),
                      Expanded(
                        child: _StatItem(
                          label: 'Total Spent',
                          value: DuukaFormatters.currencyCompact(customer.totalSpent),
                          icon: Icons.payments,
                        ),
                      ),
                      Container(width: 1, height: 40.h, color: DuukaColors.border),
                      Expanded(
                        child: _StatItem(
                          label: 'Customer Since',
                          value: DuukaFormatters.dateShort(customer.createdAt),
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Transactions Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Credit Transactions',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Container(
                        margin: EdgeInsets.all(16.w),
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: DuukaColors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, 
                                size: 48.sp, color: DuukaColors.textSecondary),
                            SizedBox(height: 12.h),
                            Text(
                              'No credit transactions',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        return _TransactionCard(
                          transaction: txn,
                          onRecordPayment: () => _showRecordPayment(context, ref, txn),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),

                SizedBox(height: 100.h),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showRecordPayment(BuildContext context, WidgetRef ref, CreditTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordPaymentSheet(transaction: transaction),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20.sp, color: DuukaColors.textSecondary),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: DuukaColors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: DuukaColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final CreditTransaction transaction;
  final VoidCallback onRecordPayment;

  const _TransactionCard({
    required this.transaction,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: transaction.isOverdue
            ? Border.all(color: DuukaColors.error, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: transaction.type == CreditType.credit
                      ? DuukaColors.warning.withOpacity(0.1)
                      : DuukaColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  transaction.type == CreditType.credit ? 'Credit Sale' : 'Hire Purchase',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: transaction.type == CreditType.credit
                        ? DuukaColors.warning
                        : DuukaColors.info,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(),
            ],
          ),
          SizedBox(height: 12.h),

          // Product/Amount Info
          if (transaction.productName != null) ...[
            Text(
              transaction.productName!,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
          ],

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ${DuukaFormatters.currency(transaction.amountPaid)}',
                style: TextStyle(fontSize: 13.sp, color: DuukaColors.textSecondary),
              ),
              Text(
                'of ${DuukaFormatters.currency(transaction.totalAmount)}',
                style: TextStyle(fontSize: 13.sp, color: DuukaColors.textSecondary),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: transaction.progressPercent / 100,
              backgroundColor: DuukaColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                transaction.isCleared ? DuukaColors.success : DuukaColors.primary,
              ),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 8.h),

          // Balance & Due Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(fontSize: 11.sp, color: DuukaColors.textSecondary),
                  ),
                  Text(
                    DuukaFormatters.currency(transaction.balance),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: transaction.balance > 0 ? DuukaColors.error : DuukaColors.success,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(fontSize: 11.sp, color: DuukaColors.textSecondary),
                  ),
                  Text(
                    DuukaFormatters.date(transaction.agreedPaymentDate),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: transaction.isOverdue ? DuukaColors.error : DuukaColors.textPrimary,
                    ),
                  ),
                  if (transaction.isOverdue)
                    Text(
                      '${transaction.daysOverdue} days overdue',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: DuukaColors.error,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Actions
          if (!transaction.isCleared) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRecordPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuukaColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],

          // Collect button for hire purchase
          if (transaction.canCollect) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Mark as collected
                },
                icon: Icon(Icons.check_circle, size: 20.sp),
                label: const Text('Mark as Collected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuukaColors.success,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (transaction.status) {
      case CreditStatus.cleared:
        color = DuukaColors.success;
        text = 'Cleared';
        break;
      case CreditStatus.partial:
        color = DuukaColors.warning;
        text = 'Partial';
        break;
      case CreditStatus.overdue:
        color = DuukaColors.error;
        text = 'Overdue';
        break;
      case CreditStatus.pending:
        color = DuukaColors.textSecondary;
        text = 'Pending';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
