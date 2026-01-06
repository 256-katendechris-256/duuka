import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class DuukaTheme {
  DuukaTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: DuukaColors.background,

      // Typography
      textTheme: _textTheme,

      // AppBar
      appBarTheme: _appBarTheme,

      // Card
      cardTheme: _cardTheme,

      // Button Themes
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      iconButtonTheme: _iconButtonTheme,

      // Input Decoration
      inputDecorationTheme: _inputDecorationTheme,

      // Bottom Navigation
      bottomNavigationBarTheme: _bottomNavigationBarTheme,

      // Navigation Bar (Material 3)
      navigationBarTheme: _navigationBarTheme,

      // Floating Action Button
      floatingActionButtonTheme: _fabTheme,

      // Chip
      chipTheme: _chipTheme,

      // Dialog
      dialogTheme: _dialogTheme,

      // Bottom Sheet
      bottomSheetTheme: _bottomSheetTheme,

      // Divider
      dividerTheme: _dividerTheme,

      // List Tile
      listTileTheme: _listTileTheme,

      // Switch
      switchTheme: _switchTheme,

      // Checkbox
      checkboxTheme: _checkboxTheme,

      // Radio
      radioTheme: _radioTheme,

      // Snackbar
      snackBarTheme: _snackBarTheme,

      // Progress Indicator
      progressIndicatorTheme: _progressIndicatorTheme,

      // Tab Bar
      tabBarTheme: _tabBarTheme,

      // Tooltip
      tooltipTheme: _tooltipTheme,

      // Badge
      badgeTheme: _badgeTheme,

      // Search Bar
      searchBarTheme: _searchBarTheme,

      // PopupMenu
      popupMenuTheme: _popupMenuTheme,

      // Icon Theme
      iconTheme: IconThemeData(
        size: 24.sp,
        color: DuukaColors.textSecondary,
      ),

      // Splash Factory
      splashFactory: InkRipple.splashFactory,
    );
  }

  // Color Scheme
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: DuukaColors.primary,
    onPrimary: DuukaColors.textOnPrimary,
    primaryContainer: DuukaColors.primaryBg,
    onPrimaryContainer: DuukaColors.primary,

    secondary: DuukaColors.primaryLight,
    onSecondary: DuukaColors.textOnPrimary,

    tertiary: DuukaColors.info,
    onTertiary: Colors.white,

    error: DuukaColors.error,
    onError: Colors.white,
    errorContainer: DuukaColors.errorBg,
    onErrorContainer: DuukaColors.error,

    surface: DuukaColors.surface,
    onSurface: DuukaColors.textPrimary,
    surfaceContainerHighest: DuukaColors.background,

    outline: DuukaColors.border,
    outlineVariant: DuukaColors.divider,

    shadow: Colors.black26,
  );

  // Text Theme
  static TextTheme get _textTheme {
    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: DuukaColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 45.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textPrimary,
      ),

      // Headline
      headlineLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        color: DuukaColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        color: DuukaColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: DuukaColors.textPrimary,
      ),

      // Title
      titleLarge: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w500,
        color: DuukaColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: DuukaColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: DuukaColors.textPrimary,
      ),

      // Body
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: DuukaColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: DuukaColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: DuukaColors.textSecondary,
      ),

      // Label
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: DuukaColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: DuukaColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: DuukaColors.textSecondary,
      ),
    );
  }

  // AppBar Theme
  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: DuukaColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: DuukaColors.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: DuukaColors.textPrimary,
      ),
      iconTheme: IconThemeData(
        size: 24.sp,
        color: DuukaColors.textPrimary,
      ),
    );
  }

  // Card Theme
  static CardTheme get _cardTheme {
    return CardTheme(
      elevation: 0,
      color: DuukaColors.cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: DuukaColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  // Elevated Button Theme
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: DuukaColors.primary,
        foregroundColor: DuukaColors.textOnPrimary,
        disabledBackgroundColor: DuukaColors.border,
        disabledForegroundColor: DuukaColors.textHint,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        minimumSize: Size(120.w, 48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Outlined Button Theme
  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DuukaColors.primary,
        disabledForegroundColor: DuukaColors.textHint,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        minimumSize: Size(120.w, 48.h),
        side: BorderSide(color: DuukaColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Text Button Theme
  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DuukaColors.primary,
        disabledForegroundColor: DuukaColors.textHint,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        minimumSize: Size(64.w, 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        textStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Filled Button Theme
  static FilledButtonThemeData get _filledButtonTheme {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DuukaColors.primary,
        foregroundColor: DuukaColors.textOnPrimary,
        disabledBackgroundColor: DuukaColors.border,
        disabledForegroundColor: DuukaColors.textHint,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        minimumSize: Size(120.w, 48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Icon Button Theme
  static IconButtonThemeData get _iconButtonTheme {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: DuukaColors.textSecondary,
        iconSize: 24.sp,
        minimumSize: Size(48.w, 48.h),
        padding: EdgeInsets.all(12.w),
      ),
    );
  }

  // Input Decoration Theme
  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: DuukaColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),

      // Border styles
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

      // Text styles
      labelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textSecondary,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: DuukaColors.primary,
      ),
      hintStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textHint,
      ),
      errorStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.error,
      ),
      helperStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textSecondary,
      ),

      // Icons
      prefixIconColor: DuukaColors.textSecondary,
      suffixIconColor: DuukaColors.textSecondary,
    );
  }

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData get _bottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      elevation: 8,
      backgroundColor: DuukaColors.surface,
      selectedItemColor: DuukaColors.primary,
      unselectedItemColor: DuukaColors.textSecondary,
      selectedIconTheme: IconThemeData(size: 28.sp),
      unselectedIconTheme: IconThemeData(size: 24.sp),
      selectedLabelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }

  // Navigation Bar Theme (Material 3)
  static NavigationBarThemeData get _navigationBarTheme {
    return NavigationBarThemeData(
      height: 80.h,
      elevation: 0,
      backgroundColor: DuukaColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: DuukaColors.primaryBg,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(size: 28.sp, color: DuukaColors.primary);
        }
        return IconThemeData(size: 24.sp, color: DuukaColors.textSecondary);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.primary,
          );
        }
        return TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: DuukaColors.textSecondary,
        );
      }),
    );
  }

  // FAB Theme
  static FloatingActionButtonThemeData get _fabTheme {
    return FloatingActionButtonThemeData(
      elevation: 2,
      backgroundColor: DuukaColors.primary,
      foregroundColor: DuukaColors.textOnPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      iconSize: 24.sp,
    );
  }

  // Chip Theme
  static ChipThemeData get _chipTheme {
    return ChipThemeData(
      backgroundColor: DuukaColors.background,
      selectedColor: DuukaColors.primaryBg,
      disabledColor: DuukaColors.divider,
      labelStyle: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: DuukaColors.textPrimary,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: DuukaColors.primary,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      side: BorderSide(color: DuukaColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  // Dialog Theme
  static DialogTheme get _dialogTheme {
    return DialogTheme(
      elevation: 3,
      backgroundColor: DuukaColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: DuukaColors.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textSecondary,
      ),
    );
  }

  // Bottom Sheet Theme
  static BottomSheetThemeData get _bottomSheetTheme {
    return BottomSheetThemeData(
      elevation: 8,
      backgroundColor: DuukaColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      constraints: BoxConstraints(maxWidth: 640.w),
    );
  }

  // Divider Theme
  static DividerThemeData get _dividerTheme {
    return DividerThemeData(
      color: DuukaColors.divider,
      thickness: 1,
      space: 1,
    );
  }

  // List Tile Theme
  static ListTileThemeData get _listTileTheme {
    return ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      minLeadingWidth: 40.w,
      iconColor: DuukaColors.textSecondary,
      textColor: DuukaColors.textPrimary,
      titleTextStyle: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: DuukaColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  // Switch Theme
  static SwitchThemeData get _switchTheme {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DuukaColors.primary;
        }
        return DuukaColors.textHint;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DuukaColors.primaryBg;
        }
        return DuukaColors.border;
      }),
    );
  }

  // Checkbox Theme
  static CheckboxThemeData get _checkboxTheme {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DuukaColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(DuukaColors.textOnPrimary),
      side: BorderSide(color: DuukaColors.border, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  // Radio Theme
  static RadioThemeData get _radioTheme {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DuukaColors.primary;
        }
        return DuukaColors.border;
      }),
    );
  }

  // Snackbar Theme
  static SnackBarThemeData get _snackBarTheme {
    return SnackBarThemeData(
      elevation: 4,
      backgroundColor: DuukaColors.textPrimary,
      contentTextStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  // Progress Indicator Theme
  static ProgressIndicatorThemeData get _progressIndicatorTheme {
    return const ProgressIndicatorThemeData(
      color: DuukaColors.primary,
      linearTrackColor: DuukaColors.primaryBg,
      circularTrackColor: DuukaColors.primaryBg,
    );
  }

  // Tab Bar Theme
  static TabBarTheme get _tabBarTheme {
    return TabBarTheme(
      labelColor: DuukaColors.primary,
      unselectedLabelColor: DuukaColors.textSecondary,
      labelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: DuukaColors.primary, width: 2),
        insets: EdgeInsets.symmetric(horizontal: 16.w),
      ),
    );
  }

  // Tooltip Theme
  static TooltipThemeData get _tooltipTheme {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: DuukaColors.textPrimary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      textStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      waitDuration: const Duration(milliseconds: 500),
    );
  }

  // Badge Theme
  static BadgeThemeData get _badgeTheme {
    return BadgeThemeData(
      backgroundColor: DuukaColors.error,
      textColor: Colors.white,
      textStyle: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    );
  }

  // Search Bar Theme
  static SearchBarThemeData get _searchBarTheme {
    return SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(DuukaColors.surface),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.all(
        BorderSide(color: DuukaColors.border, width: 1.5),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: 16.w),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: DuukaColors.textPrimary,
        ),
      ),
      hintStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: DuukaColors.textHint,
        ),
      ),
    );
  }

  // Popup Menu Theme
  static PopupMenuThemeData get _popupMenuTheme {
    return PopupMenuThemeData(
      elevation: 8,
      color: DuukaColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      textStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: DuukaColors.textPrimary,
      ),
    );
  }
}
