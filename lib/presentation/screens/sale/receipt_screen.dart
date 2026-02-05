import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/business_provider.dart';
import '../../widgets/common/duuka_button.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final Sale sale;

  const ReceiptScreen({
    Key? key,
    required this.sale,
  }) : super(key: key);

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);

    try {
      // Capture the receipt widget as an image
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture receipt');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${widget.sale.receiptNumber}.png');
      await file.writeAsBytes(pngBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Receipt #${widget.sale.receiptNumber}',
        text: 'Thank you for your purchase!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: $e'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessNotifierProvider);
    final businessName = businessAsync.valueOrNull?.name ?? 'My Store';

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: AppBar(
        backgroundColor: DuukaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Receipt',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: DuukaColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Receipt content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: RepaintBoundary(
                key: _receiptKey,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Receipt header with zigzag edge effect
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: DuukaColors.primary,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.r),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Business name
                            Text(
                              businessName,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.h),
                            // Receipt number
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '#${widget.sale.receiptNumber}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Success icon
                      Transform.translate(
                        offset: Offset(0, -24.h),
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: DuukaColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                        ),
                      ),

                      // Sale complete message
                      Transform.translate(
                        offset: Offset(0, -12.h),
                        child: Text(
                          'Sale Complete!',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: DuukaColors.success,
                          ),
                        ),
                      ),

                      // Date and time
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          DuukaFormatters.dateTime(widget.sale.createdAt),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Dashed divider
                      _buildDashedDivider(),

                      // Items list
                      Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ...widget.sale.items.map((item) => _buildItemRow(item)),
                          ],
                        ),
                      ),

                      // Dashed divider
                      _buildDashedDivider(),

                      // Summary
                      Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', widget.sale.subtotal),
                            if (widget.sale.discount > 0) ...[
                              SizedBox(height: 8.h),
                              _buildSummaryRow(
                                'Discount${widget.sale.discountPercent > 0 ? ' (${widget.sale.discountPercent.toStringAsFixed(0)}%)' : ''}',
                                -widget.sale.discount,
                                valueColor: DuukaColors.error,
                              ),
                            ],
                            SizedBox(height: 12.h),
                            Divider(color: DuukaColors.border),
                            SizedBox(height: 12.h),
                            _buildSummaryRow(
                              'Total',
                              widget.sale.total,
                              isTotal: true,
                            ),
                            SizedBox(height: 8.h),
                            _buildSummaryRow(
                              'Paid (${_getPaymentMethodName(widget.sale.paymentMethod)})',
                              widget.sale.amountPaid,
                            ),
                            if (widget.sale.balance > 0) ...[
                              SizedBox(height: 8.h),
                              _buildSummaryRow(
                                'Balance',
                                widget.sale.balance,
                                valueColor: DuukaColors.warning,
                              ),
                            ],
                            if (widget.sale.amountPaid > widget.sale.total) ...[
                              SizedBox(height: 8.h),
                              _buildSummaryRow(
                                'Change',
                                widget.sale.amountPaid - widget.sale.total,
                                valueColor: DuukaColors.success,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Customer info (if any)
                      if (widget.sale.customerName != null) ...[
                        _buildDashedDivider(),
                        Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 20.sp,
                                color: DuukaColors.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                widget.sale.customerName!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: DuukaColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Payment status badge
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(widget.sale.paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _getPaymentStatusColor(widget.sale.paymentStatus).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getPaymentStatusIcon(widget.sale.paymentStatus),
                              size: 18.sp,
                              color: _getPaymentStatusColor(widget.sale.paymentStatus),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _getPaymentStatusText(widget.sale.paymentStatus),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: _getPaymentStatusColor(widget.sale.paymentStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Footer message
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            Text(
                              'Thank you for your purchase!',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: DuukaColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Please keep this receipt for your records',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: DuukaColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Powered by Duuka
                      Text(
                        'Powered by Duuka',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: DuukaColors.textHint,
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Share button
                  Expanded(
                    child: DuukaButton.secondary(
                      label: 'Share Receipt',
                      icon: Icons.share,
                      onPressed: _isSharing ? null : _shareReceipt,
                      isLoading: _isSharing,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // New Sale button
                  Expanded(
                    child: DuukaButton.primary(
                      label: 'New Sale',
                      icon: Icons.add,
                      onPressed: () => context.go('/sale'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven ? DuukaColors.border : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(SaleItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity
          Container(
            width: 32.w,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: DuukaColors.primaryBg,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              item.isMeasurable
                  ? item.formattedQuantity.split(' ').first
                  : '${item.quantity.toInt()}x',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 12.w),
          // Product name, specifications, and unit price
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
                // Show specifications if present
                if (item.specifications.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.specificationsText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: DuukaColors.primary,
                    ),
                  ),
                ],
                Text(
                  item.isMeasurable
                      ? '@ ${DuukaFormatters.currency(item.unitPrice)}/${item.unit}'
                      : '@ ${DuukaFormatters.currency(item.unitPrice)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Line total
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
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: DuukaColors.textPrimary,
          ),
        ),
        Text(
          amount < 0
              ? '-${DuukaFormatters.currency(amount.abs())}'
              : DuukaFormatters.currency(amount),
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isTotal ? DuukaColors.primary : DuukaColors.textPrimary),
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return DuukaColors.success;
      case PaymentStatus.partial:
        return DuukaColors.warning;
      case PaymentStatus.unpaid:
        return DuukaColors.error;
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.partial:
        return Icons.timelapse;
      case PaymentStatus.unpaid:
        return Icons.pending;
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Fully Paid';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.unpaid:
        return 'Credit Sale';
    }
  }
}
