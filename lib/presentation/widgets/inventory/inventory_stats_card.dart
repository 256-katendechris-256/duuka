import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';

class InventoryStatsCard extends StatelessWidget {
  final InventoryStats stats;

  const InventoryStatsCard({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DuukaColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Total Items
          Expanded(
            child: _StatItem(
              icon: Icons.inventory_2_outlined,
              iconColor: DuukaColors.primary,
              label: 'Total Items',
              value: '${stats.totalItems}',
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40.h,
            color: DuukaColors.border,
          ),

          // Low Stock
          Expanded(
            child: _StatItem(
              icon: Icons.warning_amber_rounded,
              iconColor: DuukaColors.warning,
              label: 'Low Stock',
              value: '${stats.lowStockCount}',
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40.h,
            color: DuukaColors.border,
          ),

          // Total Value
          Expanded(
            child: _StatItem(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: DuukaColors.success,
              label: 'Total Value',
              value: DuukaFormatters.currencyShort(stats.totalValue),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24.sp,
          color: iconColor,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: DuukaColors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: DuukaColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
