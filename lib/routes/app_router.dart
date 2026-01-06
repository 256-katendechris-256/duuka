import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/datasources/local/preferences_service.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/otp_screen.dart';
import '../presentation/screens/onboarding/welcome_screen.dart';
import '../presentation/screens/onboarding/business_type_screen.dart';
import '../presentation/screens/onboarding/business_details_screen.dart';
import '../presentation/screens/onboarding/business_size_screen.dart';
import '../presentation/screens/onboarding/location_screen.dart';
import '../presentation/screens/onboarding/setup_complete_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/sale/quick_sale_screen.dart';
import '../presentation/screens/sale/cart_screen.dart';
import '../presentation/screens/main_shell.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Add auth-based redirects here if needed
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: OtpScreen(phoneNumber: phoneNumber),
          );
        },
      ),

      // Onboarding Routes
      GoRoute(
        path: '/onboarding/welcome',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/business-type',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BusinessTypeScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/business-details',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BusinessDetailsScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/business-size',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BusinessSizeScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/location',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LocationScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/complete',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SetupCompleteScreen(),
        ),
      ),

      // Main App Routes with Shell (Bottom Navigation)
      ShellRoute(
        builder: (context, state, child) {
          // Determine current index based on location
          int currentIndex = 0;
          final location = state.uri.path;
          if (location.startsWith('/home')) {
            currentIndex = 0;
          } else if (location.startsWith('/inventory')) {
            currentIndex = 1;
          } else if (location.startsWith('/customers')) {
            currentIndex = 2;
          } else if (location.startsWith('/reports')) {
            currentIndex = 3;
          }

          return MainShell(
            currentIndex: currentIndex,
            child: child,
          );
        },
        routes: [
          // Home
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // Inventory Routes
          GoRoute(
            path: '/inventory',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Scaffold(
                body: Center(child: Text('Inventory Screen - Coming Soon')),
              ),
            ),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Add Item Screen - Coming Soon')),
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return Scaffold(
                    body: Center(
                      child: Text('Item Detail Screen - ID: $id - Coming Soon'),
                    ),
                  );
                },
              ),
            ],
          ),

          // Customers Routes
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Scaffold(
                body: Center(child: Text('Customers Screen - Coming Soon')),
              ),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return Scaffold(
                    body: Center(
                      child: Text('Customer Detail Screen - ID: $id - Coming Soon'),
                    ),
                  );
                },
              ),
            ],
          ),

          // Reports
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Scaffold(
                body: Center(child: Text('Reports Screen - Coming Soon')),
              ),
            ),
          ),
        ],
      ),

      // Sale Routes (Outside Shell - Full Screen)
      GoRoute(
        path: '/sale',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const QuickSaleScreen(),
        ),
        routes: [
          GoRoute(
            path: 'cart',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const CartScreen(),
            ),
          ),
          GoRoute(
            path: 'receipt',
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: const Scaffold(
                  body: Center(child: Text('Receipt Screen - Coming Soon')),
                ),
              );
            },
          ),
        ],
      ),

      // Settings Route
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Settings Screen - Coming Soon')),
          ),
        ),
      ),

      // Sales List (for "See All")
      GoRoute(
        path: '/sales',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Sales List Screen - Coming Soon')),
          ),
        ),
      ),
    ],
  );
});
