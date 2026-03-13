import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../widgets/home/sales_summary_card.dart';
import '../../widgets/home/quick_action_button.dart';
import '../../widgets/home/low_stock_alert.dart';
import '../../widgets/home/recent_sale_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/sync_status_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/sync_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isAmountVisible = false;

  void _toggleAmountVisibility() {
    setState(() {
      _isAmountVisible = !_isAmountVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayStatsAsync = ref.watch(todayStatsProvider);
    final recentSalesAsync = ref.watch(recentSalesProvider(limit: 5));
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final businessAsync = ref.watch(businessNotifierProvider);
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    return Scaffold(
      backgroundColor: DuukaColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(recentSalesProvider);
          ref.invalidate(lowStockProductsProvider);
          // Also trigger sync on pull-to-refresh
          ref.read(syncProvider.notifier).sync();
        },
        child: CustomScrollView(
          slivers: [
            // Custom Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: DuukaColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DuukaFormatters.greeting()} 👋',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  businessAsync.when(
                                    data: (business) => Text(
                                      business?.name ?? DuukaStrings.appName,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    loading: () => const SizedBox(),
                                    error: (_, __) => const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Sync status icon
                                const SyncStatusIndicator(),
                                SizedBox(
                                  width: 36.w,
                                  height: 36.h,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.notifications_outlined,
                                      size: 22.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36.w,
                                  height: 36.h,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => context.push('/settings'),
                                    icon: Icon(
                                      Icons.settings_outlined,
                                      size: 22.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Sales Summary Card - Shows Cash at Hand (actual money received)
                  todayStatsAsync.when(
                    data: (stats) => SalesSummaryCard(
                      amount: stats.cashAtHand,
                      creditOutstanding: stats.creditOutstanding,
                      totalSales: stats.total,
                      refunded: stats.refunded,
                      percentageChange: stats.percentageChange,
                      onTap: isOwner ? () => context.push('/reports') : null,
                      isAmountVisible: _isAmountVisible,
                      onToggleVisibility: _toggleAmountVisibility,
                    ),
                    loading: () => Container(
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: DuukaColors.primaryBg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                  SizedBox(height: 16.h),

                  // Quick Actions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 1.15,
                    children: [
                      QuickActionButton(
                        icon: Icons.shopping_cart_outlined,
                        label: DuukaStrings.newSale,
                        color: DuukaColors.success,
                        onTap: () => context.push('/sale'),
                      ),
                      QuickActionButton(
                        icon: Icons.description_outlined,
                        label: 'Invoices',
                        color: DuukaColors.info,
                        onTap: () => context.push('/invoices'),
                      ),
                      QuickActionButton(
                        icon: Icons.inventory_2_outlined,
                        label: DuukaStrings.stockIn,
                        color: Colors.teal,
                        onTap: () => context.push('/inventory/add'),
                      ),
                      QuickActionButton(
                        icon: Icons.receipt_long,
                        label: 'Expenses',
                        color: DuukaColors.warning,
                        onTap: () => context.push('/expenses'),
                      ),
                      QuickActionButton(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Debtors',
                        color: Colors.red,
                        onTap: () => context.push('/debtors'),
                      ),
                      // Reports - Only visible to owners
                      if (isOwner)
                        QuickActionButton(
                          icon: Icons.assessment_outlined,
                          label: DuukaStrings.reports,
                          color: Colors.purple,
                          onTap: () => context.push('/reports'),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Low Stock Alert
                  lowStockAsync.when(
                    data: (products) {
                      if (products.isEmpty) return const SizedBox();
                      return Column(
                        children: [
                          LowStockAlert(
                            itemCount: products.length,
                            itemNames: products.map((p) => p.name).toList(),
                            onTap: () => context.push('/inventory'),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),

                  // Recent Sales Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DuukaStrings.recentSales,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/sales'),
                        child: Text(
                          DuukaStrings.seeAll,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Recent Sales List
                  recentSalesAsync.when(
                    data: (sales) {
                      if (sales.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No sales yet',
                          description: 'Record your first sale to see it here',
                          actionLabel: DuukaStrings.newSale,
                          onAction: () => context.push('/sale'),
                        );
                      }
                      return Column(
                        children: sales
                            .map((sale) => RecentSaleTile(sale: sale))
                            .toList(),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => const EmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load sales',
                      description: 'Please try again',
                    ),
                  ),
                  SizedBox(height: 60.h), // Bottom nav padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
