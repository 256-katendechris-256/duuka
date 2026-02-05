import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Custom app bar with optional back button and actions
class DuukaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool transparent;
  final VoidCallback? onBackPressed;

  const DuukaAppBar({
    Key? key,
    required this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.actions,
    this.transparent = false,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: transparent ? Colors.white : DuukaColors.textPrimary,
        ),
      ),
      centerTitle: false,
      elevation: transparent ? 0 : 0,
      backgroundColor: transparent ? Colors.transparent : DuukaColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 24.sp,
                color: transparent ? Colors.white : DuukaColors.textPrimary,
              ),
              onPressed: onBackPressed ?? () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : null,
      actions: actions,
      iconTheme: IconThemeData(
        color: transparent ? Colors.white : DuukaColors.textPrimary,
        size: 24.sp,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
