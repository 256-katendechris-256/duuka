import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_text_field.dart';
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
                            ref.read(cartProvider.notifier).addItem(product);
                          },
                        ),
                        if (isInCart)
                          Positioned(
                            top: 8.h,
                            right: 8.w,
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
                                '${cartItem.quantity}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
              onCheckout: () => context.push('/cart'),
            )
          : null,
    );
  }
}
