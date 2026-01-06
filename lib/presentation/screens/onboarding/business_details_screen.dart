import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/duuka_text_field.dart';
import '../../providers/business_provider.dart';

/// Business details form screen
class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tinController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    context.hideKeyboard();

    // Update onboarding data
    final notifier = ref.read(onboardingDataNotifierProvider.notifier);
    notifier.updateBusinessName(_businessNameController.text);
    notifier.updateOwnerName(_ownerNameController.text);
    notifier.updatePhone(_phoneController.text);

    context.push('/onboarding/business-size');
  }

  void _handleSkip() {
    context.push('/onboarding/business-size');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DuukaAppBar(
        title: 'Step 2 of 4',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 6.h,
                    backgroundColor: DuukaColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DuukaColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Title
                Text(
                  DuukaStrings.tellUsAboutBusiness,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  DuukaStrings.infoAppearsOnReceipts,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                ),
                SizedBox(height: 32.h),

                // Business Name
                DuukaTextField(
                  label: DuukaStrings.businessName,
                  hint: 'e.g. Mukwano Shop',
                  controller: _businessNameController,
                  validator: DuukaValidators.businessName,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 20.h),

                // Owner Name
                DuukaTextField(
                  label: DuukaStrings.ownerName,
                  hint: 'e.g. John Doe',
                  controller: _ownerNameController,
                  validator: DuukaValidators.personName,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 20.h),

                // Business Phone
                DuukaTextField.phone(
                  label: DuukaStrings.businessPhone,
                  hint: '700000000',
                  controller: _phoneController,
                  validator: DuukaValidators.phone,
                ),
                SizedBox(height: 20.h),

                // TIN Number (Optional)
                DuukaTextField(
                  label: DuukaStrings.tinNumber,
                  hint: '1234567890',
                  controller: _tinController,
                  keyboardType: TextInputType.number,
                  validator: DuukaValidators.tin,
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: 32.h),

                // Continue Button
                DuukaButton.primary(
                  label: DuukaStrings.continueText,
                  onPressed: _handleContinue,
                ),
                SizedBox(height: 12.h),

                // Skip Button
                TextButton(
                  onPressed: _handleSkip,
                  child: Text(
                    DuukaStrings.skipForNow,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
