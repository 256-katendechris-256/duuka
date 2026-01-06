import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

/// Versatile button widget with multiple variants
class DuukaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final _ButtonVariant _variant;

  const DuukaButton.primary({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  })  : _variant = _ButtonVariant.primary,
        super(key: key);

  const DuukaButton.secondary({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  })  : _variant = _ButtonVariant.secondary,
        super(key: key);

  const DuukaButton.text({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  })  : _variant = _ButtonVariant.text,
        super(key: key);

  const DuukaButton.icon({
    Key? key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
  })  : _variant = _ButtonVariant.icon,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = isDisabled || isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: 48.h,
      child: _buildButton(context, isButtonDisabled),
    );
  }

  Widget _buildButton(BuildContext context, bool isButtonDisabled) {
    switch (_variant) {
      case _ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isButtonDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DuukaColors.primary,
            foregroundColor: DuukaColors.textOnPrimary,
            disabledBackgroundColor: DuukaColors.border,
            disabledForegroundColor: DuukaColors.textHint,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: _buildContent(),
        );

      case _ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isButtonDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: DuukaColors.primary,
            disabledForegroundColor: DuukaColors.textHint,
            side: BorderSide(
              color: isButtonDisabled ? DuukaColors.border : DuukaColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: _buildContent(),
        );

      case _ButtonVariant.text:
        return TextButton(
          onPressed: isButtonDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: DuukaColors.primary,
            disabledForegroundColor: DuukaColors.textHint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _buildContent(),
        );

      case _ButtonVariant.icon:
        return ElevatedButton.icon(
          onPressed: isButtonDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DuukaColors.primary,
            foregroundColor: DuukaColors.textOnPrimary,
            disabledBackgroundColor: DuukaColors.border,
            disabledForegroundColor: DuukaColors.textHint,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          icon: Icon(icon, size: 20.sp),
          label: _buildContent(),
        );
    }
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        height: 20.h,
        width: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _variant == _ButtonVariant.primary || _variant == _ButtonVariant.icon
                ? DuukaColors.textOnPrimary
                : DuukaColors.primary,
          ),
        ),
      );
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary, text, icon }
