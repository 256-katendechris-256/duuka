import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

/// Main card on home screen showing today's cash at hand with gradient background
class SalesSummaryCard extends StatelessWidget {
  final double amount;  // Cash at hand (actual money received)
  final double creditOutstanding;  // Unpaid credit balance
  final double totalSales;  // Total sales (cash + credit)
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
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: DuukaColors.primaryGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: DuukaColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with eye icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash at Hand',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      isAmountVisible ? Icons.visibility : Icons.visibility_off,
                      size: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Net Amount (visible or hidden)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isAmountVisible
                    ? DuukaFormatters.currency(netAmount)
                    : 'UGX ••••••••',
                key: ValueKey(isAmountVisible),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Show credit sales info if there are outstanding credits
            if (creditOutstanding > 0 && isAmountVisible) ...[
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14.sp,
                    color: Colors.amber.shade200,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Credit: ${DuukaFormatters.currency(creditOutstanding)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade200,
                    ),
                  ),
                  if (totalSales > 0) ...[
                    SizedBox(width: 8.w),
                    Text(
                      '(Total: ${DuukaFormatters.currency(totalSales - refunded)})',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Show refund info if there are any refunds
            if (refunded > 0 && isAmountVisible) ...[
              SizedBox(height: 4.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '-${DuukaFormatters.currency(refunded)} returns',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            
            // Percentage change row (also hidden when amount is hidden)
            AnimatedOpacity(
              opacity: isAmountVisible ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    isAmountVisible 
                        ? DuukaFormatters.percentageChange(percentageChange)
                        : '••%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'vs yesterday',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
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
}
