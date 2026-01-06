import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';

/// Versatile text field widget with multiple variants
class DuukaTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final _TextFieldVariant _variant;

  const DuukaTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.focusNode,
  })  : _variant = _TextFieldVariant.normal,
        super(key: key);

  const DuukaTextField.phone({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.focusNode,
  })  : _variant = _TextFieldVariant.phone,
        prefixIcon = null,
        suffixIcon = null,
        obscureText = false,
        keyboardType = TextInputType.phone,
        textInputAction = null,
        maxLines = 1,
        maxLength = null,
        readOnly = false,
        onTap = null,
        inputFormatters = null,
        super(key: key);

  const DuukaTextField.currency({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.focusNode,
  })  : _variant = _TextFieldVariant.currency,
        prefixIcon = null,
        suffixIcon = null,
        obscureText = false,
        keyboardType = const TextInputType.numberWithOptions(decimal: true),
        textInputAction = null,
        maxLines = 1,
        maxLength = null,
        readOnly = false,
        onTap = null,
        inputFormatters = null,
        super(key: key);

  const DuukaTextField.search({
    Key? key,
    this.hint,
    this.controller,
    this.onChanged,
    this.focusNode,
  })  : _variant = _TextFieldVariant.search,
        label = null,
        initialValue = null,
        prefixIcon = Icons.search,
        suffixIcon = null,
        errorText = null,
        obscureText = false,
        keyboardType = TextInputType.text,
        textInputAction = TextInputAction.search,
        maxLines = 1,
        maxLength = null,
        enabled = true,
        readOnly = false,
        onTap = null,
        validator = null,
        inputFormatters = null,
        super(key: key);

  @override
  State<DuukaTextField> createState() => _DuukaTextFieldState();
}

class _DuukaTextFieldState extends State<DuukaTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          validator: widget.validator,
          inputFormatters: _getInputFormatters(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: DuukaColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: DuukaColors.textHint,
            ),
            prefixIcon: _buildPrefixIcon(),
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            filled: true,
            fillColor: DuukaColors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: DuukaColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: DuukaColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: DuukaColors.divider, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildPrefixIcon() {
    switch (widget._variant) {
      case _TextFieldVariant.phone:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Text(
            DuukaConfig.countryCode,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: DuukaColors.textPrimary,
            ),
          ),
        );

      case _TextFieldVariant.currency:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Text(
            DuukaConfig.currencyCode,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: DuukaColors.textSecondary,
            ),
          ),
        );

      case _TextFieldVariant.search:
      case _TextFieldVariant.normal:
        if (widget.prefixIcon != null) {
          return Icon(
            widget.prefixIcon,
            size: 20.sp,
            color: DuukaColors.textSecondary,
          );
        }
        return null;
    }
  }

  Widget? _buildSuffixIcon() {
    // Password toggle
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: 20.sp,
          color: DuukaColors.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    // Search variant mic icon
    if (widget._variant == _TextFieldVariant.search) {
      return IconButton(
        icon: Icon(
          Icons.mic,
          size: 20.sp,
          color: DuukaColors.textSecondary,
        ),
        onPressed: () {
          // TODO: Implement voice search
        },
      );
    }

    return widget.suffixIcon;
  }

  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.inputFormatters != null) {
      return widget.inputFormatters;
    }

    switch (widget._variant) {
      case _TextFieldVariant.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ];

      case _TextFieldVariant.currency:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ];

      case _TextFieldVariant.search:
      case _TextFieldVariant.normal:
        return null;
    }
  }
}

enum _TextFieldVariant { normal, phone, currency, search }
