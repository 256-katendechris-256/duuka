import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../providers/business_provider.dart';

class BusinessSizeScreen extends ConsumerWidget {
  const BusinessSizeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSize = ref.watch(onboardingDataNotifierProvider).businessSize;

    return Scaffold(
      appBar: const DuukaAppBar(title: 'Step 3 of 4', showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: 0.75,
                      minHeight: 6.h,
                      backgroundColor: DuukaColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(DuukaColors.primary),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    DuukaStrings.howBigIsBusiness,
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: DuukaColors.textPrimary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    DuukaStrings.helpsRecommendPlan,
                    style: TextStyle(fontSize: 15.sp, color: DuukaColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                children: [
                  _SizeOption(
                    size: BusinessSize.starter,
                    title: DuukaStrings.justStarting,
                    description: DuukaStrings.justStartingDesc,
                    price: DuukaStrings.free,
                    isSelected: selectedSize == BusinessSize.starter,
                    onTap: () => ref.read(onboardingDataNotifierProvider.notifier).updateBusinessSize(BusinessSize.starter),
                  ),
                  SizedBox(height: 12.h),
                  _SizeOption(
                    size: BusinessSize.small,
                    title: DuukaStrings.smallShop,
                    description: DuukaStrings.smallShopDesc,
                    price: DuukaStrings.starterPrice,
                    isSelected: selectedSize == BusinessSize.small,
                    onTap: () => ref.read(onboardingDataNotifierProvider.notifier).updateBusinessSize(BusinessSize.small),
                  ),
                  SizedBox(height: 12.h),
                  _SizeOption(
                    size: BusinessSize.growing,
                    title: DuukaStrings.growingBusiness,
                    description: DuukaStrings.growingBusinessDesc,
                    price: DuukaStrings.businessPrice,
                    isSelected: selectedSize == BusinessSize.growing,
                    onTap: () => ref.read(onboardingDataNotifierProvider.notifier).updateBusinessSize(BusinessSize.growing),
                  ),
                  SizedBox(height: 12.h),
                  _SizeOption(
                    size: BusinessSize.established,
                    title: DuukaStrings.established,
                    description: DuukaStrings.establishedDesc,
                    price: DuukaStrings.premiumPrice,
                    isSelected: selectedSize == BusinessSize.established,
                    onTap: () => ref.read(onboardingDataNotifierProvider.notifier).updateBusinessSize(BusinessSize.established),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: DuukaButton.primary(
                label: DuukaStrings.continueText,
                onPressed: selectedSize != null ? () => context.push('/onboarding/location') : null,
                isDisabled: selectedSize == null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeOption extends StatelessWidget {
  final BusinessSize size;
  final String title;
  final String description;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeOption({
    required this.size,
    required this.title,
    required this.description,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? DuukaColors.primaryBg : DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? DuukaColors.primary : DuukaColors.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? DuukaColors.primary : DuukaColors.border, width: 2),
                color: isSelected ? DuukaColors.primary : Colors.transparent,
              ),
              child: isSelected ? Center(child: Container(width: 8.w, height: 8.h, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: DuukaColors.textPrimary)),
                  SizedBox(height: 4.h),
                  Text(description, style: TextStyle(fontSize: 13.sp, color: DuukaColors.textSecondary)),
                ],
              ),
            ),
            Text(price, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: DuukaColors.primary)),
          ],
        ),
      ),
    );
  }
}
