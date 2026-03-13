import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// Compact card showing today's cash at hand
class SalesSummaryCard extends StatelessWidget {
  final double amount;
  final double creditOutstanding;
  final double totalSales;
  final double refunded;
  final double percentageChange;
  final VoidCallback? onTap;
  final bool isAmountVisible;
  final VoidCallback? onToggleVisibility;

  const SalesSummaryCard({
    Key? key,
    required this.amount,
    this.creditOutstanding = 0,
    this.totalSales = 0,
    this.refunded = 0,
    this.percentageChange = 0,
    this.onTap,
    this.isAmountVisible = true,
    this.onToggleVisibility,
  }) : super(key: key);

  double get netAmount => amount - refunded;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = percentageChange >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: DuukaColors.primaryGradient,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: DuukaColors.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash at Hand',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    isAmountVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),

            // Amount
            Text(
              isAmountVisible ? DuukaFormatters.currency(netAmount) : 'UGX ••••••••',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6.h),

            // Bottom row: percentage + credit + refunds
            Row(
              children: [
                // Percentage change
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        isAmountVisible
                            ? '${DuukaFormatters.percentageChange(percentageChange)} vs yesterday'
                            : '••%',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Credit outstanding
                if (creditOutstanding > 0 && isAmountVisible) ...[
                  SizedBox(width: 6.w),
                  Icon(Icons.access_time, size: 11.sp, color: Colors.amber.shade200),
                  SizedBox(width: 2.w),
                  Text(
                    DuukaFormatters.currencyShort(creditOutstanding),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade200,
                    ),
                  ),
                ],

                // Refunds
                if (refunded > 0 && isAmountVisible) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: Text(
                      '-${DuukaFormatters.currencyShort(refunded)}',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
