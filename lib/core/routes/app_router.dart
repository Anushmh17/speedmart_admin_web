import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedmart_admin_web/features/auth/domain/auth_state.dart';
import 'package:speedmart_admin_web/features/auth/presentation/screens/login_screen.dart';
import 'package:speedmart_admin_web/features/auth/presentation/screens/register_screen.dart';
import 'package:speedmart_admin_web/features/auth/presentation/screens/splash_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_category_management_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_order_detail_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_placeholder_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_vendor_assignment_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_vendor_management_screen.dart';
import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_web_shell.dart';
import 'package:speedmart_admin_web/features/orders/models/order_model.dart';
import 'package:speedmart_admin_web/features/auth/providers/auth_provider.dart';
import 'package:speedmart_admin_web/shared/models/user_role.dart';
import 'package:speedmart_admin_web/core/routes/route_names.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

Page<T> _buildPage<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

final currentRouteLocationProvider = Provider<String>((ref) {
  final router = ref.watch(appRouterProvider);
  try {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return '/';
    return configuration.last.matchedLocation;
  } catch (e) {
    return '/';
  }
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(const AuthState.initial());

  ref.listen<AuthState>(authProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final auth = authNotifier.value;
      final location = state.matchedLocation;
      final isOnAuthRoute = location == RouteNames.splash ||
          location == RouteNames.adminLogin ||
          location == RouteNames.adminRegister;

      if (auth.isLoading) {
        return null;
      }

      if (isOnAuthRoute && auth.hasError) {
        return null;
      }

      if (!auth.isAuthenticated) {
        if (isOnAuthRoute) {
          return null;
        }
        return RouteNames.adminLogin;
      }

      if (auth.user == null || auth.user!.role != UserRole.admin) {
        return RouteNames.adminLogin;
      }

      if (isOnAuthRoute) {
        return RouteNames.adminDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) => _buildPage(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.adminLogin,
        pageBuilder: (context, state) => _buildPage(context, state, const LoginScreen(role: UserRole.admin)),
      ),
      GoRoute(
        path: RouteNames.adminRegister,
        pageBuilder: (context, state) => _buildPage(context, state, const RegisterScreen(role: UserRole.admin)),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminWebShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.adminDashboard,
            pageBuilder: (context, state) => _buildPage(context, state, const AdminHomeScreen()),
          ),
          GoRoute(
            path: RouteNames.adminApprovalRequests,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminVendorManagementScreen(
                initialFilter: 'pending',
                title: 'Approval Requests',
                subtitle: 'Review new shop owner registrations',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminVendorManagement,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminVendorManagementScreen(
                initialFilter: 'active',
                title: 'Shop Owners',
                subtitle: 'Manage accepted shop owners',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminVendorAssignment,
            pageBuilder: (context, state) {
              final vendor = state.extra;
              return _buildPage(context, state, AdminVendorAssignmentScreen(vendor: vendor));
            },
          ),
          GoRoute(
            path: RouteNames.adminUsers,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminHomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.adminCategories,
            pageBuilder: (context, state) => _buildPage(context, state, const AdminCategoryManagementScreen()),
          ),
          GoRoute(
            path: RouteNames.adminOrders,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Orders',
                subtitle: 'Monitor and manage platform orders',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminPayments,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Payments',
                subtitle: 'Review platform payment flows',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminReviews,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Reviews',
                subtitle: 'Inspect customer and vendor reviews',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminDeliveryAreas,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Delivery Areas',
                subtitle: 'Manage delivery zones and coverage',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminNotifications,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Notifications',
                subtitle: 'Configure admin notifications',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminReports,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Reports',
                subtitle: 'View platform performance reports',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminActivityLogs,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Activity Logs',
                subtitle: 'Audit admin activity history',
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminSettings,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminHomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.adminAdminUsers,
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const AdminPlaceholderScreen(
                title: 'Admin Users',
                subtitle: 'Manage platform admin accounts',
              ),
            ),
          ),
          GoRoute(
            path: '/admin/orders/detail',
            pageBuilder: (context, state) {
              final order = state.extra as OrderModel;
              return _buildPage(context, state, AdminOrderDetailScreen(order: order));
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(RouteNames.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

