import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_text_field.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/sale/cart_summary_bar.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';

class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showQuantityDialog(BuildContext context, WidgetRef ref, Product product, double currentQuantity) {
    // For measurable products, show a different dialog with text input
    if (product.isMeasurable) {
      _showMeasurableQuantityDialog(context, ref, product, currentQuantity);
    } else {
      _showRegularQuantityDialog(context, ref, product, currentQuantity.toInt());
    }
  }

  void _showMeasurableQuantityDialog(BuildContext context, WidgetRef ref, Product product, double currentQuantity) {
    final quantityController = TextEditingController(
      text: currentQuantity > 0 ? currentQuantity.toString() : '',
    );
    double quantity = currentQuantity > 0 ? currentQuantity : 0;
    String? stockError;
    final availableStock = product.safeStockQuantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.w,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: DuukaColors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Product info
                  Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: DuukaColors.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.scale,
                            size: 28.sp,
                            color: DuukaColors.primary,
                          ),
                        ),
                      ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: DuukaColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${DuukaFormatters.currency(product.sellPrice)} per ${product.displayUnit}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                
                // Stock available
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: product.safeStockQuantity > 10
                        ? DuukaColors.successBg
                        : product.safeStockQuantity > 0
                            ? DuukaColors.warningBg
                            : DuukaColors.errorBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${product.formatQuantity(product.safeStockQuantity)} available',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: product.safeStockQuantity > 10
                          ? DuukaColors.success
                          : product.safeStockQuantity > 0
                              ? DuukaColors.warning
                              : DuukaColors.error,
                    ),
                  ),
                ),

                // Specifications (read-only display)
                if (product.specifications.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildSpecsDisplay(product),
                ],
                SizedBox(height: 24.h),

                // Measurement input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.0',
                          hintStyle: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            color: DuukaColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: DuukaColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: DuukaColors.primary, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            quantity = double.tryParse(value) ?? 0;
                            if (quantity > availableStock) {
                              stockError = 'Only ${product.formatQuantity(availableStock)} available';
                            } else {
                              stockError = null;
                            }
                          });
                        },
                        autofocus: true,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                      decoration: BoxDecoration(
                        color: DuukaColors.primaryBg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        product.displayUnit.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // Stock error message
                if (stockError != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: DuukaColors.errorBg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: DuukaColors.error, size: 18.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            stockError!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Quick measurement buttons
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [0.25, 0.5, 1.0, 1.5, 2.0, 5.0].where((val) => val <= availableStock).map((val) {
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          quantity = val;
                          quantityController.text = val.toString();
                          stockError = null;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: quantity == val ? DuukaColors.primary : DuukaColors.background,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: quantity == val ? DuukaColors.primary : DuukaColors.border,
                          ),
                        ),
                        child: Text(
                          '$val ${product.displayUnit}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: quantity == val ? Colors.white : DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                
                // Line total
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.primaryBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Total',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      Text(
                        DuukaFormatters.currency(product.sellPrice * quantity),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Action buttons
                Row(
                  children: [
                    if (currentQuantity > 0)
                      Expanded(
                        child: DuukaButton.secondary(
                          label: 'Remove',
                          icon: Icons.delete_outline,
                          onPressed: () {
                            ref.read(cartProvider.notifier).removeItem(product.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    if (currentQuantity > 0) SizedBox(width: 12.w),
                    Expanded(
                      flex: currentQuantity > 0 ? 1 : 2,
                      child: DuukaButton.primary(
                        label: currentQuantity > 0
                            ? (quantity == 0 ? 'Remove' : 'Update')
                            : 'Add to Cart',
                        onPressed: (quantity > 0 || currentQuantity > 0) && stockError == null ? () {
                          if (quantity == 0) {
                            ref.read(cartProvider.notifier).removeItem(product.id);
                          } else if (quantity > availableStock) {
                            // Don't allow - show error
                            setModalState(() {
                              stockError = 'Only ${product.formatQuantity(availableStock)} available';
                            });
                            return;
                          } else if (currentQuantity == 0) {
                            ref.read(cartProvider.notifier).addItem(product, quantity: quantity);
                          } else {
                            ref.read(cartProvider.notifier).updateQuantity(product.id, quantity);
                          }
                          Navigator.pop(context);
                        } : null,
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRegularQuantityDialog(BuildContext context, WidgetRef ref, Product product, int currentQuantity) {
    int quantity = currentQuantity == 0 ? 1 : currentQuantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.w,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: DuukaColors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Product info
                  Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: DuukaColors.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            _getProductEmoji(product.category),
                            style: TextStyle(fontSize: 28.sp),
                          ),
                        ),
                      ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: DuukaColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            DuukaFormatters.currency(product.sellPrice),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                
                // Stock available
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: product.safeStockQuantity > 10
                        ? DuukaColors.successBg
                        : product.safeStockQuantity > 0
                            ? DuukaColors.warningBg
                            : DuukaColors.errorBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${product.safeStockQuantity.toInt()} ${product.unit} available',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: product.safeStockQuantity > 10
                          ? DuukaColors.success
                          : product.safeStockQuantity > 0
                              ? DuukaColors.warning
                              : DuukaColors.error,
                    ),
                  ),
                ),

                // Specifications (read-only display)
                if (product.specifications.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildSpecsDisplay(product),
                ],
                SizedBox(height: 24.h),

                // Quantity controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decrease button
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: quantity > 0
                          ? () => setModalState(() => quantity--)
                          : null,
                      isEnabled: quantity > 0,
                    ),
                    
                    // Quantity display
                    Container(
                      width: 100.w,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Increase button
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: quantity < product.safeStockQuantity
                          ? () => setModalState(() => quantity++)
                          : null,
                      isEnabled: quantity < product.safeStockQuantity,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                
                // Line total
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.primaryBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Total',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      Text(
                        DuukaFormatters.currency(product.sellPrice * quantity),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Action buttons
                Row(
                  children: [
                    // Remove button (only show if item is in cart)
                    if (currentQuantity > 0)
                      Expanded(
                        child: DuukaButton.secondary(
                          label: 'Remove',
                          icon: Icons.delete_outline,
                          onPressed: () {
                            ref.read(cartProvider.notifier).removeItem(product.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    if (currentQuantity > 0) SizedBox(width: 12.w),
                    
                    // Add/Update button
                    Expanded(
                      flex: currentQuantity > 0 ? 1 : 2,
                      child: DuukaButton.primary(
                        label: currentQuantity > 0
                            ? (quantity == 0 ? 'Remove' : 'Update')
                            : 'Add to Cart',
                        onPressed: quantity <= product.safeStockQuantity ? () {
                          if (quantity == 0) {
                            ref.read(cartProvider.notifier).removeItem(product.id);
                          } else if (quantity > product.safeStockQuantity) {
                            // Double-check - shouldn't happen
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Only ${product.safeStockQuantity.toInt()} available in stock'),
                                backgroundColor: DuukaColors.error,
                              ),
                            );
                            return;
                          } else if (currentQuantity == 0) {
                            ref.read(cartProvider.notifier).addItem(product, quantity: quantity.toDouble());
                          } else {
                            ref.read(cartProvider.notifier).updateQuantity(product.id, quantity.toDouble());
                          }
                          Navigator.pop(context);
                        } : null,
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build read-only specifications display
  Widget _buildSpecsDisplay(Product product) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: DuukaColors.primaryBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.primary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            product.specifications.map((s) => '${s.name}: ${s.value}').join(' | '),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: DuukaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(
      _searchQuery.isEmpty
          ? productsByCategoryProvider(selectedCategory)
          : productSearchProvider(_searchQuery),
    );
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: DuukaAppBar(
        title: DuukaStrings.newSale,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Open barcode scanner
            },
            icon: Icon(Icons.qr_code_scanner, size: 24.sp),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: DuukaTextField.search(
              hint: DuukaStrings.searchProducts,
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category Filter Pills
          if (_searchQuery.isEmpty)
            categoriesAsync.when(
              data: (categories) => SizedBox(
                height: 40.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .select(category);
                        },
                        backgroundColor: DuukaColors.surface,
                        selectedColor: DuukaColors.primaryBg,
                        labelStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? DuukaColors.primary
                              : DuukaColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? DuukaColors.primary
                              : DuukaColors.border,
                        ),
                      ),
                    );
                  },
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

          SizedBox(height: 16.h),

          // Product Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    description: _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add products to start selling',
                    actionLabel: 'Add Product',
                    onAction: () => context.push('/inventory/add'),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final cartItem = cartState.items.firstWhere(
                      (item) => item.productId == product.id,
                      orElse: () => CartItem(
                        productId: -1,
                        productName: '',
                        unitPrice: 0,
                        costPrice: 0,
                      ),
                    );
                    final isInCart = cartItem.productId != -1;

                    return Stack(
                      children: [
                        ProductCard(
                          product: product,
                          isSelected: isInCart,
                          onTap: () {
                            _showQuantityDialog(context, ref, product, isInCart ? cartItem.quantity : 0);
                          },
                        ),
                        if (isInCart)
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: GestureDetector(
                              onTap: () {
                                _showQuantityDialog(context, ref, product, cartItem.quantity);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: DuukaColors.primary,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  cartItem.isMeasurable 
                                      ? cartItem.formattedQuantity
                                      : '${cartItem.quantity.toInt()}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load products',
                description: 'Please try again',
              ),
            ),
          ),
        ],
      ),

      // Floating Cart Summary Bar
      bottomNavigationBar: cartState.isNotEmpty
          ? CartSummaryBar(
              itemCount: cartState.itemCount,
              total: cartState.total,
              onCheckout: () => context.push('/sale/cart'),
            )
          : null,
    );
  }
}

// Quantity control button widget
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _QuantityButton({
    required this.icon,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 56.h,
        decoration: BoxDecoration(
          color: isEnabled ? DuukaColors.primary : DuukaColors.border,
          shape: BoxShape.circle,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: DuukaColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : DuukaColors.textHint,
          size: 28.sp,
        ),
      ),
    );
  }
}
