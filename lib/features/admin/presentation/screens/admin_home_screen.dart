import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/commission_input_formatter.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/models/vendor_status.dart';
import '../../../requests/providers/request_provider.dart';
import '../../../orders/models/order_model.dart';
import '../../../orders/providers/order_provider.dart';
import '../../providers/admin_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'admin_web_shell.dart';
import '../widgets/admin_web_content.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with WidgetsBindingObserver {
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(adminProvider.notifier).loadAllUsers();
      ref.read(requestProvider.notifier).loadNearbyRequests();
      ref.read(orderProvider.notifier).loadAllOrders();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncTabFromRoute();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTabFromRoute();
    });
  }

  void _syncTabFromRoute() {
    if (!mounted) return;
    final location = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final targetIndex = _routeToTabIndex(location);
    if (targetIndex != null && ref.read(adminWebSectionProvider) != targetIndex) {
      ref.read(adminWebSectionProvider.notifier).state = targetIndex;
    }
  }

  int? _routeToTabIndex(String location) {
    if (location.startsWith('/admin/approval-requests')) return 1;
    if (location.startsWith('/admin/users')) return 2;
    if (location.startsWith('/admin/orders')) return 3;
    if (location.startsWith('/admin/settings')) return 4;
    if (location == '/admin' || location.isEmpty) return 0;
    return null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _switchTab(int index) {
    ref.read(adminWebSectionProvider.notifier).state = index;
  }

  /// Called by the system BEFORE GoRouter's back-button dispatcher.
  /// Returning [true] consumes the event; [false] lets GoRouter handle it.
  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;

    // Only intercept on admin shell tabs.
    const adminTabs = {
      '/admin',
      '/admin/approval-requests',
      '/admin/vendor-management',
      '/admin/vendor-approvals',
      '/admin/users',
      '/admin/categories',
      '/admin/requests',
      '/admin/orders',
      '/admin/payments',
      '/admin/disputes',
      '/admin/settings',
    };

    // Determine current location from GoRouter.
    final String location;
    try {
      location = GoRouter.of(context)
          .routeInformationProvider
          .value
          .uri
          .path;
    } catch (_) {
      return false;
    }

    if (!adminTabs.contains(location)) return false;

    // Non-home tab: go back to Home tab.
    final currentIndex = ref.read(adminWebSectionProvider);
    if (currentIndex != 0) {
      ref.read(adminWebSectionProvider.notifier).state = 0;
      return true;
    }

    // Home tab: double-back to exit.
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Swipe back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return true; // consumed – do NOT exit
    }

    // Second press within 2 s → let the system exit.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(adminWebSectionProvider);
    final location = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final rawIndex = _routeToTabIndex(location) ?? currentIndex;
    final effectiveIndex = rawIndex.clamp(0, 4);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
        body: IndexedStack(
          index: effectiveIndex,
          children: [
            _AdminDashboardTab(isDark: isDark, switchTab: _switchTab),
            _VendorApprovalsTab(isDark: isDark),
            _UsersManagementTab(isDark: isDark),
            _OrdersMonitoringTab(isDark: isDark),
            _PlatformSettingsTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab({required this.isDark, required this.switchTab});
  final bool isDark;
  final ValueChanged<int> switchTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final adminState = ref.watch(adminProvider);
    final requestState = ref.watch(requestProvider);
    final orderState = ref.watch(orderProvider);

    // Live calculations
    final totalUsers = adminState.users.length.toString();
    final totalVendors = adminState.users.where((u) => u.role == UserRole.vendor).length.toString();
    final pendingApprovals = adminState.users.where((u) => u.role == UserRole.vendor && u.vendorApproved == false).length.toString();
    
    // Requests total (mock customer lists + nearby vendor requests feed)
    final totalRequests = (requestState.requests.length + requestState.nearbyRequests.length).toString();
    final totalOrders = orderState.orders.length.toString();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminProvider.notifier).loadAllUsers();
        await ref.read(requestProvider.notifier).loadNearbyRequests();
        await ref.read(orderProvider.notifier).loadAllOrders();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.adminColor, AppColors.adminColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.adminColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Dashboard', style: AppTextStyles.h2(Colors.white)),
                      const SizedBox(height: 4),
                      Text('Speedmart Lanka Platform Control', style: AppTextStyles.bodyMedium(Colors.white70)),
                      const SizedBox(height: 14),
                      StatusBadge(label: '● Platform Monitoring Online', color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Stats grid — responsive
                Text('Platform Overview', style: AppTextStyles.h2(primaryText)),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth > 700 ? 5 : (constraints.maxWidth > 400 ? 3 : 2);
                    return GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth > 900 ? 1.3 : 1.2,
                      children: [
                        _AdminStatCard(label: 'Total Users', value: totalUsers, icon: Icons.group_rounded, color: AppColors.info, isDark: isDark),
                        _AdminStatCard(label: 'Shop Owners', value: totalVendors, icon: Icons.storefront_rounded, color: AppColors.vendorColor, isDark: isDark),
                        _AdminStatCard(label: 'Pending Approvals', value: pendingApprovals, icon: Icons.hourglass_top_rounded, color: AppColors.warning, isDark: isDark),
                        _AdminStatCard(label: 'Shopping Lists', value: totalRequests, icon: Icons.grid_view_rounded, color: AppColors.customerColor, isDark: isDark),
                        _AdminStatCard(label: 'Platform Orders', value: totalOrders, icon: Icons.local_shipping_rounded, color: AppColors.accent, isDark: isDark),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Quick actions
                Text('Platform Control Actions', style: AppTextStyles.h2(primaryText)),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    final actions = [
                      _quickActionCard(Icons.pending_actions_rounded, 'Approval Requests', '$pendingApprovals pending applications', AppColors.warning, () {
                        context.push(RouteNames.adminApprovalRequests);
                      }),
                      _quickActionCard(Icons.storefront_rounded, 'Shop Owners', 'Manage accepted shop owners', AppColors.vendorColor, () {
                        context.push(RouteNames.adminVendorManagement);
                      }),
                      _quickActionCard(Icons.supervisor_account_rounded, 'User Directories', 'Suspend / activate users', AppColors.info, () => switchTab(2)),
                      _quickActionCard(Icons.label_rounded, 'Category Management', 'Add, edit, enable / disable categories', AppColors.accent, () {
                        context.push('/admin/categories');
                      }),
                      _quickActionCard(Icons.local_shipping_rounded, 'Monitor Orders', 'Track & monitor order dispatch', AppColors.success, () => switchTab(3)),
                      _quickActionCard(Icons.tune_rounded, 'Platform Config', 'Commission percentages & values', AppColors.accent, () => switchTab(4)),
                    ];
                    if (isWide) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 5.0,
                        children: actions,
                      );
                    }
                    return Column(children: actions);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyLarge(isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.bodySmall(isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(value, style: AppTextStyles.h2(isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.bodySmall(isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorApprovalsTab extends ConsumerWidget {
  const _VendorApprovalsTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final adminState = ref.watch(adminProvider);
    final vendors = adminState.users.where((u) => u.role == UserRole.vendor && u.vendorStatus == VendorStatus.pendingApproval).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).loadAllUsers(),
        child: adminState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
            : vendors.isEmpty
                ? const AppEmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'No Pending Approval Requests',
                    subtitle: 'New shop owner applications will show up here.',
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: AdminWebContent(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shop Owner Account Registrations', style: AppTextStyles.h2(primaryText)),
                          const SizedBox(height: 16),
                          ...vendors.map((vendor) {
                            final isApproved = vendor.vendorApproved == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(vendor.businessName ?? 'Shop Profile', style: AppTextStyles.subtitle(primaryText)),
                                      StatusBadge(
                                        label: isApproved ? 'Approved' : 'Pending',
                                        color: isApproved ? AppColors.success : AppColors.warning,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Shop Owner Partner: ${vendor.fullName}', style: AppTextStyles.bodyMedium(secondaryText)),
                                  Text('Phone: ${vendor.phone} | Email: ${vendor.email}', style: AppTextStyles.bodySmall(secondaryText)),
                                  if (vendor.vendorCategories != null) ...[
                                    const SizedBox(height: 6),
                                    Text('Categories: ${vendor.vendorCategories!.join(', ')}', style: AppTextStyles.caption(AppColors.vendorColor)),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Joined: ${vendor.createdAt.day}/${vendor.createdAt.month}/${vendor.createdAt.year}', style: AppTextStyles.caption(secondaryText)),
                                      if (!isApproved)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.adminColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            minimumSize: const Size(0, 36),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () async {
                                            await ref.read(adminProvider.notifier).approveVendor(vendorId: vendor.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Approved ${vendor.businessName}!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                          label: const Text('Approve Access', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        )
                                      else
                                        Row(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.verified_outlined, color: AppColors.success, size: 14),
                                          const SizedBox(width: 6),
                                          const Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ]),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _UsersManagementTab extends ConsumerWidget {
  const _UsersManagementTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).loadAllUsers(),
        child: adminState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AdminWebContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Management Center', style: AppTextStyles.h2(primaryText)),
                      const SizedBox(height: 16),
                      ...adminState.users.map((user) {
                        final isSuspended = !user.isActive;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: user.role == UserRole.admin
                                    ? AppColors.adminColor.withOpacity(0.15)
                                    : (user.role == UserRole.vendor
                                        ? AppColors.vendorColor.withOpacity(0.15)
                                        : AppColors.customerColor.withOpacity(0.15)),
                                child: Text(user.initials, style: TextStyle(
                                  color: user.role == UserRole.admin ? AppColors.adminColor
                                      : (user.role == UserRole.vendor ? AppColors.vendorColor : AppColors.customerColor),
                                  fontWeight: FontWeight.bold, fontSize: 13,
                                )),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(user.fullName, style: AppTextStyles.subtitle(primaryText)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                        child: Text(user.role.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(user.email, style: AppTextStyles.caption(secondaryText)),
                                    Text(isSuspended ? 'Suspended' : 'Active', style: TextStyle(color: isSuspended ? AppColors.error : AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              if (user.role != UserRole.admin)
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isSuspended ? AppColors.success : AppColors.error),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () async {
                                    await ref.read(adminProvider.notifier).toggleUserActive(user.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('${isSuspended ? "Activated" : "Suspended"} ${user.fullName}'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  },
                                  child: Text(isSuspended ? 'Activate' : 'Suspend',
                                    style: TextStyle(color: isSuspended ? AppColors.success : AppColors.error, fontSize: 12)),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _OrdersMonitoringTab extends ConsumerStatefulWidget {
  const _OrdersMonitoringTab({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_OrdersMonitoringTab> createState() => _OrdersMonitoringTabState();
}

class _OrdersMonitoringTabState extends ConsumerState<_OrdersMonitoringTab> {
  final _vendorSearchCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  final _expandedVendors = <String>{};
  String _vendorQuery = '';
  String _productQuery = '';

  static const _groupOrder = [
    'Today', 'Yesterday', 'This Week', 'Last Week', 'This Month', 'Last Month', 'Older'
  ];

  @override
  void dispose() {
    _vendorSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    super.dispose();
  }

  String _formatOrderStatus(dynamic status) {
    final raw = status.toString().split('.').last;
    return raw
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _dateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    if (!d.isBefore(startOfWeek)) return 'This Week';
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    if (!d.isBefore(startOfLastWeek)) return 'Last Week';
    if (d.year == now.year && d.month == now.month) return 'This Month';
    final lastMonthDate = DateTime(now.year, now.month - 1);
    if (d.year == lastMonthDate.year && d.month == lastMonthDate.month) return 'Last Month';
    return 'Older';
  }

  bool _matchesProductQuery(OrderModel order) {
    if (_productQuery.isEmpty) return true;
    return order.items.any((item) =>
        item.id.toLowerCase().contains(_productQuery) ||
        item.requestItemId.toLowerCase().contains(_productQuery));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final orderState = ref.watch(orderProvider);

    // Group orders by vendor, applying product ID filter
    final Map<String, List<OrderModel>> ordersByVendor = {};
    for (final order in orderState.orders) {
      if (_matchesProductQuery(order)) {
        ordersByVendor.putIfAbsent(order.vendorBusinessName, () => []).add(order);
      }
    }

    // Filter vendors by vendor name search
    final filteredVendors = ordersByVendor.keys
        .where((name) => name.toLowerCase().contains(_vendorQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderProvider.notifier).loadAllOrders(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live Order Transactions', style: AppTextStyles.h2(primaryText)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _vendorSearchCtrl,
                    onChanged: (v) => setState(() => _vendorQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search vendor shop name…',
                      prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                      suffixIcon: _vendorQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _vendorSearchCtrl.clear();
                                setState(() => _vendorQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _productSearchCtrl,
                    onChanged: (v) => setState(() => _productQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by product ID…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _productQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _productSearchCtrl.clear();
                                setState(() => _productQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orderState.orders.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Orders Yet',
                      subtitle: 'Orders will appear here once customers place them.',
                    )
                  : filteredVendors.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No Matching Orders',
                          subtitle: 'Try a different vendor name or product ID.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                          itemCount: filteredVendors.length,
                          itemBuilder: (context, vendorIndex) {
                            final vendorName = filteredVendors[vendorIndex];
                            final vendorOrders = ordersByVendor[vendorName]!;
                            final isExpanded = _expandedVendors.contains(vendorName);

                            // Group vendor orders by date
                            final Map<String, List<OrderModel>> grouped = {};
                            for (final o in vendorOrders) {
                              grouped.putIfAbsent(_dateGroup(o.createdAt), () => []).add(o);
                            }
                            final groupKeys = _groupOrder.where(grouped.containsKey).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tappable vendor header
                                InkWell(
                                  onTap: () => setState(() {
                                    if (isExpanded) {
                                      _expandedVendors.remove(vendorName);
                                    } else {
                                      _expandedVendors.add(vendorName);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.storefront_rounded, size: 16, color: AppColors.adminColor),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(vendorName, style: AppTextStyles.subtitle(primaryText))),
                                        Text('(${vendorOrders.length})', style: AppTextStyles.caption(secondaryText)),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                          size: 18,
                                          color: secondaryText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Collapsible date-grouped orders
                                if (isExpanded)
                                  ...groupKeys.expand((dateLabel) => [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, top: 6, bottom: 4),
                                      child: Text(
                                        dateLabel,
                                        style: AppTextStyles.labelMedium(AppColors.adminColor)
                                            .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4),
                                      ),
                                    ),
                                    ...grouped[dateLabel]!.map((order) => GestureDetector(
                                      onTap: () => context.push('/admin/orders/detail', extra: order),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(order.id, style: AppTextStyles.subtitle(primaryText)),
                                                StatusBadge(label: _formatOrderStatus(order.status), color: AppColors.adminColor),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Customer: ${order.customerName}', style: AppTextStyles.bodySmall(secondaryText)),
                                            Text('${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}  •  Rs. ${order.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.caption(secondaryText)),
                                            if (order.items.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: order.items.map((item) => Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.adminColor.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(color: AppColors.adminColor.withOpacity(0.2)),
                                                  ),
                                                  child: Text('ID: ${item.id}', style: AppTextStyles.labelSmall(AppColors.adminColor)),
                                                )).toList(),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text('View Details', style: AppTextStyles.caption(AppColors.adminColor)),
                                                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.adminColor),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ]),
                                const SizedBox(height: 4),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformSettingsTab extends ConsumerStatefulWidget {
  const _PlatformSettingsTab({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_PlatformSettingsTab> createState() => _PlatformSettingsTabState();
}

class _PlatformSettingsTabState extends ConsumerState<_PlatformSettingsTab> {
  late final TextEditingController _commissionCtrl;
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _currentPasswordCtrl;
  late final TextEditingController _newPasswordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  bool _editingCommission = false;
  bool _editingRadius = false;
  bool _editingPassword = false;
  String _savedCommission = '10.0';
  String _savedRadius = '5';

  @override
  void initState() {
    super.initState();
    _commissionCtrl = TextEditingController();
    _radiusCtrl = TextEditingController();
    _currentPasswordCtrl = TextEditingController();
    _newPasswordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.getPlatformSettings();
    if (mounted) {
      setState(() {
        _savedCommission = settings.commissionPct.toStringAsFixed(1);
        _savedRadius = settings.radiusKm.toString();
        _commissionCtrl.text = _savedCommission;
        _radiusCtrl.text = _savedRadius;
      });
    }
  }

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _radiusCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCommission() async {
    final pct = double.tryParse(_commissionCtrl.text);
    if (pct == null || pct < 0 || pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid percentage between 0 and 100'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final current = await StorageService.getPlatformSettings();
    await StorageService.savePlatformSettings(
      standardCommissionPct: pct,
      standardRadiusKm: current.radiusKm,
    );
    if (!mounted) return;

    setState(() {
      _savedCommission = pct.toStringAsFixed(1);
      _editingCommission = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Standard commission rate saved as ${pct.toStringAsFixed(1)}%'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveRadius() async {
    final km = int.tryParse(_radiusCtrl.text);
    if (km == null || km <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid radius greater than 0'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final current = await StorageService.getPlatformSettings();
    await StorageService.savePlatformSettings(
      standardCommissionPct: current.commissionPct,
      standardRadiusKm: km,
    );
    if (!mounted) return;

    setState(() {
      _savedRadius = km.toString();
      _editingRadius = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Standard search radius saved as ${km}km'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveAdminPassword() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final current = _currentPasswordCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (current.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter all password fields.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use a password of at least 8 characters.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final storedPassword = await ref.read(authProvider.notifier).getPassword(user.email);
    if (storedPassword == null || storedPassword != current) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password is incorrect.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (current == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use a different password than the current one.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(authProvider.notifier).resetPassword(email: user.email, newPassword: newPassword);
    final authState = ref.read(authProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error ?? 'Password update failed.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _editingPassword = false;
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionCard({
    required Color cardColor,
    required Color borderColor,
    required Color boxShadowColor,
    required Widget header,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: boxShadowColor, blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _sectionInputDecoration({
    required String labelText,
    String? suffixText,
    required bool enabled,
  }) {
    return InputDecoration(
      labelText: labelText,
      suffixText: suffixText,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      filled: true,
      fillColor: enabled ? (widget.isDark ? const Color(0xFF2A2D34) : const Color(0xFFF4F5F7)) : (widget.isDark ? const Color(0xFF21242B) : const Color(0xFFE7EAEE)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.fullName ?? 'Admin User';
    final displayEmail = currentUser?.email ?? 'admin@speedmart.lk';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final horizontalPadding = isCompact ? 16.0 : 24.0;
          final maxContentWidth = isCompact ? double.infinity : 960.0;
          final boxShadowColor = isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.06);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 40),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Platform Configuration', style: AppTextStyles.h2(primaryText)),
                    const SizedBox(height: 14),
                    Text('Manage core platform settings, password access, commission defaults and vendor matching.', style: AppTextStyles.bodySmall(secondaryText)),
                    const SizedBox(height: 24),

                    _buildSectionCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      boxShadowColor: boxShadowColor,
                      header: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.adminColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_outline, color: AppColors.adminColor, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Profile', style: AppTextStyles.subtitle(primaryText)),
                                const SizedBox(height: 4),
                                Text('Your account and password settings.', style: AppTextStyles.caption(secondaryText)),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                              foregroundColor: AppColors.adminColor,
                            ),
                            onPressed: () => setState(() => _editingPassword = !_editingPassword),
                            child: Text(_editingPassword ? 'Cancel' : 'Change Password'),
                          ),
                        ],
                      ),
                      children: [
                        Text(displayName, style: AppTextStyles.bodyLarge(primaryText)),
                        const SizedBox(height: 4),
                        Text(displayEmail, style: AppTextStyles.caption(secondaryText)),
                        if (_editingPassword) ...[
                          const SizedBox(height: 20),
                          TextField(
                            controller: _currentPasswordCtrl,
                            obscureText: true,
                            decoration: _sectionInputDecoration(labelText: 'Current Password', enabled: true),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _newPasswordCtrl,
                            obscureText: true,
                            decoration: _sectionInputDecoration(labelText: 'New Password', enabled: true),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirmPasswordCtrl,
                            obscureText: true,
                            decoration: _sectionInputDecoration(labelText: 'Confirm Password', enabled: true),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.adminColor,
                                    side: BorderSide(color: AppColors.adminColor.withOpacity(0.18)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => setState(() {
                                    _editingPassword = false;
                                    _currentPasswordCtrl.clear();
                                    _newPasswordCtrl.clear();
                                    _confirmPasswordCtrl.clear();
                                  }),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.adminColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _saveAdminPassword,
                                  child: const Text('Save Password'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 18),

                    _buildSectionCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      boxShadowColor: boxShadowColor,
                      header: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.adminColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.percent_rounded, color: AppColors.adminColor, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text('Platform Commission Rate', style: AppTextStyles.subtitle(primaryText))),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.adminColor),
                            onPressed: () => setState(() => _editingCommission = !_editingCommission),
                            child: Text(_editingCommission ? 'Done' : 'Edit'),
                          ),
                        ],
                      ),
                      children: [
                        TextField(
                          controller: _commissionCtrl,
                          enabled: _editingCommission,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CommissionInputFormatter()],
                          decoration: _sectionInputDecoration(labelText: 'Standard Commission Percentage', suffixText: '%', enabled: _editingCommission),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Default rate for new shop owners. Individual vendors can be adjusted separately.',
                          style: AppTextStyles.caption(secondaryText),
                        ),
                        if (_editingCommission) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.adminColor,
                                    side: BorderSide(color: AppColors.adminColor.withOpacity(0.18)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => setState(() {
                                    _commissionCtrl.text = _savedCommission;
                                    _editingCommission = false;
                                  }),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.adminColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _saveCommission,
                                  child: const Text('Save Rate'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 18),

                    _buildSectionCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      boxShadowColor: boxShadowColor,
                      header: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.adminColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.explore_outlined, color: AppColors.adminColor, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text('Sri Lankan Matching Settings', style: AppTextStyles.subtitle(primaryText))),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.adminColor),
                            onPressed: () => setState(() => _editingRadius = !_editingRadius),
                            child: Text(_editingRadius ? 'Done' : 'Edit'),
                          ),
                        ],
                      ),
                      children: [
                        TextField(
                          controller: _radiusCtrl,
                          enabled: _editingRadius,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _sectionInputDecoration(labelText: 'Standard Vendor Search Radius', suffixText: 'km', enabled: _editingRadius),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Default radius for new shop owners. Existing vendors keep their individually assigned radius.',
                          style: AppTextStyles.caption(secondaryText),
                        ),
                        if (_editingRadius) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.adminColor,
                                    side: BorderSide(color: AppColors.adminColor.withOpacity(0.18)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => setState(() {
                                    _radiusCtrl.text = _savedRadius;
                                    _editingRadius = false;
                                  }),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.adminColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _saveRadius,
                                  child: const Text('Save Radius'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


