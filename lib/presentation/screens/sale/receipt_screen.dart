import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_button.dart';

class ReceiptScreen extends ConsumerWidget {
  final Sale sale;

  const ReceiptScreen({
    Key? key,
    required this.sale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share receipt
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Print receipt
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: DuukaColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48.sp,
                color: DuukaColors.success,
              ),
            ),
            SizedBox(height: 16.h),

            Text(
              'Sale Complete!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),

            Text(
              sale.receiptNumber,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),

            // Receipt Card
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: DuukaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        DuukaStrings.appName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      Text(
                        DuukaFormatters.dateTime(sale.createdAt),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      Divider(color: DuukaColors.divider),
                      SizedBox(height: 16.h),

                      // Items List
                      Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      ...sale.items.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: DuukaColors.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: DuukaColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${DuukaFormatters.currency(item.unitPrice)} each',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: DuukaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DuukaFormatters.currency(item.total),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: DuukaColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),

                      SizedBox(height: 16.h),
                      Divider(color: DuukaColors.divider),
                      SizedBox(height: 16.h),

                      // Summary
                      _SummaryRow(
                        label: 'Subtotal',
                        value: DuukaFormatters.currency(sale.subtotal),
                      ),
                      if (sale.discountAmount > 0) ...[
                        SizedBox(height: 8.h),
                        _SummaryRow(
                          label: 'Discount',
                          value: '-${DuukaFormatters.currency(sale.discountAmount)}',
                          valueColor: DuukaColors.error,
                        ),
                      ],
                      SizedBox(height: 8.h),
                      _SummaryRow(
                        label: 'Total',
                        value: DuukaFormatters.currency(sale.total),
                        isTotal: true,
                      ),
                      SizedBox(height: 16.h),

                      Divider(color: DuukaColors.divider),
                      SizedBox(height: 16.h),

                      // Payment Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                          Text(
                            _paymentMethodName(sale.paymentMethod),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Status',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _paymentStatusColor(sale.paymentStatus)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              _paymentStatusName(sale.paymentStatus),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: _paymentStatusColor(sale.paymentStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  DuukaButton.primary(
                    label: 'New Sale',
                    onPressed: () => context.go('/sale'),
                  ),
                  SizedBox(height: 12.h),
                  DuukaButton.secondary(
                    label: 'Back to Home',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  String _paymentStatusName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partially Paid';
    }
  }

  Color _paymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return DuukaColors.success;
      case PaymentStatus.pending:
        return DuukaColors.warning;
      case PaymentStatus.partial:
        return DuukaColors.info;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _SummaryRow({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: DuukaColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ??
                (isTotal ? DuukaColors.primary : DuukaColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
