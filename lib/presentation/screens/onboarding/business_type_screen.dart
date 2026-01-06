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

/// Business type selection screen
class BusinessTypeScreen extends ConsumerWidget {
  const BusinessTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(onboardingDataNotifierProvider).businessType;

    return Scaffold(
      appBar: const DuukaAppBar(
        title: 'Step 1 of 4',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linear Progress Indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: 0.25,
                      minHeight: 6.h,
                      backgroundColor: DuukaColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DuukaColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text(
                    DuukaStrings.whatTypeOfBusiness,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    DuukaStrings.thisHelpsCustomize,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Grid of Business Types
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1.2,
                children: BusinessType.values.map((type) {
                  final isSelected = selectedType == type;
                  return _BusinessTypeCard(
                    type: type,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(onboardingDataNotifierProvider.notifier)
                          .updateBusinessType(type);
                    },
                  );
                }).toList(),
              ),
            ),

            // Continue Button
            Padding(
              padding: EdgeInsets.all(24.w),
              child: DuukaButton.primary(
                label: DuukaStrings.continueText,
                onPressed: selectedType != null
                    ? () => context.push('/onboarding/business-details')
                    : null,
                isDisabled: selectedType == null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessTypeCard extends StatelessWidget {
  final BusinessType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BusinessTypeCard({
    Key? key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = DuukaStrings.businessTypes[type.name] ?? '';
    final emoji = DuukaStrings.businessTypeEmojis[type.name] ?? '📦';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? DuukaColors.primaryBg : DuukaColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? DuukaColors.primary : DuukaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 40.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label.replaceAll(emoji, '').trim(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? DuukaColors.primary
                    : DuukaColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
