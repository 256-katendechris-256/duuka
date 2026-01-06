import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/sale_provider.dart';

/// Cart item tile with quantity controls
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onRemove;

  const CartItemTile({
    Key? key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  DuukaFormatters.currency(item.unitPrice),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: DuukaColors.border, width: 1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                // Decrease Button
                InkWell(
                  onTap: () {
                    if (item.quantity > 1) {
                      onQuantityChanged?.call(item.quantity - 1);
                    }
                  },
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    child: Icon(
                      Icons.remove,
                      size: 16.sp,
                      color: item.quantity > 1
                          ? DuukaColors.textPrimary
                          : DuukaColors.textHint,
                    ),
                  ),
                ),

                // Quantity
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                ),

                // Increase Button
                InkWell(
                  onTap: () {
                    onQuantityChanged?.call(item.quantity + 1);
                  },
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    child: Icon(
                      Icons.add,
                      size: 16.sp,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),

          // Line Total
          SizedBox(
            width: 80.w,
            child: Text(
              DuukaFormatters.currency(item.total),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8.w),

          // Remove Button
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.delete_outline,
              size: 20.sp,
              color: DuukaColors.error,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
          ),
        ],
      ),
    );
  }
}
