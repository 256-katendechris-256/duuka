import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

/// List tile for inventory screen
class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductListTile({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Product Image/Emoji
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: DuukaColors.background,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Text(
                  _getProductEmoji(),
                  style: TextStyle(fontSize: 28.sp),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (product.category != null) ...[
                        Text(
                          product.category!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getStockColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${product.quantity} ${product.unit}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStockColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Stock Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DuukaFormatters.currency(product.sellPrice),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Value: ${DuukaFormatters.currencyShort(product.stockValue)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getProductEmoji() {
    final category = product.category?.toLowerCase() ?? '';
    if (category.contains('beverage') || category.contains('drink')) return '🥤';
    if (category.contains('food')) return '🍎';
    if (category.contains('clean')) return '🧼';
    if (category.contains('personal')) return '🧴';
    if (category.contains('electron')) return '📱';
    if (category.contains('station')) return '✏️';
    return '📦';
  }

  Color _getStockColor() {
    if (product.isLowStock) return DuukaColors.error;
    if (product.quantity < product.reorderLevel * 2) return DuukaColors.warning;
    return DuukaColors.success;
  }
}
