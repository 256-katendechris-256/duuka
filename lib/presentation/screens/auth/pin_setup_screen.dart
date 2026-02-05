import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pin_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isConfirmStep = false;
  String _firstPin = '';
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onPinComplete(String pin) {
    if (!_isConfirmStep) {
      // First entry - validate and move to confirm
      final validation = ref.read(pinValidationProvider(pin));
      if (validation != null) {
        setState(() {
          _error = validation;
        });
        _pinController.clear();
        return;
      }

      setState(() {
        _firstPin = pin;
        _isConfirmStep = true;
        _error = null;
      });
      _confirmFocusNode.requestFocus();
    } else {
      // Confirm step - check if PINs match
      if (pin != _firstPin) {
        setState(() {
          _error = 'PINs do not match. Please try again.';
          _isConfirmStep = false;
          _firstPin = '';
        });
        _pinController.clear();
        _confirmPinController.clear();
        _pinFocusNode.requestFocus();
        return;
      }

      // PINs match - save
      _setupPin(pin);
    }
  }

  Future<void> _setupPin(String pin) async {
    final success = await ref.read(pinProvider.notifier).setupPin(pin);

    if (success && mounted) {
      // Notify auth provider
      ref.read(authProvider.notifier).onPinSetupComplete();

      // Navigate based on onboarding status
      final isOnboarded = ref.read(isOnboardingCompleteProvider);
      if (isOnboarded) {
        context.go('/home');
      } else {
        context.go('/onboarding/welcome');
      }
    }
  }

  void _resetEntry() {
    setState(() {
      _isConfirmStep = false;
      _firstPin = '';
      _error = null;
    });
    _pinController.clear();
    _confirmPinController.clear();
    _pinFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 40.h),

                  // Icon
                  Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: DuukaColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 40.sp,
                  color: DuukaColors.primary,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                _isConfirmStep ? 'Confirm Your PIN' : 'Create Your PIN',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: DuukaColors.textPrimary,
                ),
              ),

              SizedBox(height: 12.h),

              // Subtitle
              Text(
                _isConfirmStep
                    ? 'Enter your PIN again to confirm'
                    : 'Create a 4-6 digit PIN for quick login',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: DuukaColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),

              // PIN Input
              _buildPinInput(),

              if (_error != null || pinState.error != null) ...[
                SizedBox(height: 16.h),
                Text(
                  _error ?? pinState.error ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: 24.h),

              // Reset button (only in confirm step)
              if (_isConfirmStep)
                TextButton(
                  onPressed: _resetEntry,
                  child: Text(
                    'Start Over',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: DuukaColors.primary,
                    ),
                  ),
                ),

              const Spacer(),

              // Loading indicator
              if (pinState.isLoading)
                const CircularProgressIndicator(),

              SizedBox(height: 32.h),

              // Security note
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Your PIN is stored securely on this device and is used for quick daily access.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    final controller = _isConfirmStep ? _confirmPinController : _pinController;
    final focusNode = _isConfirmStep ? _confirmFocusNode : _pinFocusNode;

    return Column(
      children: [
        // PIN dots display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final filled = index < controller.text.length;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              width: 16.w,
              height: 16.w,
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

        SizedBox(height: 24.h),

        // Hidden text field for PIN input
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
            onChanged: (value) {
              setState(() {});
              if (value.length >= 4) {
                _onPinComplete(value);
              }
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),

        // Tap to focus hint
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
            child: Text(
              'Tap here to enter PIN',
              style: TextStyle(
                fontSize: 14.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
