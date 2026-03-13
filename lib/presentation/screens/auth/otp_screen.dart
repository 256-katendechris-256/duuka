import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../../core/utils/post_auth_navigator.dart';
import '../../providers/auth_provider.dart';

/// OTP verification screen with 6-digit input
class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(_otpCode);

    if (!mounted) return;

    if (success) {
      final authState = ref.read(authProvider);
      if (authState.needsPinSetup) {
        context.go('/pin/setup');
      } else if (authState.needsPin) {
        context.go('/pin/login');
      } else {
        navigateAfterAuth(context, ref);
      }
    } else {
      final error = ref.read(authProvider).error;
      context.showErrorSnackBar(error ?? 'Verification failed');
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits entered
    if (_otpCode.length == 6) {
      context.hideKeyboard();
      _verifyOtp();
    }
  }

  void _onDigitBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    await ref.read(authProvider.notifier).sendOtp(widget.phoneNumber);
    if (mounted) {
      context.showSuccessSnackBar('OTP resent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: const DuukaAppBar(
        title: '',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24.h),

              // Icon
              Center(
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: DuukaColors.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.message_outlined,
                    size: 40.sp,
                    color: DuukaColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                DuukaStrings.verifyYourNumber,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Subtitle
              Text(
                '${DuukaStrings.weSentCode}\n${DuukaFormatters.phone(widget.phoneNumber.substring(4))}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: DuukaColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return _OtpDigitBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onDigitChanged(index, value),
                    onBackspace: () => _onDigitBackspace(index),
                    enabled: !isLoading,
                  );
                }),
              ),
              SizedBox(height: 32.h),

              // Resend Link
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : _resendOtp,
                  child: Text.rich(
                    TextSpan(
                      text: '${DuukaStrings.didntReceiveCode} ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: DuukaColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: DuukaStrings.resend,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Loading Indicator
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DuukaColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool enabled;

  const _OtpDigitBox({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    required this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48.w,
      height: 56.h,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: DuukaColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: DuukaColors.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: DuukaColors.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: DuukaColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: DuukaColors.primary, width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        onChanged: onChanged,
        onTap: () {
          // Clear on tap to allow re-entering
          if (controller.text.isNotEmpty) {
            controller.clear();
          }
        },
      ),
    );
  }
}
