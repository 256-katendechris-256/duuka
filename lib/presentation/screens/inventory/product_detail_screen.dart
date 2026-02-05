import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../providers/product_provider.dart';
import 'add_product_screen.dart';
import '../../widgets/inventory/stock_adjustment_dialog.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isLoading = false;

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: DuukaColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(productsProvider.notifier)
          .deleteProduct(widget.productId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: DuukaColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStockAdjustment(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StockAdjustmentDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: DuukaColors.background,
        appBar: DuukaAppBar(
          title: 'Product Details',
          actions: [
            IconButton(
              onPressed: () {
                productAsync.whenData((product) {
                  if (product != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(product: product),
                      ),
                    );
                  }
                });
              },
              icon: Icon(Icons.edit, size: 24.sp),
            ),
            IconButton(
              onPressed: _deleteProduct,
              icon: Icon(
                Icons.delete,
                size: 24.sp,
                color: DuukaColors.error,
              ),
            ),
          ],
        ),
        body: productAsync.when(
          data: (product) {
            if (product == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.sp,
                      color: DuukaColors.error,
                    ),
                    SizedBox(height: 16.h),
                    const Text('Product not found'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: DuukaColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: DuukaColors.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        // Product Image/Emoji
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                          child: _buildProductImage(product),
                        ),
                        
                        Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            children: [
                              // Product Name
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: DuukaColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12.h),
                              
                              // Tags Row (Category, Size, Color)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  if (product.category != null) 
                                    _buildTag(
                                      product.category!,
                                      DuukaColors.primaryBg,
                                      DuukaColors.primary,
                                    ),
                                  if (product.size != null)
                                    _buildTag(
                                      product.size!,
                                      DuukaColors.surface,
                                      DuukaColors.textSecondary,
                                      hasBorder: true,
                                    ),
                                  if (product.color != null && product.color!.isNotEmpty)
                                    _buildColorTag(product.color!),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Stock Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: _getStockColor(product).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _getStockColor(product).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStockIcon(product),
                          size: 24.sp,
                          color: _getStockColor(product),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Stock',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: DuukaColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                product.formatQuantity(product.safeStockQuantity),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _getStockColor(product),
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _showStockAdjustment(product),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DuukaColors.primary,
                            side: BorderSide(color: DuukaColors.primary, width: 1.5),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Adjust Stock',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Details Section
                  _buildSectionHeader('Product Information'),
                  SizedBox(height: 12.h),
                  _buildDetailCard([
                    if (product.barcode != null)
                      _DetailRow(label: 'Barcode', value: product.barcode!),
                    _DetailRow(
                      label: 'Cost Price',
                      value: DuukaFormatters.currency(product.costPrice),
                    ),
                    _DetailRow(
                      label: 'Sell Price',
                      value: DuukaFormatters.currency(product.sellPrice),
                    ),
                    _DetailRow(
                      label: 'Profit Margin',
                      value: '${product.profitMargin.toStringAsFixed(1)}%',
                      valueColor: DuukaColors.success,
                    ),
                    _DetailRow(
                      label: 'Stock Value',
                      value: DuukaFormatters.currency(product.stockValue),
                      valueColor: DuukaColors.primary,
                    ),
                    _DetailRow(
                      label: 'Reorder Level',
                      value: '${product.reorderLevel} ${product.unit}',
                    ),
                  ]),
                  SizedBox(height: 20.h),

                  // Timestamps Section
                  _buildSectionHeader('Timestamps'),
                  SizedBox(height: 12.h),
                  _buildDetailCard([
                    _DetailRow(
                      label: 'Created',
                      value: DuukaFormatters.dateTime(product.createdAt),
                    ),
                    _DetailRow(
                      label: 'Last Updated',
                      value: DuukaFormatters.dateTime(product.updatedAt),
                    ),
                  ]),
                  SizedBox(height: 80.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48.sp,
                  color: DuukaColors.error,
                ),
                SizedBox(height: 16.h),
                const Text('Failed to load product'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: DuukaColors.textPrimary,
      ),
    );
  }

  Widget _buildDetailCard(List<_DetailRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border, width: 1),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: rows[i].valueColor ?? DuukaColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(
                height: 1.h,
                thickness: 1,
                color: DuukaColors.border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    // If product has custom image
    if (product.hasCustomImage) {
      final file = File(product.photoPath!);
      if (file.existsSync()) {
        return Container(
          width: double.infinity,
          height: 180.h,
          decoration: BoxDecoration(
            color: DuukaColors.background,
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildEmojiDisplay(product.category);
            },
          ),
        );
      }
    }
    
    // If product has color
    if (product.color != null && product.color!.isNotEmpty) {
      final color = _parseProductColor(product.color!);
      if (color != null) {
        return Container(
          width: double.infinity,
          height: 120.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 64.w,
              height: 64.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 28.sp,
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
    
    return _buildEmojiDisplay(product.category);
  }
  
  Widget _buildEmojiDisplay(String? category) {
    return Container(
      width: double.infinity,
      height: 100.h,
      color: DuukaColors.background,
      child: Center(
        child: Text(
          _getProductEmoji(category),
          style: TextStyle(fontSize: 48.sp),
        ),
      ),
    );
  }
  
  Widget _buildTag(String text, Color bgColor, Color textColor, {bool hasBorder = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: hasBorder ? Border.all(color: DuukaColors.border, width: 1) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
  
  Widget _buildColorTag(String colorString) {
    final color = _parseProductColor(colorString);
    if (color == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: DuukaColors.border, width: 1),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            colorString,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Color? _parseProductColor(String colorString) {
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

  String _getProductEmoji(String? category) {
    final cat = category?.toLowerCase() ?? '';
    if (cat.contains('beverage') || cat.contains('drink')) return '🥤';
    if (cat.contains('food')) return '🍎';
    if (cat.contains('clean')) return '🧼';
    if (cat.contains('personal')) return '🧴';
    if (cat.contains('electron')) return '📱';
    if (cat.contains('station')) return '✏️';
    return '📦';
  }

  Color _getStockColor(Product product) {
    if (product.isLowStock) return DuukaColors.error;
    if (product.safeStockQuantity < product.reorderLevel * 2) return DuukaColors.warning;
    return DuukaColors.success;
  }

  IconData _getStockIcon(Product product) {
    if (product.isLowStock) return Icons.warning_amber_rounded;
    if (product.safeStockQuantity < product.reorderLevel * 2) return Icons.info_outline;
    return Icons.check_circle_outline;
  }
}

class _DetailRow {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
}
