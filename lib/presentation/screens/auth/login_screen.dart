import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/duuka_text_field.dart';
import '../../providers/auth_provider.dart';

/// Login screen with phone authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    context.hideKeyboard();

    final phone = DuukaValidators.formatPhoneForAuth(_phoneController.text);
    await ref.read(authProvider.notifier).sendOtp(phone);

    final authState = ref.read(authProvider);
    if (authState.verificationId != null) {
      if (mounted) {
        context.push('/otp', extra: phone);
      }
    } else if (authState.error != null) {
      if (mounted) {
        context.showErrorSnackBar(authState.error!);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authProvider.notifier).signInWithGoogle();

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (mounted) {
        context.go('/onboarding/welcome');
      }
    } else if (authState.error != null) {
      if (mounted) {
        context.showErrorSnackBar(authState.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: DuukaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                // Logo
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: DuukaColors.primaryBg,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.store,
                      size: 48.sp,
                      color: DuukaColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                // Welcome Text
                Text(
                  DuukaStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                Text(
                  DuukaStrings.signInToContinue,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),

                // Phone Number Input
                DuukaTextField.phone(
                  label: DuukaStrings.phoneNumber,
                  hint: '700000000',
                  controller: _phoneController,
                  enabled: !isLoading,
                  validator: DuukaValidators.phone,
                ),
                SizedBox(height: 24.h),

                // Continue Button
                DuukaButton.primary(
                  label: DuukaStrings.continueText,
                  onPressed: isLoading ? null : _handleContinue,
                  isLoading: isLoading,
                ),
                SizedBox(height: 32.h),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: DuukaColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        DuukaStrings.orContinueWith,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: DuukaColors.border)),
                  ],
                ),
                SizedBox(height: 32.h),

                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: DuukaColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(Icons.g_mobiledata, size: 24.sp),
                  label: Text(
                    DuukaStrings.signInWithGoogle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
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
