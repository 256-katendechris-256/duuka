import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/duuka_text_field.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/product/product_list_tile.dart';
import '../../widgets/inventory/inventory_stats_card.dart';
import '../../providers/product_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryStatsAsync = ref.watch(inventoryStatsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(
      _searchQuery.isEmpty
          ? productsByCategoryProvider(selectedCategory)
          : productSearchProvider(_searchQuery),
    );

    return Scaffold(
      backgroundColor: DuukaColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryStatsProvider);
          ref.invalidate(productCategoriesProvider);
          ref.invalidate(productsByCategoryProvider);
          ref.invalidate(productSearchProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: DuukaColors.surface,
              title: Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/inventory/bulk-upload'),
                  icon: Icon(
                    Icons.upload_file,
                    size: 24.sp,
                    color: DuukaColors.textPrimary,
                  ),
                  tooltip: 'Bulk Upload',
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Open barcode scanner
                  },
                  icon: Icon(
                    Icons.qr_code_scanner,
                    size: 24.sp,
                    color: DuukaColors.textPrimary,
                  ),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),

            // Inventory Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: inventoryStatsAsync.when(
                  data: (stats) => InventoryStatsCard(stats: stats),
                  loading: () => Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: DuukaColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            ),

            // Category Filter Pills
            if (_searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (categories) => SizedBox(
                    height: 50.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
              ),

            // Products List
            SliverPadding(
              padding: EdgeInsets.only(bottom: 80.h),
              sliver: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products found',
                        description: _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Add your first product to get started',
                        actionLabel: 'Add Product',
                        onAction: () => context.push('/inventory/add'),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return Column(
                          children: [
                            ProductListTile(
                              product: product,
                              onTap: () => context.push('/inventory/${product.id}'),
                            ),
                            if (index < products.length - 1)
                              Divider(
                                height: 1.h,
                                thickness: 1,
                                color: DuukaColors.border,
                                indent: 84.w,
                              ),
                          ],
                        );
                      },
                      childCount: products.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Failed to load products',
                    description: 'Please try again',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/add'),
        backgroundColor: DuukaColors.primary,
        icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
        label: Text(
          'Add Product',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
