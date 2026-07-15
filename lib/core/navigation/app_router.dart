import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/customers/presentation/pages/customer_list_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/create_customer_page.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../features/orders/presentation/pages/new_order_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/components/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// AppRouter defines all GoRouter route structures, paths, and navigation shells.
class AppRouter {
  AppRouter._();

  static GoRouter get router => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: '/',
        routes: [
          // 1. Splash Screen
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashPage(),
          ),
          // 2. Authentication Screens
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordPage(),
          ),
          // 3. Main Persistent Layout Shell
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return MainLayout(navigationShell: navigationShell);
            },
            branches: [
              // Branch A: Dashboard
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/dashboard',
                    builder: (context, state) => const DashboardPage(),
                  ),
                ],
              ),
              // Branch B: Customers
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/customers',
                    builder: (context, state) => const CustomerListPage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const CreateCustomerPage(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                          return CustomerDetailPage(customerId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Branch C: Orders
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/orders',
                    builder: (context, state) => const OrderListPage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) {
                          final cidStr = state.uri.queryParameters['customerId'];
                          final cid = cidStr != null ? int.tryParse(cidStr) : null;
                          return NewOrderPage(preselectedCustomerId: cid);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Branch D: Search
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/search',
                    builder: (context, state) => const SearchPage(),
                  ),
                ],
              ),
              // Branch E: Settings
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/settings',
                    builder: (context, state) => const SettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}
