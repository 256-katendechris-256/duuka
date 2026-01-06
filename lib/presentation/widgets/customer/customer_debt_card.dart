import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

/// Card for customer with debt showing balance and actions
class CustomerDebtCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onRemind;
  final VoidCallback? onAddPayment;
  final VoidCallback? onTap;

  const CustomerDebtCard({
    Key? key,
    required this.customer,
    this.onRemind,
    this.onAddPayment,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = customer.isOverLimit;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isOverdue ? DuukaColors.error.withOpacity(0.3) : DuukaColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with initials
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: isOverdue ? DuukaColors.errorBg : DuukaColors.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      DuukaFormatters.initials(customer.name),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? DuukaColors.error : DuukaColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      if (customer.phone != null)
                        Text(
                          DuukaFormatters.phone(customer.phone!),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Debt Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DuukaFormatters.currency(customer.balance),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.error,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isOverdue ? DuukaColors.errorBg : DuukaColors.successBg,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        isOverdue ? DuukaStrings.overdue : DuukaStrings.onTrack,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isOverdue ? DuukaColors.error : DuukaColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Action Buttons
            if (onRemind != null || onAddPayment != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (onRemind != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemind,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DuukaColors.primary,
                          side: BorderSide(color: DuukaColors.border, width: 1),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: Icon(Icons.message_outlined, size: 16.sp),
                        label: Text(
                          DuukaStrings.remind,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (onRemind != null && onAddPayment != null) SizedBox(width: 8.w),
                  if (onAddPayment != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DuukaColors.success,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(Icons.add, size: 16.sp),
                        label: Text(
                          DuukaStrings.addPayment,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
