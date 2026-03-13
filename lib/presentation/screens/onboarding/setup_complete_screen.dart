import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/post_auth_navigator.dart';
import '../../widgets/common/duuka_button.dart';
import '../../providers/business_provider.dart';

class SetupCompleteScreen extends ConsumerWidget {
  const SetupCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(color: DuukaColors.successBg, shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 60.sp, color: DuukaColors.success),
              ),
              SizedBox(height: 32.h),
              Text(DuukaStrings.youreAllSet, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: DuukaColors.textPrimary), textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              businessAsync.when(
                data: (business) => Text(
                  business != null ? '${business.name} ${DuukaStrings.businessReadyToGo}' : DuukaStrings.businessReadyToGo,
                  style: TextStyle(fontSize: 16.sp, color: DuukaColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                loading: () => Text(DuukaStrings.businessReadyToGo, style: TextStyle(fontSize: 16.sp, color: DuukaColors.textSecondary), textAlign: TextAlign.center),
                error: (_, __) => Text(DuukaStrings.businessReadyToGo, style: TextStyle(fontSize: 16.sp, color: DuukaColors.textSecondary), textAlign: TextAlign.center),
              ),
              const Spacer(),
              DuukaButton.primary(label: DuukaStrings.goToDashboard, onPressed: () => navigateAfterAuth(context, ref)),
              SizedBox(height: 12.h),
              DuukaButton.secondary(label: DuukaStrings.addFirstProduct, onPressed: () => context.go('/inventory/add')),
            ],
          ),
        ),
      ),
    );
  }
}
