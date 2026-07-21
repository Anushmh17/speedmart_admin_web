/// All named route paths in one place.
/// Change a route name here and it updates everywhere.
class RouteNames {
  RouteNames._();

  // ── Core ──────────────────────────────────────────────────────────────────
  static const String splash = '/';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String adminLogin = '/auth/admin/login';
  static const String adminRegister = '/auth/admin/register';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin';
  static const String adminVendorApprovals = '/admin/vendor-approvals';
  static const String adminApprovalRequests = '/admin/approval-requests';
  static const String adminVendorManagement = '/admin/vendor-management';
  static const String adminVendorAssignment = '/admin/vendor-assignment/:id';
  static const String adminUsers = '/admin/users';
  static const String adminCategories = '/admin/categories';
  static const String adminRequests = '/admin/requests';
  static const String adminOrders = '/admin/orders';
  static const String adminPayments = '/admin/payments';
  static const String adminReviews = '/admin/reviews';
  static const String adminDeliveryAreas = '/admin/delivery-areas';
  static const String adminNotifications = '/admin/notifications';
  static const String adminReports = '/admin/reports';
  static const String adminActivityLogs = '/admin/activity-logs';
  static const String adminSettings = '/admin/settings';
  static const String adminAdminUsers = '/admin/admin-users';

}


