import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/duuka_text_field.dart';
import '../../providers/business_provider.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _districtController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _districtController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    context.hideKeyboard();

    setState(() => _isLoading = true);

    final notifier = ref.read(onboardingDataNotifierProvider.notifier);
    notifier.updateDistrict(_districtController.text);
    notifier.updateArea(_areaController.text);

    final success = await notifier.complete();

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.go('/onboarding/complete');
    } else if (mounted) {
      context.showErrorSnackBar('Failed to complete setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DuukaAppBar(title: 'Step 4 of 4', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 6.h,
                  backgroundColor: DuukaColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(DuukaColors.primary),
                ),
              ),
              SizedBox(height: 24.h),
              Text(DuukaStrings.whereIsBusiness, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: DuukaColors.textPrimary)),
              SizedBox(height: 8.h),
              Text(DuukaStrings.helpsWithLocation, style: TextStyle(fontSize: 15.sp, color: DuukaColors.textSecondary)),
              SizedBox(height: 32.h),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: DuukaColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: Icon(Icons.my_location, size: 20.sp),
                label: Text(DuukaStrings.useCurrentLocation, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 24.h),
              DuukaTextField(label: DuukaStrings.district, hint: 'e.g. Kampala', controller: _districtController),
              SizedBox(height: 20.h),
              DuukaTextField(label: DuukaStrings.area, hint: 'e.g. Nakawa', controller: _areaController),
              SizedBox(height: 32.h),
              DuukaButton.primary(label: DuukaStrings.completeSetup, onPressed: _isLoading ? null : _handleComplete, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
