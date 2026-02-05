import 'dart:io';

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
            // Product Image/Color/Emoji
            _buildProductThumbnail(),
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
                      // Flexible section for size and category
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.size != null) ...[
                              Flexible(
                                child: Text(
                                  product.size!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: DuukaColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                            if (product.category != null) ...[
                              Flexible(
                                child: Text(
                                  product.category!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: DuukaColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          ],
                        ),
                      ),
                      // Stock badge - fixed size
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getStockColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          product.formatQuantity(product.safeStockQuantity),
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

  Widget _buildProductThumbnail() {
    // Priority 1: Custom photo
    if (product.hasCustomImage) {
      final file = File(product.photoPath!);
      if (file.existsSync()) {
        return Container(
          width: 56.w,
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildEmojiThumbnail();
              },
            ),
          ),
        );
      }
    }
    
    // Priority 2: Color swatch
    if (product.color != null && product.color!.isNotEmpty) {
      final color = _parseProductColor();
      if (color != null) {
        return Container(
          width: 56.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    // Priority 3: Emoji fallback
    return _buildEmojiThumbnail();
  }
  
  Widget _buildEmojiThumbnail() {
    return Container(
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
    );
  }
  
  Color? _parseProductColor() {
    if (product.color == null || product.color!.isEmpty) return null;
    
    final colorString = product.color!;
    if (colorString.startsWith('#')) {
      try {
        final hex = colorString.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        return null;
      }
    }
    return null;
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
    if (product.safeStockQuantity < product.reorderLevel * 2) return DuukaColors.warning;
    return DuukaColors.success;
  }
}
