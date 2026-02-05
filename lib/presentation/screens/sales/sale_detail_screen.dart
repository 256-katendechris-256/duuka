import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../data/models/product_return.dart';
import '../../providers/sale_provider.dart';
import '../../providers/return_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleByIdProvider(saleId));
    final returnsAsync = ref.watch(saleReturnsProvider(saleId));

    return Scaffold(
      appBar: DuukaAppBar(
        title: 'Sale Details',
      ),
      body: saleAsync.when(
        data: (sale) {
          if (sale == null) {
            return const Center(child: Text('Sale not found'));
          }
          return _buildSaleDetails(context, ref, sale, returnsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSaleDetails(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    AsyncValue<List<ProductReturn>> returnsAsync,
  ) {
    final returns = returnsAsync.valueOrNull ?? [];
    final totalRefunded = returns.fold(0.0, (sum, r) => sum + r.refundAmount);
    final netSaleAmount = sale.total - totalRefunded;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: DuukaColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receipt #${sale.receiptNumber}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    _buildPaymentStatusChip(sale.paymentStatus),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DuukaFormatters.dateTime(sale.createdAt),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                    Text(
                      sale.paymentMethod.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Items Section
          Text(
            'Items Purchased',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),

          // List of items with return option
          ...sale.items.map((item) {
            final returnedQty = _getReturnedQuantity(returns, item.productId);
            final canReturn = item.quantity > returnedQty;

            return _SaleItemTile(
              item: item,
              returnedQuantity: returnedQty,
              canReturn: canReturn,
              onReturn: canReturn
                  ? () => _showReturnDialog(context, ref, sale, item, returnedQty)
                  : null,
            );
          }),

          SizedBox(height: 16.h),

          // Totals Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: DuukaColors.primaryBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', sale.subtotal),
                if (sale.discount > 0) ...[
                  SizedBox(height: 8.h),
                  _buildTotalRow('Discount', -sale.discount, isDiscount: true),
                ],
                SizedBox(height: 8.h),
                Divider(color: DuukaColors.border),
                SizedBox(height: 8.h),
                _buildTotalRow('Original Total', sale.total),
                if (returns.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _buildTotalRow('Total Refunded', -totalRefunded, isRefund: true),
                  SizedBox(height: 8.h),
                  Divider(color: DuukaColors.border),
                  SizedBox(height: 8.h),
                  _buildTotalRow('Net Sale', netSaleAmount, isTotal: true),
                ] else ...[
                  _buildTotalRow('', 0, isHidden: true), // Placeholder
                ],
                if (sale.paymentStatus == PaymentStatus.partial) ...[
                  SizedBox(height: 8.h),
                  _buildTotalRow('Paid', sale.amountPaid),
                  _buildTotalRow('Balance', sale.balance, isBalance: true),
                ],
              ],
            ),
          ),

          // Returns Section (if any)
          if (returns.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Row(
              children: [
                Icon(Icons.assignment_return, size: 20.sp, color: DuukaColors.warning),
                SizedBox(width: 8.w),
                Text(
                  'Returns (${returns.length})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: DuukaColors.errorBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '-${DuukaFormatters.currency(totalRefunded)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.error,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...returns.map((ret) => _ReturnTile(productReturn: ret)),
          ],

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  double _getReturnedQuantity(List<ProductReturn> returns, int productId) {
    double total = 0;
    for (final r in returns) {
      if (r.productId == productId) {
        total += r.quantity;
      }
    }
    return total;
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color color;
    String label;

    switch (status) {
      case PaymentStatus.paid:
        color = DuukaColors.success;
        label = 'PAID';
        break;
      case PaymentStatus.partial:
        color = DuukaColors.warning;
        label = 'PARTIAL';
        break;
      case PaymentStatus.unpaid:
        color = DuukaColors.error;
        label = 'UNPAID';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isTotal = false, bool isDiscount = false, bool isBalance = false, bool isRefund = false, bool isHidden = false}) {
    if (isHidden) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? DuukaColors.textPrimary : DuukaColors.textSecondary,
          ),
        ),
        Text(
          '${(isDiscount || isRefund) ? '-' : ''}${DuukaFormatters.currency(amount.abs())}',
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isDiscount
                ? DuukaColors.success
                : isRefund
                    ? DuukaColors.error
                    : isBalance
                        ? DuukaColors.error
                        : DuukaColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showReturnDialog(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    SaleItem item,
    double alreadyReturned,
  ) {
    final maxReturnQty = item.quantity - alreadyReturned;
    double returnQty = maxReturnQty;
    ReturnReason selectedReason = ReturnReason.changedMind;
    ReturnCondition selectedCondition = ReturnCondition.resellable;
    RefundType selectedRefundType = RefundType.cash;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final refundAmount = returnQty * item.unitPrice;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 20.w,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24.w,
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: DuukaColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  Text(
                    'Return Item',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Product Info
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.background,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, color: DuukaColors.primary),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${DuukaFormatters.currency(item.unitPrice)} x ${item.formattedQuantity}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: DuukaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Quantity to return
                  Text(
                    'Quantity to Return',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: returnQty > 1
                            ? () => setModalState(() => returnQty -= 1)
                            : null,
                        icon: Icon(Icons.remove_circle_outline),
                        color: DuukaColors.primary,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: DuukaColors.background,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            item.isMeasurable
                                ? '${returnQty.toStringAsFixed(2)} ${item.unit}'
                                : '${returnQty.toInt()} ${item.unit}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: returnQty < maxReturnQty
                            ? () => setModalState(() => returnQty += 1)
                            : null,
                        icon: Icon(Icons.add_circle_outline),
                        color: DuukaColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Reason
                  Text(
                    'Reason for Return',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: ReturnReason.values.map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedReason = reason),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DuukaColors.primary
                                : DuukaColors.background,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? DuukaColors.primary
                                  : DuukaColors.border,
                            ),
                          ),
                          child: Text(
                            reason.label,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : DuukaColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),

                  // Condition
                  Text(
                    'Item Condition',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...ReturnCondition.values.map((condition) {
                    final isSelected = selectedCondition == condition;
                    return RadioListTile<ReturnCondition>(
                      title: Text(condition.label),
                      subtitle: Text(
                        condition.canRestock
                            ? 'Will be added back to stock'
                            : 'Will NOT be restocked',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: condition.canRestock
                              ? DuukaColors.success
                              : DuukaColors.warning,
                        ),
                      ),
                      value: condition,
                      groupValue: selectedCondition,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedCondition = value);
                        }
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  SizedBox(height: 16.h),

                  // Refund Type
                  Text(
                    'Refund Method',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: RefundType.values.map((type) {
                      final isSelected = selectedRefundType == type;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedRefundType = type),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DuukaColors.primary
                                : DuukaColors.background,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? DuukaColors.primary
                                  : DuukaColors.border,
                            ),
                          ),
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : DuukaColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),

                  // Refund Amount
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.errorBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: DuukaColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Refund Amount',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.error,
                          ),
                        ),
                        Text(
                          selectedRefundType == RefundType.noRefund
                              ? 'UGX 0'
                              : DuukaFormatters.currency(refundAmount),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: DuukaColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Process Button
                  DuukaButton.primary(
                    label: 'Process Return',
                    onPressed: () async {
                      final success = await ref
                          .read(returnsNotifierProvider.notifier)
                          .processReturn(
                            saleId: sale.id,
                            receiptNumber: sale.receiptNumber,
                            productId: item.productId,
                            productName: item.productName,
                            quantity: returnQty,
                            unit: item.unit ?? 'pcs',
                            unitPrice: item.unitPrice,
                            costPrice: item.costPrice,
                            reason: selectedReason,
                            reasonNotes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                            condition: selectedCondition,
                            refundType: selectedRefundType,
                            refundAmount: selectedRefundType == RefundType.noRefund
                                ? 0
                                : refundAmount,
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Return processed successfully'
                                  : 'Failed to process return',
                            ),
                            backgroundColor:
                                success ? DuukaColors.success : DuukaColors.error,
                          ),
                        );

                        // Refresh the returns for this sale
                        ref.invalidate(saleReturnsProvider(sale.id));
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaleItemTile extends StatelessWidget {
  final SaleItem item;
  final double returnedQuantity;
  final bool canReturn;
  final VoidCallback? onReturn;

  const _SaleItemTile({
    required this.item,
    required this.returnedQuantity,
    required this.canReturn,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final isFullyReturned = returnedQuantity >= item.quantity;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isFullyReturned
            ? DuukaColors.errorBg.withOpacity(0.5)
            : DuukaColors.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isFullyReturned ? DuukaColors.error.withOpacity(0.3) : DuukaColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isFullyReturned
                            ? DuukaColors.textSecondary
                            : DuukaColors.textPrimary,
                        decoration:
                            isFullyReturned ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${DuukaFormatters.currency(item.unitPrice)} × ${item.formattedQuantity}',
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
                    DuukaFormatters.currency(item.total),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isFullyReturned
                          ? DuukaColors.textSecondary
                          : DuukaColors.textPrimary,
                      decoration:
                          isFullyReturned ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (returnedQuantity > 0)
                    Text(
                      'Returned: ${returnedQuantity.toStringAsFixed(returnedQuantity == returnedQuantity.toInt() ? 0 : 2)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: DuukaColors.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (canReturn) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReturn,
                icon: Icon(Icons.assignment_return, size: 16.sp),
                label: Text('Return Item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DuukaColors.warning,
                  side: BorderSide(color: DuukaColors.warning),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReturnTile extends StatelessWidget {
  final ProductReturn productReturn;

  const _ReturnTile({required this.productReturn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: DuukaColors.warningBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: DuukaColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_return, color: DuukaColors.warning, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productReturn.productName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${productReturn.formattedQuantity} • ${productReturn.reason.label}',
                  style: TextStyle(
                    fontSize: 11.sp,
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
                '-${DuukaFormatters.currency(productReturn.refundAmount)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.error,
                ),
              ),
              if (productReturn.isRestocked)
                Text(
                  'Restocked ✓',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: DuukaColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
