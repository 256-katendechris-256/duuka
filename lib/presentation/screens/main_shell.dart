import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/models.dart';
import '../providers/auth_provider.dart';

/// Main shell with bottom navigation using StatefulShellRoute
class MainShellWithNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellWithNav({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sale'),
        backgroundColor: DuukaColors.primary,
        child: Icon(Icons.add, size: 28.sp),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index, isOwner),
        type: BottomNavigationBarType.fixed,
        backgroundColor: DuukaColors.surface,
        selectedItemColor: DuukaColors.primary,
        unselectedItemColor: DuukaColors.textSecondary,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: DuukaStrings.home,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: DuukaStrings.inventory,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: DuukaStrings.customers,
          ),
          // Show Sales for non-owners, Reports for owners
          BottomNavigationBarItem(
            icon: Icon(isOwner ? Icons.assessment_outlined : Icons.receipt_long_outlined),
            activeIcon: Icon(isOwner ? Icons.assessment : Icons.receipt_long),
            label: isOwner ? DuukaStrings.reports : 'Sales',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index, bool isOwner) {
    // For the last tab (index 3), route non-owners to sales instead of reports
    if (index == 3 && !isOwner) {
      context.push('/sales');
      return;
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Legacy MainShell for compatibility (not used with StatefulShellRoute)
class MainShell extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sale'),
        backgroundColor: DuukaColors.primary,
        child: Icon(Icons.add, size: 28.sp),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/inventory');
              break;
            case 2:
              context.go('/customers');
              break;
            case 3:
              // Route non-owners to sales instead of reports
              if (isOwner) {
                context.go('/reports');
              } else {
                context.push('/sales');
              }
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: DuukaColors.surface,
        selectedItemColor: DuukaColors.primary,
        unselectedItemColor: DuukaColors.textSecondary,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: DuukaStrings.home,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: DuukaStrings.inventory,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: DuukaStrings.customers,
          ),
          // Show Sales for non-owners, Reports for owners
          BottomNavigationBarItem(
            icon: Icon(isOwner ? Icons.assessment_outlined : Icons.receipt_long_outlined),
            activeIcon: Icon(isOwner ? Icons.assessment : Icons.receipt_long),
            label: isOwner ? DuukaStrings.reports : 'Sales',
          ),
        ],
      ),
    );
  }
}
