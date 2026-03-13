import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pin_provider.dart';

/// PIN setup as part of onboarding (step 5 of 6).
/// Shown after business details are filled in, before setup complete.
class PinSetupOnboardingScreen extends ConsumerStatefulWidget {
  const PinSetupOnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PinSetupOnboardingScreen> createState() =>
      _PinSetupOnboardingScreenState();
}

class _PinSetupOnboardingScreenState
    extends ConsumerState<PinSetupOnboardingScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isConfirmStep = false;
  String _firstPin = '';
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onDigitEntered(String value) {
    setState(() => _error = null);
    if (value.length >= 4) {
      _onPinComplete(value);
    }
  }

  void _onPinComplete(String pin) {
    if (!_isConfirmStep) {
      // Validate
      final validation = ref.read(pinValidationProvider(pin));
      if (validation != null) {
        setState(() {
          _error = validation;
        });
        _pinController.clear();
        return;
      }
      // Move to confirm step
      setState(() {
        _firstPin = pin;
        _isConfirmStep = true;
        _error = null;
      });
      _confirmFocusNode.requestFocus();
    } else {
      // Confirm: check match
      if (pin != _firstPin) {
        setState(() {
          _error = 'PINs do not match. Try again.';
          _isConfirmStep = false;
          _firstPin = '';
        });
        _pinController.clear();
        _confirmController.clear();
        _pinFocusNode.requestFocus();
        return;
      }
      _savePin(pin);
    }
  }

  Future<void> _savePin(String pin) async {
    setState(() => _isSaving = true);
    final success = await ref.read(pinProvider.notifier).setupPin(pin);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ref.read(authProvider.notifier).onPinSetupComplete();
      context.go('/onboarding/complete');
    } else if (mounted) {
      setState(() => _error = 'Failed to save PIN. Please try again.');
      _resetEntry();
    }
  }

  void _resetEntry() {
    setState(() {
      _isConfirmStep = false;
      _firstPin = '';
      _error = null;
    });
    _pinController.clear();
    _confirmController.clear();
    _pinFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _isConfirmStep ? _confirmController : _pinController;
    final focusNode = _isConfirmStep ? _confirmFocusNode : _pinFocusNode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),

                // Progress indicator (step 5 of 6)
                Row(
                  children: List.generate(6, (i) {
                    return Expanded(
                      child: Container(
                        height: 4.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: i <= 4
                              ? DuukaColors.primary
                              : DuukaColors.border,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    );
                  }),
                ),

                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: DuukaColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isConfirmStep ? Icons.lock : Icons.lock_outline,
                    size: 40.sp,
                    color: DuukaColors.primary,
                  ),
                ),
                SizedBox(height: 24.h),

                // Title
                Text(
                  _isConfirmStep ? 'Confirm Your PIN' : 'Secure Your Account',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  _isConfirmStep
                      ? 'Enter your PIN again to confirm'
                      : 'Create a 4–6 digit PIN for quick daily access',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: DuukaColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),

                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final filled = index < controller.text.length;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? DuukaColors.primary : Colors.transparent,
                        border: Border.all(
                          color: filled ? DuukaColors.primary : DuukaColors.border,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                // Hidden text field
                SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    obscureText: true,
                    onChanged: _onDigitEntered,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),

                SizedBox(height: 16.h),

                // Tap hint
                Text(
                  'Tap anywhere to type',
                  style: TextStyle(fontSize: 12.sp, color: DuukaColors.textHint),
                ),

                // Error
                if (_error != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: DuukaColors.errorBg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 13.sp, color: DuukaColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                SizedBox(height: 16.h),

                // Start over (only in confirm step)
                if (_isConfirmStep)
                  TextButton(
                    onPressed: _resetEntry,
                    child: Text(
                      'Start Over',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: DuukaColors.primary,
                      ),
                    ),
                  ),

                if (_isSaving) ...[
                  SizedBox(height: 16.h),
                  const CircularProgressIndicator(),
                ],

                const Spacer(flex: 3),

                // Info note
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.primaryBg,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 20.sp, color: DuukaColors.primary),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Your PIN is stored securely on this device for quick daily login.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: DuukaColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
