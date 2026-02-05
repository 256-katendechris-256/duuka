import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import 'record_payment_screen.dart';

class HirePurchaseScreen extends ConsumerStatefulWidget {
  const HirePurchaseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HirePurchaseScreen> createState() => _HirePurchaseScreenState();
}

class _HirePurchaseScreenState extends ConsumerState<HirePurchaseScreen>
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
    final hirePurchasesAsync = ref.watch(outstandingHirePurchasesProvider);
    final readyForCollectionAsync = ref.watch(readyForCollectionProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Hire Purchase',
        actions: [
          IconButton(
            onPressed: () => _showAddHirePurchase(),
            icon: Icon(Icons.add, size: 24.sp),
            tooltip: 'New Hire Purchase',
          ),
        ],
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
                  colors: [DuukaColors.info, DuukaColors.info.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Text(
                    'Hire Purchase Outstanding',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DuukaFormatters.currency(summary.totalHirePurchaseOutstanding),
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
                        label: 'Active',
                        value: '${summary.hirePurchaseCount}',
                      ),
                      Container(width: 1, height: 30.h, color: Colors.white30),
                      _SummaryItem(
                        label: 'Ready to Collect',
                        value: '${summary.readyForCollectionCount}',
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
                Tab(text: 'Active'),
                Tab(text: 'Ready'),
                Tab(text: 'Collected'),
              ],
            ),
          ),

          // List
          Expanded(
            child: hirePurchasesAsync.when(
              data: (transactions) {
                return readyForCollectionAsync.when(
                  data: (readyTransactions) {
                    final active = transactions.where((t) => !t.isCleared).toList();
                    final collected = transactions.where((t) => t.isCollected).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHirePurchaseList(active),
                        _buildHirePurchaseList(readyTransactions, isReady: true),
                        _buildHirePurchaseList(collected, isCollected: true),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHirePurchase,
        backgroundColor: DuukaColors.primary,
        icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
        label: Text(
          'New Hire Purchase',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHirePurchaseList(
    List<CreditTransaction> transactions, {
    bool isReady = false,
    bool isCollected = false,
  }) {
    if (transactions.isEmpty) {
      return EmptyState(
        icon: isReady
            ? Icons.local_shipping_outlined
            : isCollected
                ? Icons.check_circle_outline
                : Icons.shopping_bag_outlined,
        title: isReady
            ? 'No items ready for collection'
            : isCollected
                ? 'No collected items yet'
                : 'No active hire purchases',
        description: isReady
            ? 'Items will appear here when fully paid'
            : isCollected
                ? 'Collected items will be shown here'
                : 'Start a new hire purchase arrangement',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outstandingHirePurchasesProvider);
        ref.invalidate(readyForCollectionProvider);
        ref.invalidate(creditSummaryProvider);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final txn = transactions[index];
          return _HirePurchaseCard(
            transaction: txn,
            isReady: isReady,
            isCollected: isCollected,
            onTap: () => context.push('/customer/${txn.customerId}'),
            onRecordPayment: () => _showRecordPayment(txn),
            onMarkCollected: () => _markAsCollected(txn),
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

  Future<void> _markAsCollected(CreditTransaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Collection'),
        content: Text(
          'Mark "${transaction.productName}" as collected by ${transaction.customerName}?\n\n'
          'This will deduct ${transaction.productQuantity} item(s) from your inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.success,
            ),
            child: const Text('Confirm Collection'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(creditNotifierProvider.notifier)
          .markAsCollected(transaction.id);
      
      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Item marked as collected!');
        } else {
          context.showErrorSnackBar('Failed to mark as collected');
        }
      }
    }
  }

  void _showAddHirePurchase() {
    // TODO: Navigate to add hire purchase screen
    context.showInfoSnackBar('Coming soon: Add Hire Purchase');
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

class _HirePurchaseCard extends StatelessWidget {
  final CreditTransaction transaction;
  final bool isReady;
  final bool isCollected;
  final VoidCallback onTap;
  final VoidCallback onRecordPayment;
  final VoidCallback onMarkCollected;

  const _HirePurchaseCard({
    required this.transaction,
    required this.isReady,
    required this.isCollected,
    required this.onTap,
    required this.onRecordPayment,
    required this.onMarkCollected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: isReady
            ? Border.all(color: DuukaColors.success, width: 2)
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
              // Product Info
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: DuukaColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: DuukaColors.info,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.productName ?? 'Unknown Product',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Qty: ${transaction.productQuantity ?? 1}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: DuukaColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, 
                              size: 14.sp, color: DuukaColors.success),
                          SizedBox(width: 4.w),
                          Text(
                            'Ready',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isCollected)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: DuukaColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Collected',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),

              // Customer
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14.sp, color: DuukaColors.textSecondary),
                  SizedBox(width: 4.w),
                  Text(
                    transaction.customerName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    transaction.customerPhone,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Payment Progress
              if (!isCollected) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid: ${DuukaFormatters.currency(transaction.amountPaid)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                    Text(
                      'of ${DuukaFormatters.currency(transaction.totalAmount)}',
                      style: TextStyle(
                        fontSize: 12.sp,
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
                      isReady ? DuukaColors.success : DuukaColors.info,
                    ),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${transaction.progressPercent.toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isReady ? DuukaColors.success : DuukaColors.info,
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Due date
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
                  if (transaction.isOverdue) ...[
                    SizedBox(width: 8.w),
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
                ],
              ),

              // Actions
              if (!isCollected) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (!isReady)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRecordPayment,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            side: BorderSide(color: DuukaColors.primary),
                          ),
                          child: Text(
                            'Record Payment',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (isReady) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onMarkCollected,
                          icon: Icon(Icons.check, size: 18.sp),
                          label: const Text('Mark Collected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DuukaColors.success,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
