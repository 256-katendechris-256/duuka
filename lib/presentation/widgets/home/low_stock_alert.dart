import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Alert card showing low stock items
class LowStockAlert extends StatelessWidget {
  final int itemCount;
  final List<String> itemNames;
  final VoidCallback onTap;

  const LowStockAlert({
    Key? key,
    required this.itemCount,
    required this.itemNames,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayNames = itemNames.take(3).toList();
    final remainingCount = itemCount - displayNames.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: DuukaColors.warningBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: DuukaColors.warning.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: DuukaColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 20.sp,
                color: DuukaColors.warning,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ${DuukaStrings.itemsRunningLow}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _buildItemsText(displayNames, remainingCount),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: DuukaColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _buildItemsText(List<String> names, int remaining) {
    if (names.isEmpty) return '';

    String text = names.join(', ');
    if (remaining > 0) {
      text += ' and $remaining more';
    }
    return text;
  }
}
