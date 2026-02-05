import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';

class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    // Redirect non-owners to home
    if (!isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final statsAsync = ref.watch(inventoryStatsProvider);
    final productsAsync = ref.watch(productsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Inventory Report',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryStatsProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              statsAsync.when(
                data: (stats) => _buildSummaryCards(stats),
                loading: () => _buildLoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(height: 24.h),

              // Low Stock Alert
              lowStockAsync.when(
                data: (products) {
                  if (products.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, 
                               color: DuukaColors.warning, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Low Stock Items (${products.length})',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: DuukaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _buildLowStockList(products),
                      SizedBox(height: 24.h),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Stock Value by Category
              Text(
                'Stock by Category',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              productsAsync.when(
                data: (products) => _buildCategoryBreakdown(products),
                loading: () => _buildLoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(height: 24.h),

              // All Products Stock Level
              Text(
                'All Products',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              productsAsync.when(
                data: (products) => _buildAllProductsList(products, context),
                loading: () => _buildLoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(InventoryStats stats) {
    return Column(
      children: [
        // Main value card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: DuukaColors.primaryGradient,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Icon(Icons.inventory_2, size: 32.sp, color: Colors.white70),
              SizedBox(height: 8.h),
              Text(
                'Total Inventory Value',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                DuukaFormatters.currency(stats.totalValue),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Products',
                value: stats.totalItems.toString(),
                icon: Icons.category,
                color: DuukaColors.info,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                label: 'Low Stock',
                value: stats.lowStockCount.toString(),
                icon: Icons.warning_amber,
                color: stats.lowStockCount > 0 
                    ? DuukaColors.warning 
                    : DuukaColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLowStockList(List products) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.warning.withOpacity(0.3)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length > 5 ? 5 : products.length,
        separatorBuilder: (_, __) => Divider(
          height: 1, 
          color: DuukaColors.warning.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: DuukaColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  product.formatQuantity(product.safeStockQuantity),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.warning,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Min: ${product.reorderLevel}',
              style: TextStyle(fontSize: 12.sp),
            ),
            trailing: Text(
              'Reorder needed',
              style: TextStyle(
                fontSize: 11.sp,
                color: DuukaColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryBreakdown(List products) {
    // Group products by category
    final Map<String, Map<String, dynamic>> categoryData = {};

    for (final product in products) {
      final category = product.category.isEmpty ? 'Uncategorized' : product.category;
      if (!categoryData.containsKey(category)) {
        categoryData[category] = {
          'count': 0,
          'value': 0.0,
          'quantity': 0,
        };
      }
      categoryData[category]!['count'] = categoryData[category]!['count'] + 1;
      categoryData[category]!['value'] = 
          categoryData[category]!['value'] + (product.sellPrice * product.safeStockQuantity);
      categoryData[category]!['quantity'] = 
          categoryData[category]!['quantity'] + product.safeStockQuantity;
    }

    if (categoryData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No products in inventory',
            style: TextStyle(color: DuukaColors.textSecondary),
          ),
        ),
      );
    }

    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => (b.value['value'] as double).compareTo(a.value['value'] as double));

    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedCategories.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: DuukaColors.border),
        itemBuilder: (context, index) {
          final entry = sortedCategories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(index).withOpacity(0.1),
              child: Icon(
                Icons.category,
                color: _getCategoryColor(index),
                size: 18.sp,
              ),
            ),
            title: Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Text(
              '${entry.value['count']} products • ${entry.value['quantity']} units',
              style: TextStyle(fontSize: 12.sp),
            ),
            trailing: Text(
              DuukaFormatters.currencyCompact(entry.value['value']),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllProductsList(List products, BuildContext context) {
    if (products.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No products',
            style: TextStyle(color: DuukaColors.textSecondary),
          ),
        ),
      );
    }

    // Sort by value (price * quantity)
    final sortedProducts = List.from(products)
      ..sort((a, b) => 
        (b.sellPrice * b.quantity).compareTo(a.sellPrice * a.quantity));

    final displayProducts = sortedProducts.length > 10 
        ? sortedProducts.sublist(0, 10) 
        : sortedProducts;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: DuukaColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayProducts.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: DuukaColors.border),
            itemBuilder: (context, index) {
              final product = displayProducts[index];
              final stockValue = product.sellPrice * product.safeStockQuantity;
              final isLowStock = product.isLowStock;

              return ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isLowStock 
                        ? DuukaColors.warning.withOpacity(0.1)
                        : DuukaColors.primaryBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      product.formatQuantity(product.safeStockQuantity),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isLowStock ? DuukaColors.warning : DuukaColors.primary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${DuukaFormatters.currency(product.sellPrice)} each',
                  style: TextStyle(fontSize: 12.sp),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DuukaFormatters.currencyCompact(stockValue),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isLowStock)
                      Text(
                        'Low stock',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: DuukaColors.warning,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (products.length > 10) ...[
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => context.push('/inventory'),
            child: Text(
              'View all ${products.length} products',
              style: TextStyle(
                color: DuukaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      DuukaColors.primary,
      DuukaColors.success,
      DuukaColors.info,
      DuukaColors.warning,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: DuukaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
