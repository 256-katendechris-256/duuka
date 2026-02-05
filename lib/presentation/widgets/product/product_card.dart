import 'dart:io';

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
            // Product Image - Larger
            Container(
              height: 100.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
                child: _buildProductImage(),
              ),
            ),

            // Product Info
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Stock on same row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getStockColor().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          product.formatQuantity(product.safeStockQuantity),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStockColor(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Specifications (if any)
                  if (product.specifications.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      product.specifications
                          .map((s) => '${s.name}: ${s.value}')
                          .join(' | '),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: DuukaColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: 6.h),

                  // Price
                  Text(
                    DuukaFormatters.currency(product.sellPrice),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
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

  Widget _buildProductImage() {
    // Priority 1: Custom photo
    if (product.hasCustomImage) {
      final file = File(product.photoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackDisplay();
          },
        );
      }
    }
    
    // Priority 2: Color swatch with product initial
    if (product.color != null && product.color!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: _parseProductColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_parseProductColor() ?? DuukaColors.primary).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _getContrastColor(_parseProductColor()),
                  ),
                ),
              ),
            ),
            if (product.size != null && product.size!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: DuukaColors.surface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  product.size!,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // Priority 3: Emoji fallback
    return _buildFallbackDisplay();
  }
  
  Widget _buildFallbackDisplay() {
    return Center(
      child: Text(
        _getProductEmoji(),
        style: TextStyle(fontSize: 40.sp),
      ),
    );
  }
  
  Color _getBackgroundColor() {
    // If product has a color, use a lighter version
    if (product.color != null && product.color!.isNotEmpty) {
      final color = _parseProductColor();
      if (color != null) {
        return color.withOpacity(0.15);
      }
    }
    return DuukaColors.background;
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
  
  Color _getContrastColor(Color? bgColor) {
    if (bgColor == null) return DuukaColors.textPrimary;
    return bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
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
    if (product.safeStockQuantity < product.reorderLevel * 2) return DuukaColors.warning;
    return DuukaColors.success;
  }
}
