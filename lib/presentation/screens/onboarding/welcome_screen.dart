import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/duuka_button.dart';

/// Welcome screen for onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuukaColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48.h),

              // Emoji/Icon
              Center(
                child: Text(
                  '🎉',
                  style: TextStyle(fontSize: 80.sp),
                ),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                DuukaStrings.welcomeToDuuka,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // Description
              Text(
                DuukaStrings.letsSetupBusiness,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: DuukaColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),

              // Steps List
              _StepItem(
                icon: Icons.business,
                title: 'Business Information',
                description: 'Tell us about your shop',
              ),
              SizedBox(height: 16.h),
              _StepItem(
                icon: Icons.inventory_2_outlined,
                title: 'Business Size',
                description: 'How many items do you sell?',
              ),
              SizedBox(height: 16.h),
              _StepItem(
                icon: Icons.location_on_outlined,
                title: 'Location',
                description: 'Where is your business?',
              ),

              const Spacer(),

              // Get Started Button
              DuukaButton.primary(
                label: DuukaStrings.letsGetStarted,
                onPressed: () => context.push('/onboarding/business-type'),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StepItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: DuukaColors.primaryBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            size: 24.sp,
            color: DuukaColors.primary,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: DuukaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
