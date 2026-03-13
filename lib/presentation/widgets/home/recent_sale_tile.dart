import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

/// List tile for recent sales
class RecentSaleTile extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const RecentSaleTile({
    Key? key,
    required this.sale,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstItem = sale.items.isNotEmpty ? sale.items.first : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: DuukaColors.successBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 20.sp,
                color: DuukaColors.success,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _buildItemText(firstItem, sale.itemCount),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: DuukaColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _buildSubtitle(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              '+${DuukaFormatters.number(sale.total)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildItemText(SaleItem? firstItem, int totalItems) {
    if (firstItem == null) return 'Sale';

    String text = firstItem.productName;
    if (firstItem.quantity > 1) {
      text += ' × ${firstItem.quantity}';
    }
    if (totalItems > 1) {
      text += ' +${totalItems - 1} more';
    }
    return text;
  }

  String _buildSubtitle() {
    final time = DuukaFormatters.time(sale.createdAt);
    final method = _getPaymentMethodLabel(sale.paymentMethod);
    return '$time • $method';
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }
}
