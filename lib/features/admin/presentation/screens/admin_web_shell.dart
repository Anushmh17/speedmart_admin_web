import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/theme_provider.dart';

/// Tracks which admin section is active in the web shell.
///
/// This is still used by the inner dashboard tabs, but the sidebar highlight
/// now derives from the current route path so it stays in sync with navigation.
final adminWebSectionProvider = StateProvider<int>((ref) => 0);

/// The responsive web shell for all admin screens.
/// On wide screens: persistent sidebar + content area.
/// On narrow screens: falls back to a drawer-based layout.
class AdminWebShell extends ConsumerWidget {
  const AdminWebShell({super.key, required this.child});
  final Widget child;

  static const _navSections = [
    _NavSection('Main', [
      _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard', RouteNames.adminDashboard),
      _NavItem(Icons.verified_user_rounded, Icons.verified_user_outlined, 'Approval Requests', RouteNames.adminApprovalRequests),
      _NavItem(Icons.storefront_rounded, Icons.storefront_outlined, 'Shop Owners', RouteNames.adminVendorManagement),
      _NavItem(Icons.people_rounded, Icons.people_outline_rounded, 'Users', RouteNames.adminUsers),
      _NavItem(Icons.list_alt_rounded, Icons.list_alt_outlined, 'Orders', RouteNames.adminOrders),
      _NavItem(Icons.category_rounded, Icons.category_outlined, 'Categories', RouteNames.adminCategories),
      _NavItem(Icons.payments_rounded, Icons.payments_outlined, 'Payments', RouteNames.adminPayments),
      _NavItem(Icons.star_rounded, Icons.star_outline_rounded, 'Reviews', RouteNames.adminReviews),
    ]),
    _NavSection('Management', [
      _NavItem(Icons.location_on_rounded, Icons.location_on_outlined, 'Delivery Areas', RouteNames.adminDeliveryAreas),
      _NavItem(Icons.notifications_rounded, Icons.notifications_none_rounded, 'Notifications', RouteNames.adminNotifications),
      _NavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Reports', RouteNames.adminReports),
    ]),
    _NavSection('Settings', [
      _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings', RouteNames.adminSettings),
      _NavItem(Icons.admin_panel_settings_rounded, Icons.admin_panel_settings_outlined, 'Admin Users', RouteNames.adminAdminUsers),
      _NavItem(Icons.history_rounded, Icons.history_toggle_off_rounded, 'Activity Logs', RouteNames.adminActivityLogs),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final isMedium = width >= 600 && width < 900;

    if (isWide) {
      return _WideLayout(child: child, isDark: isDark, navSections: _navSections);
    } else if (isMedium) {
      return _MediumLayout(child: child, isDark: isDark, navSections: _navSections);
    } else {
      return _NarrowLayout(child: child, isDark: isDark, navSections: _navSections);
    }
  }
}

class _NavItem {
  const _NavItem(this.selectedIcon, this.unselectedIcon, this.label, this.route);
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final String route;
}

class _NavSection {
  const _NavSection(this.heading, this.items);
  final String heading;
  final List<_NavItem> items;
}

// ── Wide Layout (≥900px): full sidebar ──────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  const _WideLayout({required this.child, required this.isDark, required this.navSections});
  final Widget child;
  final bool isDark;
  final List<_NavSection> navSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final activeIndex = _activeIndex(location);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      body: Row(
        children: [
          _Sidebar(
            isDark: isDark,
            navSections: navSections,
            activeIndex: activeIndex,
            collapsed: false,
          ),
          Expanded(
            child: Column(
              children: [
                _WebTopBar(isDark: isDark, showMenuButton: false),
                Expanded(child: _ContentArea(child: child, isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medium Layout (600–899px): collapsed icon sidebar ───────────────────────

class _MediumLayout extends ConsumerWidget {
  const _MediumLayout({required this.child, required this.isDark, required this.navSections});
  final Widget child;
  final bool isDark;
  final List<_NavSection> navSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final activeIndex = _activeIndex(location);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      body: Row(
        children: [
          _Sidebar(
            isDark: isDark,
            navSections: navSections,
            activeIndex: activeIndex,
            collapsed: true,
          ),
          Expanded(
            child: Column(
              children: [
                _WebTopBar(isDark: isDark, showMenuButton: false),
                Expanded(child: _ContentArea(child: child, isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrow Layout (<600px): drawer ──────────────────────────────────────────

class _NarrowLayout extends ConsumerStatefulWidget {
  const _NarrowLayout({required this.child, required this.isDark, required this.navSections});
  final Widget child;
  final bool isDark;
  final List<_NavSection> navSections;

  @override
  ConsumerState<_NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends ConsumerState<_NarrowLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final activeIndex = _activeIndex(location);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      drawer: Drawer(
        backgroundColor: widget.isDark ? AppColors.surfaceDark : Colors.white,
        child: _SidebarContent(
          isDark: widget.isDark,
          navSections: widget.navSections,
          activeIndex: activeIndex,
          collapsed: false,
          onTap: () => _scaffoldKey.currentState?.closeDrawer(),
        ),
      ),
      body: Column(
        children: [
          _WebTopBar(
            isDark: widget.isDark,
            showMenuButton: true,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(child: _ContentArea(child: widget.child, isDark: widget.isDark)),
        ],
      ),
    );
  }
}

// ── Content Area: centers & constrains all screen content ────────────────────

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      child: child,
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.isDark,
    required this.navSections,
    required this.activeIndex,
    required this.collapsed,
  });
  final bool isDark;
  final List<_NavSection> navSections;
  final int activeIndex;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: collapsed ? 64 : 220,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: _SidebarContent(
        isDark: isDark,
        navSections: navSections,
        activeIndex: activeIndex,
        collapsed: collapsed,
      ),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent({
    required this.isDark,
    required this.navSections,
    required this.activeIndex,
    required this.collapsed,
    this.onTap,
  });
  final bool isDark;
  final List<_NavSection> navSections;
  final int activeIndex;
  final bool collapsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Logo area
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.adminColor, AppColors.adminColorDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: collapsed
              ? const Center(
                  child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                )
              : Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin Panel',
                        style: AppTextStyles.subtitle(Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        // Nav sections
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            itemCount: navSections.length,
            itemBuilder: (context, sectionIndex) {
              final section = navSections[sectionIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!collapsed) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 0, 6),
                      child: Text(section.heading.toUpperCase(), style: AppTextStyles.labelSmall(isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ),
                  ],
                  ...List.generate(section.items.length, (itemIndex) {
                    final item = section.items[itemIndex];
                    final globalIndex = navSections.take(sectionIndex).expand((s) => s.items).length + itemIndex;
                    final isActive = activeIndex == globalIndex;
                    return Tooltip(
                      message: collapsed ? item.label : '',
                      child: InkWell(
                        onTap: () {
                          onTap?.call();
                          _handleNavTap(context, ref, globalIndex, item.route);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: EdgeInsets.symmetric(
                            horizontal: collapsed ? 0 : 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.adminColor.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: collapsed
                              ? Center(
                                  child: Icon(
                                    isActive ? item.selectedIcon : item.unselectedIcon,
                                    color: isActive ? AppColors.adminColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    size: 22,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      isActive ? item.selectedIcon : item.unselectedIcon,
                                      color: isActive ? AppColors.adminColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: AppTextStyles.bodyMedium(
                                          isActive
                                              ? AppColors.adminColor
                                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                        ).copyWith(fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        // Logout
        Padding(
          padding: const EdgeInsets.all(8),
          child: Tooltip(
            message: collapsed ? 'Logout' : '',
            child: InkWell(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(RouteNames.adminLogin);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : 12,
                  vertical: 10,
                ),
                child: collapsed
                    ? const Center(child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20))
                    : Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Text('Logout', style: AppTextStyles.bodyMedium(AppColors.error)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleNavTap(BuildContext context, WidgetRef ref, int index, String route) {
    switch (route) {
      case RouteNames.adminDashboard:
        ref.read(adminWebSectionProvider.notifier).state = 0;
        context.go(RouteNames.adminDashboard);
        break;
      case RouteNames.adminApprovalRequests:
        context.go(RouteNames.adminApprovalRequests);
        break;
      case RouteNames.adminVendorManagement:
        context.go(RouteNames.adminVendorManagement);
        break;
      case RouteNames.adminUsers:
        context.go(RouteNames.adminUsers);
        break;
      case RouteNames.adminCategories:
        context.go(RouteNames.adminCategories);
        break;
      case RouteNames.adminOrders:
        context.go(RouteNames.adminOrders);
        break;
      case RouteNames.adminPayments:
        context.go(RouteNames.adminPayments);
        break;
      case RouteNames.adminReviews:
        context.go(RouteNames.adminReviews);
        break;
      case RouteNames.adminDeliveryAreas:
        context.go(RouteNames.adminDeliveryAreas);
        break;
      case RouteNames.adminNotifications:
        context.go(RouteNames.adminNotifications);
        break;
      case RouteNames.adminReports:
        context.go(RouteNames.adminReports);
        break;
      case RouteNames.adminSettings:
        context.go(RouteNames.adminSettings);
        break;
      case RouteNames.adminAdminUsers:
        context.go(RouteNames.adminAdminUsers);
        break;
      case RouteNames.adminActivityLogs:
        context.go(RouteNames.adminActivityLogs);
        break;
    }
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────────

class _WebTopBar extends ConsumerWidget {
  const _WebTopBar({required this.isDark, required this.showMenuButton, this.onMenuTap});
  final bool isDark;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: Icon(Icons.menu_rounded, color: secondaryText),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset('assets/images/logo.png', height: 20, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Text(
            'Speedmart Lanka',
            style: AppTextStyles.subtitle(isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.adminColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: AppColors.adminColor, size: 14),
                const SizedBox(width: 4),
                Text('Admin', style: AppTextStyles.caption(AppColors.adminColor).copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: secondaryText,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper ───────────────────────────────────────────────────────────────────

int _activeIndex(String location) {
  if (location.startsWith('/admin/approval-requests')) return 1;
  if (location.startsWith('/admin/vendor-management') || location.startsWith('/admin/vendor-assignment')) return 2;
  if (location.startsWith('/admin/users')) return 3;
  if (location.startsWith('/admin/orders')) return 4;
  if (location.startsWith('/admin/categories')) return 5;
  if (location.startsWith('/admin/payments')) return 6;
  if (location.startsWith('/admin/reviews')) return 7;
  if (location.startsWith('/admin/delivery-areas')) return 8;
  if (location.startsWith('/admin/notifications')) return 9;
  if (location.startsWith('/admin/reports')) return 10;
  if (location.startsWith('/admin/settings')) return 11;
  if (location.startsWith('/admin/admin-users')) return 12;
  if (location.startsWith('/admin/activity-logs')) return 13;
  return 0;
}
