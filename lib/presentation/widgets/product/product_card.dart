import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

/// Grid card for product used in Quick Sale screen
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? DuukaColors.primary : DuukaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image/Emoji
            Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: DuukaColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              ),
              child: Center(
                child: Text(
                  _getProductEmoji(),
                  style: TextStyle(fontSize: 40.sp),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Stock Count
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
                  SizedBox(height: 8.h),

                  // Price
                  Text(
                    DuukaFormatters.currency(product.sellPrice),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductEmoji() {
    // Return emoji based on category or default
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
