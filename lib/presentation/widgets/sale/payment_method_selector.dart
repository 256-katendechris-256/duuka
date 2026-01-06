import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/models.dart';

/// Payment method selection widget
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PaymentMethodOption(
            icon: Icons.money,
            label: DuukaStrings.cash,
            method: PaymentMethod.cash,
            isSelected: selectedMethod == PaymentMethod.cash,
            onTap: () => onMethodSelected(PaymentMethod.cash),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _PaymentMethodOption(
            icon: Icons.phone_android,
            label: DuukaStrings.mobileMoney,
            method: PaymentMethod.mobileMoney,
            isSelected: selectedMethod == PaymentMethod.mobileMoney,
            onTap: () => onMethodSelected(PaymentMethod.mobileMoney),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _PaymentMethodOption(
            icon: Icons.credit_card,
            label: DuukaStrings.credit,
            method: PaymentMethod.credit,
            isSelected: selectedMethod == PaymentMethod.credit,
            onTap: () => onMethodSelected(PaymentMethod.credit),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    Key? key,
    required this.icon,
    required this.label,
    required this.method,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? DuukaColors.primaryBg
              : DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? DuukaColors.primary
                : DuukaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28.sp,
              color: isSelected
                  ? DuukaColors.primary
                  : DuukaColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? DuukaColors.primary
                    : DuukaColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
