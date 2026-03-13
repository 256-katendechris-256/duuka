import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/otp_screen.dart';
import '../presentation/screens/auth/pending_approval_screen.dart';
import '../presentation/screens/auth/pin_setup_screen.dart';
import '../presentation/screens/auth/pin_login_screen.dart';
import '../presentation/screens/onboarding/welcome_screen.dart';
import '../presentation/screens/onboarding/business_type_screen.dart';
import '../presentation/screens/onboarding/business_details_screen.dart';
import '../presentation/screens/onboarding/business_size_screen.dart';
import '../presentation/screens/onboarding/location_screen.dart';
import '../presentation/screens/onboarding/setup_complete_screen.dart';
import '../presentation/screens/onboarding/pin_setup_onboarding_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/inventory/inventory_screen.dart';
import '../presentation/screens/inventory/add_product_screen.dart';
import '../presentation/screens/inventory/product_detail_screen.dart';
import '../presentation/screens/inventory/bulk_upload_screen.dart';
import '../presentation/screens/sale/quick_sale_screen.dart';
import '../presentation/screens/sale/cart_screen.dart';
import '../presentation/screens/sale/receipt_screen.dart';
import '../presentation/screens/sales/sales_list_screen.dart';
import '../presentation/screens/sales/sale_detail_screen.dart';
import '../presentation/screens/invoices/invoices_list_screen.dart';
import '../presentation/screens/invoices/invoice_detail_screen.dart';
import '../presentation/screens/invoices/create_invoice_screen.dart';
import '../presentation/screens/customers/customers_screen.dart';
import '../presentation/screens/customers/customer_detail_screen.dart';
import '../presentation/screens/credit/debtors_screen.dart';
import '../presentation/screens/credit/hire_purchase_screen.dart';
import '../presentation/screens/expenses/expenses_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';
import '../presentation/screens/reports/sales_report_screen.dart';
import '../presentation/screens/reports/profit_loss_screen.dart';
import '../presentation/screens/reports/inventory_report_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/team_management_screen.dart';
import '../presentation/screens/auth/join_team_screen.dart';
import '../presentation/screens/main_shell.dart';
import '../data/models/models.dart';

// Singleton router instance
GoRouter? _router;

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // PIN Routes
      GoRoute(
        path: '/pin/setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/pin/login',
        builder: (context, state) => const PinLoginScreen(),
      ),

      // Onboarding Routes
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/business-type',
        builder: (context, state) => const BusinessTypeScreen(),
      ),
      GoRoute(
        path: '/onboarding/business-details',
        builder: (context, state) => const BusinessDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/business-size',
        builder: (context, state) => const BusinessSizeScreen(),
      ),
      GoRoute(
        path: '/onboarding/location',
        builder: (context, state) => const LocationScreen(),
      ),
      GoRoute(
        path: '/onboarding/pin-setup',
        builder: (context, state) => const PinSetupOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (context, state) => const SetupCompleteScreen(),
      ),

      // Main App Routes with Shell (Bottom Navigation)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellWithNav(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Inventory Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddProductScreen(),
                  ),
                  GoRoute(
                    path: 'bulk-upload',
                    builder: (context, state) => const BulkUploadScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ProductDetailScreen(productId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Customers Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return CustomerDetailScreen(customerId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Reports Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: 'sales',
                    builder: (context, state) => const SalesReportScreen(),
                  ),
                  GoRoute(
                    path: 'profit-loss',
                    builder: (context, state) => const ProfitLossScreen(),
                  ),
                  GoRoute(
                    path: 'inventory',
                    builder: (context, state) => const InventoryReportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Sale Routes (Outside Shell - Full Screen)
      GoRoute(
        path: '/sale',
        builder: (context, state) => const QuickSaleScreen(),
        routes: [
          GoRoute(
            path: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: 'receipt',
            builder: (context, state) {
              final sale = state.extra as Sale?;
              if (sale == null) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Receipt not found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('Go Home'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ReceiptScreen(sale: sale);
            },
          ),
        ],
      ),

      // Settings Route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Team Management Route
      GoRoute(
        path: '/team',
        builder: (context, state) => const TeamManagementScreen(),
      ),

      // Join Team Route (for invited users)
      GoRoute(
        path: '/join-team',
        builder: (context, state) => const JoinTeamScreen(),
      ),

      // Sales List (for "See All")
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesListScreen(),
      ),

      // Sale Detail (for returns)
      GoRoute(
        path: '/sales/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SaleDetailScreen(saleId: id);
        },
      ),

      // Invoice Routes
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesListScreen(),
      ),
      GoRoute(
        path: '/invoice/create',
        builder: (context, state) {
          final customerId = state.extra as int?;
          return CreateInvoiceScreen(customerId: customerId);
        },
      ),
      GoRoute(
        path: '/invoice/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),

      // Customer Detail (for use from non-shell screens like debtors)
      GoRoute(
        path: '/customer/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CustomerDetailScreen(customerId: id);
        },
      ),

      // Credit Management Routes
      GoRoute(
        path: '/debtors',
        builder: (context, state) => const DebtorsScreen(),
      ),
      GoRoute(
        path: '/hire-purchase',
        builder: (context, state) => const HirePurchaseScreen(),
      ),

      // Expenses
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
    ],
  );
}

// Router Provider - returns singleton instance
final routerProvider = Provider<GoRouter>((ref) {
  _router ??= _createRouter();
  return _router!;
});
